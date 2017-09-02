require 'pathname'

module Padrino
  module Generators
    # Raised when an application does not have a resolved root path.
    class  AppRootNotFound < RuntimeError; end
    ##
    # Default helper name for use in tiny app skeleton generator.
    #
    DEFAULT_HELPER_NAME = "Helper".freeze
    ##
    # Common actions needed to support project and component generation.
    #
    module Actions
      def self.included(base)
        base.extend(ClassMethods)
      end
      ##
      # Avoids editing destination file if it does not exist.
      #
      def inject_into_file(destination, *args, &block)
        destination_path = Pathname.new(destination).absolute? ? destination : destination_root(destination)
        return unless File.exist?(destination_path)
        super
      end

      ##
      # Performs the necessary generator for a given component choice.
      #
      # @param [Symbol] component
      #   The type of component module.
      # @param [String] choice
      #   The name of the component module choice.
      #
      # @example
      #   execute_component_setup(:mock, 'rr')
      #
      def execute_component_setup(component, choice)
        return true && say_status(:skipping, "#{component} component...") if choice.to_s == 'none'
        say_status(:applying, "#{choice} (#{component})...")
        apply_component_for(choice, component)
        send("setup_#{component}") if respond_to?("setup_#{component}")
      end

      ##
      # Returns the related module for a given component and option.
      #
      # @param [String] choice
      #   The name of the component module.
      # @param [Symbol] component
      #   The type of the component module.
      #
      # @example
      #   apply_component_for('rr', :mock)
      #
      def apply_component_for(choice, component)
        # I need to override Thor#apply because for unknow reason :verbose => false break tasks.
        path = File.expand_path(File.dirname(__FILE__) + "/components/#{component.to_s.pluralize}/#{choice}.rb")
        say_status :apply, "#{component.to_s.pluralize}/#{choice}"
        shell.padding += 1
        instance_eval(File.read(path))
        shell.padding -= 1
      end

      ##
      # Includes the component module for the given component and choice.
      # It determines the choice using .components file.
      #
      # @param [Symbol] component
      #   The type of component module.
      # @param [String] choice
      #   The name of the component module.
      #
      # @example
      #   include_component_module_for(:mock)
      #   include_component_module_for(:mock, 'rr')
      #
      def include_component_module_for(component, choice=nil)
        choice = fetch_component_choice(component) unless choice
        return false if choice.to_s == 'none'
        apply_component_for(choice, component)
      end

      ##
      # Returns the component choice stored within the .component file of an application.
      #
      # @param [Symbol] component
      #   The type of component module.
      #
      # @return [String] Name of the component module.
      #
      # @example
      #   fetch_component_choice(:mock)
      #
      def fetch_component_choice(component)
        retrieve_component_config(destination_root('.components'))[component]
      end

      ##
      # Set the component choice in the .component file of the application.
      #
      # @param [Symbol] key
      #   The type of component module.
      # @param [Symbol] value
      #   The name of the component module.
      #
      # @return [Symbol] The name of the component module.
      #
      # @example
      #   store_component_choice(:renderer, :haml)
      #
      def store_component_choice(key, value)
        path        = destination_root('.components')
        config      = retrieve_component_config(path)
        config[key] = value
        create_file(path, :force => true) { config.to_yaml }
        value
      end

      ##
      # Loads the component config back into a hash.
      #
      # @param [String] target
      #   Path to component config file.
      #
      # @return [Hash] Loaded YAML file.
      #
      # @example
      #   retrieve_component_config(...)
      #   # => { :mock => 'rr', :test => 'rspec', ... }
      #
      def retrieve_component_config(target)
        YAML.load_file(target)
      end

      ##
      # Prompts the user if necessary until a valid choice is returned for the component.
      #
      # @param [Symbol] component
      #   The type of component module.
      #
      # @return [String] Name of component if valid, otherwise ask for valid choice.
      #
      # @example
      #   resolve_valid_choice(:mock)
      #
      def resolve_valid_choice(component)
        choices = self.class.available_choices_for(component).map(&:to_s)
        choice = options[component]
        until valid_choice?(component, choice)
          say("Option for --#{component} '#{choice}' is not available.", :red)
          choice = ask("Please enter a valid option for #{component}:", :limited_to => choices)
        end
        choice
      end

      ##
      # Returns true if the option passed is a valid choice for component.
      #
      # @param [Symbol] component
      #   The type of component module.
      # @param [String] choice
      #   The name of the component module.
      #
      # @return [Boolean] Boolean of whether the choice is valid.
      #
      # @example
      #   valid_choice?(:mock, 'rr')
      #
      def valid_choice?(component, choice)
        choice && self.class.available_choices_for(component).include?(choice.to_sym)
      end

      ##
      # Creates a component_config file at the destination containing all component options.
      # Content is a YAMLized version of a hash containing component name mapping to chosen value.
      #
      # @param [String] destination
      #   The file path to store the component config.
      #
      # @example
      #   store_component_config('/foo/bar')
      #
      def store_component_config(destination, opts = {})
        components = @_components || options
        create_file(destination, opts) do
          self.class.component_types.inject({}) { |result, comp|
            result[comp] = components[comp].to_s; result
          }.to_yaml
        end
      end

      ##
      # Returns the root for this Thor class (also aliased as destination root).
      #
      # @param [Array<String>] paths
      #   The relative path from destination root.
      #
      # @return [String] The full path
      #
      # @example
      #   destination_root('config/boot.rb')
      #
      def destination_root(*paths)
        File.expand_path(File.join(@destination_stack.last, paths))
      end

      ##
      # Returns true if inside a Padrino application.
      #
      def in_app_root?
        File.exist?(destination_root('config/boot.rb'))
      end

      ##
      # Returns true if constant name already exists.
      #
      def already_exists?(name, project_name = nil)
        project_name = project_name ? (Object.const_get(project_name) rescue nil) : nil
        Object.const_defined?(name) || (project_name && project_name.const_defined?(name))
      end

      ##
      # Returns the field with an unacceptable name(for symbol) else returns nil.
      #
      # @param [Array<String>] fields
      #   Field names for generators.
      #
      # @return [Array<String>] array of invalid fields
      #
      # @example
      #   invalid_fields ['foo:bar', 'hello:world']
      #
      def invalid_fields(fields)
        results = fields.select { |field| field.split(":").first =~ /\W/ }
        results.empty? ? nil : results
      end

      ##
      # Apply default field types.
      #
      # @param [Array<String>] fields
      #   Field names for generators.
      #
      # @return [Array<String>] fields with default types
      #
      def apply_default_fields(fields)
        fields.map! { |field| field =~ /:/ ? field : "#{field}:string" }
      end

      # Returns the namespace for the project.
      #
      # @param [String] app
      #   folder name of application.
      #
      # @return [String] namespace for application.
      #
      # @example
      #   fetch_project_name
      #
      def fetch_project_name(app='app')
        app_path = destination_root(app, 'app.rb')
        @project_name = fetch_component_choice(:namespace) if @project_name.empty?
        @project_name ||= begin
          say "Autodetecting project namespace using folder name.", :red
          say ""
          detected_namespace = File.basename(destination_root('.')).gsub(/\W/, '_').camelize
          say(<<-WARNING, :red)
From v0.11.0 on, applications should have a `namespace` setting
in their .components file. Please include a line like the following
in your .components file:
WARNING
          say "\t:namespace: #{detected_namespace}", :yellow
          say ""

          detected_namespace
        end
      end

      ##
      # Returns the app_name for the application at root.
      #
      # @param [String] app
      #   folder name of application.
      #
      # @return [String] class name for application.
      #
      # @example
      #   fetch_app_name('subapp')
      #
      def fetch_app_name(app='app')
        app_path = destination_root(app, 'app.rb')
        @app_name ||= File.read(app_path).scan(/class\s(.*?)\s</).flatten[0]
      end

      ##
      # Adds all the specified gems into the Gemfile for bundler.
      #
      # @param [Array<String>] gem_names
      #   Splat of gems to require in Gemfile.
      # @param [Hash] options
      #   The options to pass to gem in Gemfile.
      #
      # @example
      #   require_dependencies('active_record')
      #   require_dependencies('mocha', 'bacon', :group => 'test')
      #   require_dependencies('json', :version => ">=1.2.3")
      #
      def require_dependencies(*gem_names)
        options = gem_names.last.is_a?(Hash) ? gem_names.pop : {}
        gem_names.reverse_each { |lib| insert_into_gemfile(lib, options) }
      end

      ##
      # Inserts a required gem into the Gemfile to add the bundler dependency.
      #
      # @param [String] name
      #   Name of gem to insert into Gemfile.
      # @param [Hash] options
      #   Options to generate into Gemfile for gem.
      #
      # @example
      #   insert_into_gemfile(name)
      #   insert_into_gemfile(name, :group => 'test', :require => 'foo')
      #   insert_into_gemfile(name, :group => 'test', :version => ">1.2.3")
      #
      def insert_into_gemfile(name, options={})
        after_pattern = options[:group] ? "#{options[:group].to_s.capitalize} requirements\n" : "Component requirements\n"
        version       = options.delete(:version)
        gem_options   = options.map { |k, v| k.to_s == 'require' && [true,false].include?(v) ? ":#{k} => #{v}" : ":#{k} => '#{v}'" }.join(", ")
        write_option  = gem_options.empty? ? '' : ", #{gem_options}"
        write_version = version ? ", '#{version}'" : ''
        include_text  = "gem '#{name}'" << write_version << write_option << "\n"
        inject_into_file('Gemfile', include_text, :after => after_pattern)
      end

      ##
      # Inserts an hook before or after load in our boot.rb.
      #
      # @param [String] include_text
      #   Text to include into hooks in boot.rb.
      # @param [Symbol] where
      #   method hook to call from Padrino, i.e :after_load, :before_load.
      #
      # @example
      #   insert_hook("DataMapper.finalize", :after_load)
      #
      def insert_hook(include_text, where)
        inject_into_file('config/boot.rb', "  #{include_text}\n", :after => "Padrino.#{where} do\n")
      end

      ##
      # Inserts a middleware inside app.rb.
      #
      # @param [String] include_text
      #   Text to include into hooks in boot.rb.
      #
      # @example
      #   insert_middleware(ActiveRecord::ConnectionAdapters::ConnectionManagement)
      #
      def insert_middleware(include_text, app=nil)
        name = app || (options[:name] ? @app_name.downcase : 'app')
        inject_into_file("#{name}/app.rb", "    use #{include_text}\n", :after => "Padrino::Application\n")
      end

      ##
      # Registers and creates initializer.
      #
      # @param [Symbol] name
      #   Name of the initializer.
      # @param [String] data
      #   Text to generate into the initializer file.
      #
      # @example
      #   initializer(:test, "some stuff here")
      #   #=> generates 'lib/test_init.rb'
      #
      def initializer(name, data=nil)
        @_init_name, @_init_data = name, data
        register = data ? "    register #{name.to_s.underscore.camelize}Initializer\n" : "    register #{name}\n"
        inject_into_file destination_root("/app/app.rb"), register, :after => "Padrino::Application\n"
        template "templates/initializer.rb.tt", destination_root("/config/initializers/#{name}.rb") if data
      end

      ##
      # Creates and inserts middleware.
      # @param [Symbol, String] name
      #   Name of the middleware.
      # @param [String] source
      #   Text to generate into the middleware file.
      #
      # @example
      #   middleware(:hello, "class Hello\nend")
      #   #=> generates 'lib/hello_middleware.rb'
      #
      def middleware(name, source)
        create_file destination_root("lib/#{name}_middleware.rb"), source
        insert_middleware name.to_s.underscore.camelize
      end

      ##
      # Insert the regired gem and add in boot.rb custom contribs.
      #
      # @param [String] contrib
      #   name of library from padrino-contrib
      #
      # @example
      #   require_contrib('auto_locale')
      #
      def require_contrib(contrib)
        insert_into_gemfile 'padrino-contrib'
        contrib = "require '" + File.join("padrino-contrib", contrib) + "'\n"
        inject_into_file destination_root("/config/boot.rb"), contrib, :before => "\nPadrino.load!"
      end

      ##
      # Return true if our project has test component.
      #
      def test?
        fetch_component_choice(:test).to_s != 'none'
      end

      ##
      # Return true if we have a tiny skeleton.
      #
      def tiny?
        File.exist?(destination_root('app/controllers.rb'))
      end

      ##
      # Run the bundler.
      #
      def run_bundler
        say 'Bundling application dependencies using bundler...', :yellow
        in_root { run 'bundle install --binstubs' }
      end

      ##
      # Raise SystemExit if the app does not exist.
      #
      # @param [String] app
      #   Directory name of application.
      #
      # @example
      #   check_app_existence 'app'
      #
      def check_app_existence(app)
        unless File.exist?(destination_root(app))
          say
          say "================================================================="
          say "Unable to locate '#{app.underscore.camelize}' application        "
          say "================================================================="
          say
          raise SystemExit
        end
      end

      ##
      # Generates standard and tiny applications within a project.
      #
      # @param [String] app
      #   Name of application.
      # @param [Boolean] tiny
      #   Boolean to generate a tiny structure.
      #
      # @example
      #   app_skeleton 'some_app'
      #   app_skeleton 'sub_app', true
      #
      def app_skeleton(app, tiny=false)
        directory('app/', destination_root(app))
        if tiny
          template 'templates/controller.rb.tt', destination_root(app, 'controllers.rb')
          @helper_name = DEFAULT_HELPER_NAME
          template 'templates/helper.rb.tt', destination_root(app, 'helpers.rb')
          @short_name = 'notifier'
          template 'templates/mailer.rb.tt', destination_root(app, 'mailers.rb')
        else
          empty_directory destination_root(app, 'controllers')
          empty_directory destination_root(app, 'helpers')
          empty_directory destination_root(app, 'views')
          empty_directory destination_root(app, 'views', 'layouts')
        end
      end

      ##
      # Ensures that project name is valid, else raise an NameError.
      #
      # @param [String] name
      #   Name of project.
      #
      # @return [Exception] Exception with error message if not valid.
      #
      # @example
      #   valid_constant '1235Stuff'
      #   valid_constant '#Abc'
      #
      def valid_constant?(name)
        if name =~ /^\d/
          fail ::NameError, "Constant name #{name} cannot start with numbers"
        elsif name =~ /^\W/
          fail ::NameError, "Constant name #{name} cannot start with non-word character"
        end
      end

      ##
      # Validates namespace name (controller name, etc.) or fails with an error.
      #
      # @param [String] name
      #   Name of namespace
      #
      # @example
      #   validate_namespace 'Project_One1' #=> pass
      #   validate_namespace 'Erroneous/name' #=> fail
      #
      def validate_namespace(name)
        valid_constant? name
        name.match(/^[[:alnum:]_]+$/) || fail(::NameError, "Namespace '#{name}' must consist only of alphanumeric characters or '_'")
      end

      ##
      # Recognizes the path of application.
      #
      def recognize_path
        options[:app] == '.' ? '/..' : '/../..'
      end

      ##
      # Creates an empty directory with .keep file
      #
      def empty_directory_with_keep_file(destination, config = {})
        empty_directory(destination, config)
        keep_file(destination)
      end

      ##
      # Creates an empty .keep file
      #
      def keep_file(destination)
        create_file("#{destination}/.keep")
      end

      # Class methods for Thor generators to support the generators and component choices.
      module ClassMethods
        ##
        # Defines a class option to allow a component to be chosen and add to component type list.
        # Also builds the available_choices hash of which component choices are supported.
        #
        # @param [Symbol] name
        #   Name of component.
        # @param [String] caption
        #   Description of the component.
        # @param [Hash] options
        #   Additional parameters for component choice.
        #
        # @example
        #   component_option :test, "Testing framework", :aliases => '-t', :choices => [:bacon, :shoulda]
        #
        def component_option(name, caption, options = {})
          (@component_types   ||= []) << name # TODO use ordered hash and combine with choices below
          (@available_choices ||= Hash.new)[name] = options[:choices]
          description = "The #{caption} component (#{options[:choices].join(', ')}, none)"
          class_option name, :default => options[:default] || options[:choices].first, :aliases => options[:aliases], :desc => description
        end

        ##
        # Definitions for the available customizable components.
        #
        def defines_component_options(options = {})
          [
            [ :orm,        'database engine',    { :aliases => '-d', :default => :none }],
            [ :test,       'testing framework',  { :aliases => '-t', :default => :none }],
            [ :mock,       'mocking library',    { :aliases => '-m', :default => :none }],
            [ :script,     'javascript library', { :aliases => '-s', :default => :none }],
            [ :renderer,   'template engine',    { :aliases => '-e', :default => :none }],
            [ :stylesheet, 'stylesheet engine',  { :aliases => '-c', :default => :none }]
          ].each do |name, caption, opts|
            opts[:default] = '' if options[:default] == false
            component_option name, caption, opts.merge(:choices => Dir["#{File.dirname(__FILE__)}/components/#{name.to_s.pluralize}/*.rb"].map{|lib| File.basename(lib, '.rb').to_sym})
          end
        end

        ##
        # Tells Padrino that for this Thor::Group it is a necessary task to run.
        #
        def require_arguments!
          @require_arguments = true
        end

        ##
        # Returns true if we need an arguments for our Thor::Group.
        #
        def require_arguments?
          @require_arguments
        end

        ##
        # Returns the compiled list of component types which can be specified.
        #
        def component_types
          @component_types
        end

        ##
        # Returns the list of available choices for the given component (including none).
        #
        # @param [Symbol] component
        #   The type of the component module.
        #
        # @return [Array<Symbol>] Array of component choices.
        #
        # @example
        #   available_choices_for :test
        #   => [:shoulda, :bacon, :minitest]
        #
        def available_choices_for(component)
          @available_choices[component] + [:none]
        end
      end
    end
  end
end
