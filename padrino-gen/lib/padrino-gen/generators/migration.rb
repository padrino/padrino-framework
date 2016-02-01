module Padrino
  module Generators
    ##
    # Responsible for generating migration files for the appropriate ORM component.
    #
    class Migration < Thor::Group
      Padrino::Generators.add_generator(:migration, self)

      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen migration [name] [fields]"; end

      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen migration generates a new migration file"

      argument :name, :desc => 'The name of your padrino migration'
      argument :columns, :desc => 'The columns for the migration', :type => :array, :default => []
      class_option :root, :desc => 'The root destination', :aliases => '-r', :default => '.', :type => :string
      class_option :destroy, :aliases => '-d', :default => false, :type => :boolean

      # Show help if no ARGV given.
      require_arguments!

      # Creates the migration file within a Padrino project.
      def create_migration
        validate_namespace name
        self.destination_root = options[:root]
        if in_app_root?
          self.behavior = :revoke if options[:destroy]
          if include_component_module_for(:orm)
            create_migration_file(name, name, columns)
          else
            say '<= You need an ORM adapter for run this generator. Sorry!'
            raise SystemExit
          end
        else
          say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        end
      end
    end
  end
end
