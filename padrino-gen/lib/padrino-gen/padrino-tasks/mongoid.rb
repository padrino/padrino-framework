if PadrinoTasks.load?(:mongoid, defined?(Mongoid))
  require 'mongoid'

  namespace :mi do

    if Mongoid::VERSION =~ /^[012]\./
      # Mongoid 2 API
      def mongoid_collections
        Mongoid.master.collections
      end

      def mongoid_collection(name)
        Mongoid.master.collection(name)
      end

      def mongoid_new_collection(collection, name)
        collection.db.collection(name)
      end

      def enum_mongoid_documents(collection)
        collection.find({}, :timeout => false, :sort => "_id") do |cursor|
          cursor.each do |doc|
            yield doc
          end
        end
      end

      def rename_mongoid_collection(collection, new_name)
        collection.rename(new_name)
      end
    else
      # Mongoid 3+ API
      def mongoid_collections
        Mongoid.default_session.collections
      end

      def mongoid_collection(name)
        Mongoid.default_session[name]
      end

      def mongoid_new_collection(collection, name)
        Mongoid.default_session[name]
      end

      def enum_mongoid_documents(collection)
        collection.find.sort(:_id => 1).each do |doc|
          yield doc
        end
      end

      def rename_mongoid_collection(collection, new_name)
        db_name = collection.database.name
        collection.database.session.with(:database => :admin) do |admin|
          admin.command(
            :renameCollection => "#{db_name}.#{collection.name}",
            :to               => "#{db_name}.#{new_name}",
            :dropTarget       => true)
        end
      end
    end

    desc 'Drops all the collections for the database for the current Padrino.env'
    task :drop => :environment do
      mongoid_collections.select {|c| c.name !~ /system/ }.each(&:drop)
    end

    # Helper to retrieve a list of models.
    def get_mongoid_models
      documents = []
      Dir['{app,.}/models/**/*.rb'].sort.each do |file|
        model_path = file[0..-4].split('/')[2..-1]

        begin
          klass = model_path.map(&:classify).join('::').constantize
          if klass.ancestors.include?(Mongoid::Document) && !klass.embedded
            documents << klass
          end
        rescue => e
          # Just for non-mongoid objects that don't have the embedded
          # attribute at the class level.
        end
      end

      documents
    end

    desc 'Create the indexes defined on your mongoid models'
    task :create_indexes => :environment do
      get_mongoid_models.each(&:create_indexes)
    end

    def convert_ids(obj)
      if obj.is_a?(String) && obj =~ /^[a-f0-9]{24}$/
        defined?(Moped) ? Moped::BSON::ObjectId.from_string(obj) : BSON::ObjectId(obj)
      elsif obj.is_a?(Array)
        obj.map do |v|
          convert_ids(v)
        end
      elsif obj.is_a?(Hash)
        obj.each do |k, v|
          obj[k] = convert_ids(v)
        end
      else
        obj
      end
    end

    def collection_names
      @collection_names ||= get_mongoid_models.map{ |d| d.collection.name }.uniq
    end

    desc "Convert string objectids in mongo database to ObjectID type"
    task :objectid_convert => :environment do
      collection_names.each do |collection_name|
        puts "Converting #{collection_name} to use ObjectIDs"

        # Get old collection.
        collection = mongoid_collection(collection_name)

        # Get new collection (a clean one).
        mongoid_collection("#{collection_name}_new").drop
        new_collection = mongoid_new_collection(collection, "#{collection_name}_new")

        # Convert collection documents.
        enum_mongoid_documents(collection) do |doc|
          new_doc = convert_ids(doc)
          new_collection.insert(new_doc, :safe => true)
        end

        puts "Done! Converted collection is in #{new_collection.name}\n\n"
      end

      # No errors. great! now rename _new to collection_name.
      collection_names.each do |collection_name|
        collection = mongoid_collection(collection_name)
        new_collection = mongoid_new_collection(collection, "#{collection_name}_new")

        # Swap collection to _old.
        puts "Moving #{collection.name} to #{collection_name}_old"
        mongoid_new_collection(collection, "#{collection_name}_old").drop

        begin
          rename_mongoid_collection(collection, "#{collection_name}_old")
        rescue StandardError => e
          puts "Unable to rename database #{collection_name} to #{collection_name}_old"
          puts "reason: #{e.message}\n\n"
        end

        # Swap _new to collection.
        puts "Moving #{new_collection.name} to #{collection_name}\n\n"

        begin
          rename_mongoid_collection(new_collection, collection_name)
        rescue StandardError => e
          puts "Unable to rename database #{new_collection.name} to #{collection_name}"
          puts "reason: #{e.message}\n\n"
        end
      end

      puts "DONE! Run `padrino rake mi:cleanup_old_collections` to remove old collections"
    end

    desc "Clean up old collections backed up by objectid_convert"
    task :cleanup_old_collections => :environment do
      collection_names.each do |collection_name|
        collection = mongoid_collection(collection_name)
        mongoid_new_collection(collection, "#{collection.name}_old").drop
      end
    end

    desc "Generates .yml files for I18n translations"
    task :translate => :environment do
      models = Dir["#{Padrino.root}/{app,}/models/**/*.rb"].map { |m| File.basename(m, ".rb") }

      models.each do |m|
        # Get the model class.
        klass = m.camelize.constantize

        # Avoid non Mongoid models.
        next unless klass.ancestors.include?(Mongoid::Document)

        # Init the processing.
        print "Processing #{m.humanize}: "
        FileUtils.mkdir_p("#{Padrino.root}/app/locale/models/#{m}")
        langs = Array(I18n.locale)

        # Create models for it and en locales.
        langs.each do |lang|
          filename   = "#{Padrino.root}/app/locale/models/#{m}/#{lang}.yml"
          columns    = klass.fields.values.map(&:name).reject { |name| name =~ /id/i }
          # If the lang file already exist we need to check it.
          if File.exist?(filename)
            locale = File.open(filename).read
            columns.each do |c|
              locale += "\n        #{c}: #{c.humanize}" unless locale.include?("#{c}:")
            end
            print "Lang #{lang.to_s.upcase} already exist ... "; $stdout.flush
          else
            locale     = "#{lang}:" + "\n" +
            "  models:" + "\n" +
            "    #{m}:" + "\n" +
            "      name: #{klass.name}" + "\n" +
            "      attributes:" + "\n" +
            columns.map { |c| "        #{c}: #{c.humanize}" }.join("\n")
            print "created a new for #{lang.to_s.upcase} Lang ... "; $stdout.flush
          end
          File.open(filename, "w") { |f| f.puts locale }
        end
        puts
      end
    end
  end

  task 'db:drop' => 'mi:drop'
end
