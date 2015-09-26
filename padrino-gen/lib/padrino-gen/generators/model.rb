module Padrino
  module Generators
    ##
    # Responsible for generating new models for the specified ORM component.
    #
    class Model < Thor::Group
      Padrino::Generators.add_generator(:model, self)

      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen model [name] [fields]"; end

      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen model generates a new model and migration files"

      argument :name,               :desc => 'The name of your padrino model'
      argument :fields,             :desc => 'The fields for the model',                                     :default => [],    :type => :array
      class_option :root,           :desc => 'The root destination',                       :aliases => '-r', :default => '.',   :type => :string
      class_option :app,            :desc => 'The application destination path',           :aliases => '-a', :default => '.',   :type => :string
      class_option :destroy,                                                               :aliases => '-d', :default => false, :type => :boolean
      class_option :skip_migration,                                                        :aliases => '-s', :default => false, :type => :boolean
      class_option :force,          :desc => 'Generate model files if app already exists', :aliases => '-f', :default => false, :type => :boolean

      # Show help if no ARGV given.
      require_arguments!

      # Execute the model generation.
      #
      def create_model
        app = options[:app]
        return unless valid_model_for?(app)

        include_component_module_for(:test)
        migration_name = "create_#{name.pluralize.underscore}"
        apply_default_fields fields
        create_model_file(name, :fields => fields, :app => app)
        generate_model_test(name) if test?
        create_model_migration(migration_name, name, fields) unless options[:skip_migration]
      end

      private

      ##
      # Validate model characteristics
      # Alert if the model name is being used
      #
      def valid_model_for?(app)
        self.destination_root = options[:root]
        return false unless correct_path?

        check_app_existence(app)

        if options[:destroy]
          self.behavior = :revoke
        else
          unless options[:force]
            say "#{@camel_name} already exists."
            say "Please, change the name."
            return false
          end
        end if model_name_already_exists?

        return false if has_invalid_fields?

        check_orm
      end

      ##
      # Return false if the model name is being used
      #
      def model_name_already_exists?
        @camel_name = name.to_s.underscore.camelize

        @project_name = ""
        @project_name = fetch_project_name

        return false unless already_exists?(@camel_name, @project_name)
        true
      end

      ##
      # Alert if there is not an ORM Adapter
      #
      def check_orm
        return true if include_component_module_for(:orm)

        say "<= You need an ORM adapter for run this generator. Sorry!"
        raise SystemExit
      end

      ##
      # Check app path
      #
      def correct_path?
        return true if in_app_root?
        say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        false
      end

      ##
      # Check if the fields are valid
      #
      def has_invalid_fields?
        if invalids = invalid_fields(fields)
          say 'Invalid field name:', :red
          say " #{invalids.join(", ")}"
        end
      end
    end
  end
end
