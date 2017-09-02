require 'padrino-core/version'
require 'securerandom' unless defined?(SecureRandom)

module Padrino
  module Generators
    ##
    # Responsible for generating new Padrino projects based on the specified project components.
    #
    class Project < Thor::Group
      Padrino::Generators.add_generator(:project, self)

      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen project [name] [options]"; end

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
      class_option :lean,             :desc => 'Generate lean project without apps',                               :aliases => '-l', :default => false,       :type => :boolean
      class_option :api,              :desc => 'Generate minimal project for APIs',                                                  :default => false,       :type => :boolean
      class_option :template,         :desc => 'Generate project from template',                                   :aliases => '-p', :default => nil,         :type => :string
      class_option :gem,              :desc => 'Generate project as a gem',                                        :aliases => '-g', :default => false,       :type => :boolean
      class_option :migration_format, :desc => 'Filename format for migrations (number, timestamp)',                                 :default => 'number',    :type => :string
      class_option :adapter,          :desc => 'SQL adapter for ORM (sqlite, mysql, mysql2, mysql-gem, postgres)', :aliases => '-a', :default => 'sqlite',    :type => :string

      # Definitions for the available customizable components.
      defines_component_options

      # Show help if no ARGV given.
      require_arguments!

      ##
      # Copies over the Padrino base application app.
      #
      def setup_project
        valid_constant? name
        app = (options[:app] || "App")

        @project_name = name.gsub(/\W/, '_').underscore.camelize

        fail "Constant `#{@project_name}` already exists. Please, use another name" if already_exists?(@project_name)

        @app_name = app.gsub(/\W/, '_').camelize
        self.destination_root = File.join(options[:root], name)
        if options[:template]
          execute_runner(:template, options[:template])
        else
          directory('project/', destination_root)
          empty_directory destination_root('public/images')
          empty_directory destination_root('public/javascripts')
          empty_directory destination_root('public/stylesheets')
          store_component_config('.components')
          unless options[:lean]
            app_skeleton('app', options[:tiny])
            append_file destination_root('config/apps.rb'), "Padrino.mount('#{@project_name}::#{@app_name}', :app_file => Padrino.root('app/app.rb')).to('/')\n"
          end
          template 'templates/Gemfile.tt', destination_root('Gemfile')
          template 'templates/Rakefile.tt', destination_root('Rakefile')
          template 'templates/project_bin.tt', destination_root("exe/#{name}")
          File.chmod(0755, destination_root("exe/#{name}"))
          if options.gem?
            template 'templates/gem/gemspec.tt', destination_root(name + '.gemspec')
            inject_into_file destination_root('Rakefile'), "require 'bundler/gem_tasks'\n", :after => "require 'bundler/setup'\n"
            template 'templates/gem/README.md.tt', destination_root('README.md')
            template 'templates/gem/lib/libname.tt', destination_root("lib/#{name}.rb")
            template 'templates/gem/lib/libname/version.tt', destination_root("lib/#{name}/version.rb")
          else
            empty_directory_with_keep_file destination_root('tmp')
            empty_directory_with_keep_file destination_root('log')
          end
        end
      end

      ##
      # For each component, retrieve a valid choice and then execute the associated generator.
      #
      def setup_components
        return if options[:template]
        @_components = options.class.new options.select{ |key,_| self.class.component_types.include?(key.to_sym) }
        self.class.component_types.each do |comp|
          choice = @_components[comp] = resolve_valid_choice(comp)
          execute_component_setup(comp, choice)
        end
        store_component_config('.components', :force => true)
        store_component_choice(:namespace, @project_name)
        store_component_choice(:migration_format, options[:migration_format])
      end

      ##
      # Generates test files for tiny app skeleton.
      #
      def setup_test_files
        if options[:tiny] && @_components[:test] != :none
          test_component = @_components[:test]
          test_component = "rspec" if test_component == "cucumber"
          uppercase_test_component = test_component.upcase
          controller_template_name = "#{uppercase_test_component}_CONTROLLER_TEST"
          helper_template_name     = "#{uppercase_test_component}_HELPER_TEST"
          return unless defined?(controller_template_name)

          controller_content = instance_eval(controller_template_name).gsub(/!PATH!/, "Controller").gsub(/!NAME!/, "").gsub(/!EXPANDED_PATH!/, "/")
          helper_content     = instance_eval(helper_template_name).gsub(/!NAME!/, "#{@project_name}::#{@app_name}::#{DEFAULT_HELPER_NAME}")

          proc{|*args| args.map{|str| str.gsub!(/!PATH!/, recognize_path)} }.call(controller_content, helper_content)

          directory_name = [:rspec].include?(test_component.to_sym) ? "spec" : "test"
          base_path      = File.join(directory_name, "app")
          create_file destination_root("#{base_path}/controllers/controllers_#{directory_name}.rb"), controller_content, :skip => true
          create_file destination_root("#{base_path}/helpers/helpers_#{directory_name}.rb"),         helper_content,     :skip => true
          helper_path = destination_root(File.join(directory_name, "#{directory_name == "spec" ? "spec_helper" : "test_config"}.rb"))
          gsub_file helper_path, %r{helpers/\*\*/\*\.rb}, "helpers.rb"
        end
      end

      ##
      # Bundle all required components using bundler and Gemfile.
      #
      def bundle_dependencies
        if options[:bundle]
          run_bundler
        end
      end

      ##
      # Finish message.
      #
      def finish_message
        say
        say '=' * 65, :green
        say "#{name} is ready for development!", :green
        say '=' * 65, :green
        say "$ cd #{options[:root]}/#{name}"
        say "$ bundle --binstubs" unless options[:bundle]
        say "=" * 65, :green
        say
      end

      ##
      # Returns the git author name config or a fill-in value.
      #
      def git_author_name
        git_author_name = `git config user.name`.chomp rescue ''
        git_author_name.empty? ? "TODO: Write your name" : git_author_name
      end

      ##
      # Returns the git author email config or a fill-in value.
      #
      def git_author_email
        git_author_email = `git config user.email`.chomp rescue ''
        git_author_email.empty? ? "TODO: Write your email address" : git_author_email
      end
    end
  end
end
