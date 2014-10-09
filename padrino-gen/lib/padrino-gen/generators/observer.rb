module Padrino
  module Generators
    ##
    # Responsible for generating new observer file for Padrino application.
    #
    class Observer < Thor::Group
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      Padrino::Generators.add_generator(:observer, self)

      class << self
        def source_root; File.expand_path(File.dirname(__FILE__)); end
        def banner; "padrino-gen observer [name]"; end
      end

      desc "Description:\n\n\tpadrino-gen observer generates a new observer file."

      argument     :name,        :desc => 'The name of your observer'
      class_option :root,        :desc => 'The root destination',                     :aliases => '-r', :default => '.', :type => :string

      # Show help if no ARGV given
      require_arguments!

      def create_observer
        self.destination_root = options[:root]
        if in_app_root?
          @klass_name = name
          task_name = name.to_s.underscore

          filename   = task_name + ".rb"

          template 'templates/observer.rb.tt', destination_root('app/models/', filename)
        else
          say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        end
      end
    end
  end
end
