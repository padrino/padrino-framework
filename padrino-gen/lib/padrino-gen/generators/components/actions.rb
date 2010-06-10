module Padrino
  module Generators
    module Components
      module Actions
        # For orm database components
        # Generates the model migration file created when generating a new model
        # options => { :base => "....text...", :up => "..text...",
        #             :down => "..text...", column_format => "t.column :#{field}, :#{kind}" }
        def output_model_migration(filename, name, columns, options={})
          if behavior == :revoke
            remove_migration(name)
          else
            return if migration_exist?(filename)
            model_name = name.to_s.pluralize
            field_tuples = fields.collect { |value| value.split(":") }
            field_tuples.collect! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] } # fix datetime
            column_declarations = field_tuples.collect(&options[:column_format]).join("\n      ")
            contents = options[:base].dup.gsub(/\s{4}!UP!\n/m, options[:up]).gsub(/!DOWN!\n/m, options[:down])
            contents = contents.gsub(/!NAME!/, model_name.camelize).gsub(/!TABLE!/, model_name.underscore)
            contents = contents.gsub(/!FILENAME!/, filename.underscore).gsub(/!FILECLASS!/, filename.camelize)
            current_migration_number = return_last_migration_number
            contents = contents.gsub(/!FIELDS!/, column_declarations).gsub(/!VERSION!/, (current_migration_number + 1).to_s)
            migration_filename = "#{format("%03d", current_migration_number+1)}_#{filename.underscore}.rb"
            create_file(destination_root('db/migrate/', migration_filename), contents, :skip => true)
          end
        end

        # For orm database components
        # Generates a standalone migration file based on the given options and columns
        # options => { :base "...text...", :change_format => "...text...",
        #              :add => proc { |field, kind| "add_column :#{table_name}, :#{field}, :#{kind}" },
        #              :remove => proc { |field, kind| "remove_column :#{table_name}, :#{field}" }
        def output_migration_file(filename, name, columns, options={})
          if behavior == :revoke
            remove_migration(name)
          else
            return if migration_exist?(filename)
            change_format = options[:change_format]
            migration_scan = filename.camelize.scan(/(Add|Remove)(?:.*?)(?:To|From)(.*?)$/).flatten
            direction, table_name = migration_scan[0].downcase, migration_scan[1].downcase.pluralize if migration_scan.any?
            tuples = direction ? columns.collect { |value| value.split(":") } : []
            tuples.collect! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] } # fix datetime
            add_columns    = tuples.collect(&options[:add]).join("\n    ")
            remove_columns = tuples.collect(&options[:remove]).join("\n    ")
            forward_text = change_format.gsub(/!TABLE!/, table_name).gsub(/!COLUMNS!/, add_columns) if tuples.any?
            back_text    = change_format.gsub(/!TABLE!/, table_name).gsub(/!COLUMNS!/, remove_columns) if tuples.any?
            contents = options[:base].dup.gsub(/\s{4}!UP!\n/m,   (direction == 'add' ? forward_text.to_s : back_text.to_s))
            contents.gsub!(/\s{4}!DOWN!\n/m, (direction == 'add' ? back_text.to_s : forward_text.to_s))
            contents = contents.gsub(/!FILENAME!/, filename.underscore).gsub(/!FILECLASS!/, filename.camelize)
            current_migration_number = return_last_migration_number
            contents.gsub!(/!VERSION!/, (current_migration_number + 1).to_s)
            migration_filename = "#{format("%03d", current_migration_number+1)}_#{filename.underscore}.rb"
            create_file(destination_root('db/migrate/', migration_filename), contents, :skip => true)
          end
        end

        # For migration files
        # returns the number of the latest(most current) migration file
        def return_last_migration_number
          Dir[destination_root('db/migrate/*.rb')].map { |f|
            File.basename(f).match(/^(\d+)/)[0].to_i
          }.max.to_i || 0
        end

        # Return true if the migration already exist
        def migration_exist?(filename)
          Dir[destination_root("db/migrate/*_#{filename.underscore}.rb")].size > 0
        end

        # For the removal of migration files
        # removes the migration file based on the migration name
        def remove_migration(name)
          migration_path =  Dir[destination_root('db/migrate/*.rb')].find do |f|
            File.basename(f) =~ /#{name.to_s.underscore}/
          end
          return unless migration_path
          if behavior == :revoke
            create_file migration_path # we use create to reverse the operation of a revoke
          end
        end

        # For testing components
        # Injects the test class text into the test_config file for setting up the test gen
        # insert_test_suite_setup('...CLASS_NAME...')
        # => inject_into_file("test/test_config.rb", TEST.gsub(/CLASS_NAME/, @app_name), :after => "set :environment, :test")
        def insert_test_suite_setup(suite_text, options={})
          options.reverse_merge!(:path => "test/test_config.rb")
          create_file(options[:path], suite_text.gsub(/CLASS_NAME/, @app_name))
        end

        # For mocking components
        # Injects the mock library include into the test class in test_config for setting up mock gen
        # insert_mock_library_include('Mocha::API')
        # => inject_into_file("test/test_config.rb", "  include Mocha::API\n", :after => /class.*?\n/)
        def insert_mocking_include(library_name, options={})
          options.reverse_merge!(:indent => 2, :after => /class.*?\n/, :path => "test/test_config.rb")
          return unless File.exist?(destination_root(options[:path]))
          include_text = indent_spaces(2) + "include #{library_name}\n"
          inject_into_file(options[:path], include_text, :after => options[:after])
        end

        # Returns space characters of given count
        # indent_spaces(2)
        def indent_spaces(count)
          ' ' * count
        end

        # For Controller action generation
        # Takes in fields for routes in the form of get:index post:test delete:yada and such
        def controller_actions(fields)
          field_tuples = fields.collect { |value| value.split(":") }
          action_declarations = field_tuples.collect do |request, name|
            "#{request} :#{name} do\n  end\n"
          end
          action_declarations.join("\n  ")
        end
      end # Actions
    end # Components
  end # Generators
end # Padrino