module Padrino
  module Generators
    module Components
      module Actions
        ##
        # Generates the model migration file created when generating a new model.
        #
        # @param [String] filename
        #   File name of model migration.
        # @param [String] name
        #   Name of model.
        # @param [Array<String>] columns
        #   Array of column names and property type.
        # @param [Hash] options
        #   Additional migration options, e.g
        #   { :base => "....text...", :up => "..text...",
        #     :down => "..text...", column_format => "t.column :#{field}, :#{kind}" }
        # @example
        #   output_model_migration("AddPerson", "person", ["name:string", "age:integer"],
        #     :base => AR_MIGRATION,
        #     :column_format => Proc.new { |field, kind| "t.#{kind.underscore.gsub(/_/, '')} :#{field}" },
        #     :up => AR_MODEL_UP_MG, :down => AR_MODEL_DOWN_MG)
        #
        def output_model_migration(filename, name, columns, options={})
          if behavior == :revoke
            remove_migration(filename)
          else
            return if migration_exist?(filename)
            model_name = name.to_s.pluralize
            field_tuples = columns.map { |value| value.split(":") }
            field_tuples.map! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] }
            column_declarations = field_tuples.map(&options[:column_format]).join("\n      ")
            contents = options[:base].dup.gsub(/\s{4}!UP!\n/m, options[:up]).gsub(/!DOWN!\n/m, options[:down])
            contents = contents.gsub(/!NAME!/, model_name.underscore.camelize).gsub(/!TABLE!/, model_name.underscore)
            contents = contents.gsub(/!FILENAME!/, filename.underscore).gsub(/!FILECLASS!/, filename.underscore.camelize)
            migration_number = current_migration_number
            contents = contents.gsub(/!FIELDS!/, column_declarations).gsub(/!VERSION!/, migration_number)
            migration_filename = "#{format("%03d", migration_number)}_#{filename.underscore}.rb"
            create_file(destination_root('db/migrate/', migration_filename), contents, :skip => true)
          end
        end

        ##
        # Generates a standalone migration file based on the given options and columns.
        #
        # @param [String] filename
        #   File name of model migration.
        # @param [String] name
        #   Name of model.
        # @param [Array<String>] columns
        #   Array of column names and property type.
        # @param [Hash] options
        #   Additional migration options, e.g
        #     { :base "...text...", :change_format => "...text...",
        #       :add => proc { |field, kind| "add_column :#{table_name}, :#{field}, :#{kind}" },
        #       :remove => proc { |field, kind| "remove_column :#{table_name}, :#{field}" }
        # @example
        #   output_migration_file(migration_name, name, columns,
        #     :base => AR_MIGRATION, :change_format => AR_CHANGE_MG,
        #     :add => Proc.new { |field, kind| "t.#{kind.underscore.gsub(/_/, '')} :#{field}" },
        #     :remove => Proc.new { |field, kind| "t.remove :#{field}" }
        #   )
        #
        def output_migration_file(filename, name, columns, options={})
          if behavior == :revoke
            remove_migration(name)
          else
            return if migration_exist?(filename)
            change_format = options[:change_format]
            migration_scan = filename.underscore.camelize.scan(/(Add|Remove).*?(?:(?:To|From).+?)*(?:To|From)((?:To|From)?.*?)$/).flatten
            direction, table_name = migration_scan[0].downcase, migration_scan[1].downcase.pluralize if migration_scan.any?
            tuples = direction ? columns.map { |value| value.split(":") } : []
            tuples.map! { |field, kind| kind =~ /datetime/i ? [field, 'DateTime'] : [field, kind] }
            add_columns    = tuples.map(&options[:add]).join("\n      ")
            remove_columns = tuples.map(&options[:remove]).join("\n      ")
            forward_text = change_format.gsub(/!TABLE!/, table_name).gsub(/!COLUMNS!/, add_columns) if tuples.any?
            back_text    = change_format.gsub(/!TABLE!/, table_name).gsub(/!COLUMNS!/, remove_columns) if tuples.any?
            contents = options[:base].dup.gsub(/\s{4}!UP!\n/m,   (direction == 'add' ? forward_text.to_s : back_text.to_s))
            contents.gsub!(/\s{4}!DOWN!\n/m, (direction == 'add' ? back_text.to_s : forward_text.to_s))
            contents = contents.gsub(/!FILENAME!/, filename.underscore).gsub(/!FILECLASS!/, filename.underscore.camelize)
            migration_number = current_migration_number
            contents.gsub!(/!VERSION!/, migration_number)
            migration_filename = "#{format("%03d", migration_number)}_#{filename.underscore}.rb"
            create_file(destination_root('db/migrate/', migration_filename), contents, :skip => true)
          end
        end

        ##
        # Returns the number of the latest(most current) migration file.
        #
        def return_last_migration_number
          Dir[destination_root('db/migrate/*.rb')].map { |f|
            File.basename(f).match(/^(\d+)/)[0].to_i
          }.max.to_i || 0
        end

        ##
        # Returns timestamp instead if :migration_format: in .components is "timestamp"
        #
        def current_migration_number
          if fetch_component_choice(:migration_format).to_s == 'timestamp'
            Time.now.utc.strftime("%Y%m%d%H%M%S")
          else
            return_last_migration_number + 1
          end.to_s
        end

        ##
        # Return true if the migration already exist.
        #
        # @param [String] filename
        #   File name of the migration file.
        #
        def migration_exist?(filename)
          Dir[destination_root("db/migrate/*_#{filename.underscore}.rb")].size > 0
        end

        ##
        # Removes the migration file based on the migration name.
        #
        # @param [String] name
        #   File name of the migration.
        #
        def remove_migration(name)
          migration_path =  Dir[destination_root('db/migrate/*.rb')].find do |f|
            File.basename(f) =~ /#{name.to_s.underscore}/
          end
          return unless migration_path
          if behavior == :revoke
            create_file migration_path # we use create to reverse the operation of a revoke
          end
        end

        ##
        # Injects the test class text into the test_config file for setting up the test gen.
        #
        # @param [String] suite_text
        #   Class name for test suite.
        # @param [Hash] options
        #   Additional options to pass into injection.
        #
        # @example
        #   insert_test_suite_setup('...CLASS_NAME...')
        #   => inject_into_file("test/test_config.rb", TEST.gsub(/CLASS_NAME/, @app_name), :after => "set :environment, :test")
        #
        def insert_test_suite_setup(suite_text, options={})
          options = { :path => "test/test_config.rb" }.update(options)
          create_file(options[:path], suite_text.gsub(/CLASS_NAME/, "#{@project_name}::#{@app_name}"))
        end

        ##
        # Injects the mock library include into the test class in test_config
        # for setting up mock gen
        #
        # @param [String] library_name
        #   Name of mocking library.
        # @param [Hash] options
        #
        # @example
        #   insert_mocking_include('Mocha::API'):
        #   => inject_into_file("test/test_config.rb", "  include Mocha::API\n", :after => /class.*?\n/)
        #
        def insert_mocking_include(library_name, options={})
          options = { :indent => 2, :after => /class.*?\n/, :path => "test/test_config.rb" }.update(options)
          return unless File.exist?(destination_root(options[:path]))
          include_text = indent_spaces(2) + "include #{library_name}\n"
          inject_into_file(options[:path], include_text, :after => options[:after])
        end

        ##
        # Returns space characters of given count.
        #
        # @example
        #   indent_spaces(2)
        #
        def indent_spaces(count)
          ' ' * count
        end

        ##
        # Takes in fields for routes in the form of get:index post:test delete:yada.
        #
        # @param [Array<String>] fields
        #   Array of controller actions and route name.
        #
        # @example
        #   controller_actions("get:index", "post:test")
        #
        def controller_actions(fields)
          field_tuples = fields.map { |value| value.split(":") }
          action_declarations = field_tuples.map do |request, name|
            "#{request} :#{name} do\n\nend\n"
          end
          action_declarations.join("\n").gsub(/^/, " " * 2).gsub(/^\s*$/, "")
        end

        def create_helper_files(app, name)
          @helper_name  = "#{name.to_s.underscore.camelize}Helper"
          template 'templates/helper.rb.tt', destination_root(app, 'helpers', "#{name.to_s.underscore}_helper.rb")
          if test?
            include_component_module_for(:test)
            generate_helper_test(@helper_name, @project_name, @app_name)
          end
        end
      end
    end
  end
end
