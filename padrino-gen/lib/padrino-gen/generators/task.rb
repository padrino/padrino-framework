module Padrino
  module Generators
    ##
    # Responsible for generating new task file for Padrino application.
    #
    class Task < Thor::Group
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      Padrino::Generators.add_generator(:task, self)

      class << self
        def source_root; File.expand_path(File.dirname(__FILE__)); end
        def banner; "padrino-gen task [name]"; end
      end

      desc "Description:\n\n\tpadrino-gen task generates a new task file."

      argument     :name,        :desc => 'The name of your application task'
      class_option :root,        :desc => 'The root destination',                     :aliases => '-r', :default => '.', :type => :string
      class_option :description, :desc => 'The description of your application task', :aliases => '-d', :default => nil, :type => :string
      class_option :namespace,   :desc => 'The namespace of your application task',   :aliases => '-n', :default => nil, :type => :string

      # Show help if no ARGV given
      require_arguments!

      def create_task
        validate_namespace name
        self.destination_root = options[:root]
        if in_app_root?
          app        = options[:app]
          @task_name = name.to_s.underscore
          @namespace = options[:namespace].underscore if options[:namespace]
          @desc      = options[:description]
          filename   = @task_name + ".rake"
          filename   = "#{@namespace}_#{filename}" if @namespace

          template 'templates/task.rb.tt', destination_root('tasks', filename)
        else
          say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        end
      end
    end
  end
end
