require 'padrino-core/version'
require 'securerandom' unless defined?(SecureRandom)

module Padrino
  module Generators
    ##
    # Responsible for generating new Padrino projects based on the specified project components.
    #
    class Project < Thor::Group

      # Add this generator to our padrino-gen
      Padrino::Generators.add_generator(:project, self)

      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      # Defines the banner for this CLI generator
      def self.banner; "padrino-gen project [name] [options]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Runner
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen project generates a new Padrino project"

      argument :name, :desc => 'The name of your padrino project'

      class_option :app ,             :desc => 'The application name',                                             :aliases => '-n', :default => nil,         :type => :string
      class_option :bundle,           :desc => 'Run bundle install',                                               :aliases => '-b', :default => false,       :type => :boolean
      class_option :root,             :desc => 'The root destination',                                             :aliases => '-r', :default => '.',         :type => :string
      class_option :dev,              :desc => 'Use padrino from a git checkout',                                                    :default => false,       :type => :boolean
      class_option :tiny,             :desc => 'Generate tiny app skeleton',                                       :aliases => '-i', :default => false,       :type => :boolean
      class_option :adapter,          :desc => 'SQL adapter for ORM (sqlite, mysql, mysql2, mysql-gem, postgres)', :aliases => '-a', :default => 'sqlite',    :type => :string
      class_option :template,         :desc => 'Generate project from template',                                   :aliases => '-p', :default => nil,         :type => :string
      class_option :gem,              :desc => 'Generate project as a gem',                                        :aliases => '-g', :default => false,       :type => :boolean
      class_option :migration_format, :desc => 'Filename format for migrations (number, timestamp)',                                 :default => 'number',    :type => :string

      # Definitions for the available customizable components
      component_option :orm,        'database engine',    :aliases => '-d', :choices => [:activerecord, :minirecord, :datamapper, :mongomapper, :mongoid, :sequel, :couchrest, :ohm, :mongomatic, :ripple], :default => :none
      component_option :test,       'testing framework',  :aliases => '-t', :choices => [:rspec, :shoulda, :cucumber, :bacon, :testspec, :riot, :minitest], :default => :none
      component_option :mock,       'mocking library',    :aliases => '-m', :choices => [:mocha, :rr], :default => :none
      component_option :script,     'javascript library', :aliases => '-s', :choices => [:jquery, :prototype, :rightjs, :mootools, :extcore, :dojo], :default => :none
      component_option :renderer,   'template engine',    :aliases => '-e', :choices => [:haml, :erb, :liquid, :slim], :default => :slim
      component_option :stylesheet, 'stylesheet engine',  :aliases => '-c', :choices => [:less, :sass, :compass, :scss], :default => :none

      # Show help if no argv given
      require_arguments!

      # Copies over the Padrino base application App
      #
      # @api private
      def setup_project
        valid_constant? name
        app = (options[:app] || "App")

        @project_name = name.gsub(/\W/, '_').underscore.camelize
        @app_name = app.gsub(/\W/, '_').underscore.camelize
        self.destination_root = File.join(options[:root], name)
        if options[:template] # Run the template to create project
          execute_runner(:template, options[:template])
        else # generate project without template
          directory('project/', destination_root)
          empty_directory destination_root('public/images')
          empty_directory destination_root('public/javascripts')
          empty_directory destination_root('public/stylesheets')
          empty_directory destination_root('tmp')
          store_component_config('.components')
          app_skeleton('app', options[:tiny])
          template 'templates/Gemfile.tt', destination_root('Gemfile')
          template 'templates/Rakefile.tt', destination_root('Rakefile')
          if options.gem?
            template 'templates/gem/gemspec.tt', destination_root(name + '.gemspec')
            template 'templates/gem/README.md.tt', destination_root('README.md')
            template 'templates/gem/lib/libname.tt', destination_root("lib/#{name}.rb")
            template 'templates/gem/lib/libname/version.tt', destination_root("lib/#{name}/version.rb")
          end
        end
      end

      # For each component, retrieve a valid choice and then execute the associated generator
      #
      # @api private
      def setup_components
        return if options[:template]
        @_components = options.dup.slice(*self.class.component_types)
        self.class.component_types.each do |comp|
          choice = @_components[comp] = resolve_valid_choice(comp)
          execute_component_setup(comp, choice)
        end
        store_component_config('.components')
        store_component_choice(:namespace, @project_name)
        store_component_choice(:migration_format, options[:migration_format])
      end

      # Bundle all required components using bundler and Gemfile
      #
      # @api private
      def bundle_dependencies
        if options[:bundle]
          run_bundler
        end
      end

      # Finish message
      #
      # @api private
      def finish_message
        say
        say '=' * 65, :green
        say "#{name} is ready for development!", :green
        say '=' * 65, :green
        say "$ cd #{options[:root]}/#{name}"
        say "$ bundle" unless options[:bundle]
        say "="*65, :green
        say
      end

      # Returns the git author name config or a fill-in value
      #
      # @api private
      def git_author_name
        git_author_name = `git config user.name`.chomp rescue ''
        git_author_name.empty? ? "TODO: Write your name" : git_author_name
      end

      # Returns the git author email config or a fill-in value
      #
      # @api private
      def git_author_email
        git_author_email = `git config user.email`.chomp rescue ''
        git_author_email.empty? ? "TODO: Write your email address" : git_author_email
      end
    end # Project
  end # Generators
end # Padrino
