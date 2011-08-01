module Padrino
  module Generators
    class  AppRootNotFound < RuntimeError; end

    module Actions

      def self.included(base)
        base.extend(ClassMethods)
      end

      # Performs the necessary generator for a given component choice
      # execute_component_setup(:mock, 'rr')
      def execute_component_setup(component, choice)
        return true && say("Skipping generator for #{component} component...", :yellow) if choice.to_s == 'none'
        say "Applying '#{choice}' (#{component})...", :yellow
        apply_component_for(choice, component)
        send("setup_#{component}") if respond_to?("setup_#{component}")
      end

      # Returns the related module for a given component and option
      # generator_module_for('rr', :mock)
      def apply_component_for(choice, component)
        # I need to override Thor#apply because for unknow reason :verobse => false break tasks.
        path = File.expand_path(File.dirname(__FILE__) + "/components/#{component.to_s.pluralize}/#{choice}.rb")
        say_status :apply, "#{component.to_s.pluralize}/#{choice}"
        shell.padding += 1
        instance_eval(open(path).read)
        shell.padding -= 1
      end

      # Includes the component module for the given component and choice
      # Determines the choice using .components file
      # include_component_module_for(:mock)
      # include_component_module_for(:mock, 'rr')
      def include_component_module_for(component, choice=nil)
        choice = fetch_component_choice(component) unless choice
        return false if choice.to_s == 'none'
        apply_component_for(choice, component)
      end

      # Returns the component choice stored within the .component file of an application
      # fetch_component_choice(:mock)
      def fetch_component_choice(component)
        retrieve_component_config(destination_root('.components'))[component]
      end

      # Set the component choice and store it in the .component file of the application
      # store_component_choice(:renderer, :haml)
      def store_component_choice(key, value)
        path        = destination_root('.components')
        config      = retrieve_component_config(path)
        config[key] = value
        create_file(path, :force => true) { config.to_yaml }
        value
      end

      # Loads the component config back into a hash
      # i.e retrieve_component_config(...) => { :mock => 'rr', :test => 'riot', ... }
      def retrieve_component_config(target)
        YAML.load_file(target)
      end

      # Prompts the user if necessary until a valid choice is returned for the component
      # resolve_valid_choice(:mock) => 'rr'
      def resolve_valid_choice(component)
        available_string = self.class.available_choices_for(component).join(", ")
        choice = options[component]
        until valid_choice?(component, choice)
          say("Option for --#{component} '#{choice}' is not available.", :red)
          choice = ask("Please enter a valid option for #{component} (#{available_string}):")
        end
        choice
      end

      # Returns true if the option passed is a valid choice for component
      # valid_option?(:mock, 'rr')
      def valid_choice?(component, choice)
        choice.present? && self.class.available_choices_for(component).include?(choice.to_sym)
      end

      # Creates a component_config file at the destination containing all component options
      # Content is a yamlized version of a hash containing component name mapping to chosen value
      def store_component_config(destination)
        components = @_components || options
        create_file(destination) do
          self.class.component_types.inject({}) { |result, comp|
            result[comp] = components[comp].to_s; result
          }.to_yaml
        end
      end

      # Returns the root for this thor class (also aliased as destination root).
      def destination_root(*paths)
        File.expand_path(File.join(@destination_stack.last, paths))
      end

      # Returns true if inside a Padrino application
      def in_app_root?
        File.exist?(destination_root('config/boot.rb'))
      end

      # Returns the field with an unacceptable name(for symbol) else returns nil
      def invalid_fields(fields)
        results = fields.select { |field| field.split(":").first =~ /\W/ }
        results.empty? ? nil : results
      end

      # Returns the app_name for the application at root
      def fetch_app_name(app='app')
        app_path = destination_root(app, 'app.rb')
        @app_name ||= File.read(app_path).scan(/class\s(.*?)\s</).flatten[0]
      end

      # Adds all the specified gems into the Gemfile for bundler
      # require_dependencies 'active_record'
      # require_dependencies 'mocha', 'bacon', :group => 'test'
      # require_dependencies 'json', :version => ">=1.2.3"
      def require_dependencies(*gem_names)
        options = gem_names.extract_options!
        gem_names.reverse.each { |lib| insert_into_gemfile(lib, options) }
      end

      # Inserts a required gem into the Gemfile to add the bundler dependency
      # insert_into_gemfile(name)
      # insert_into_gemfile(name, :group => 'test', :require => 'foo')
      # insert_into_gemfile(name, :group => 'test', :version => ">1.2.3")
      def insert_into_gemfile(name, options={})
        after_pattern = options[:group] ? "#{options[:group].to_s.capitalize} requirements\n" : "Component requirements\n"
        version = options.delete(:version)
        gem_options   = options.map { |k, v| "#{k.inspect} => #{v.inspect}" }.join(", ")
        write_option = gem_options.present? ? ", #{gem_options}" : ""
        write_version = version.present? ? ", #{version.inspect}" : ""
        include_text  = "gem '#{name}'"<< write_version << write_option << "\n"
        inject_into_file('Gemfile', include_text, :after => after_pattern)
      end

      # Inserts an hook before or after load in our boot.rb
      # insert_hook("DataMapper.finalize", :after_load)
      def insert_hook(include_text, where)
        inject_into_file('config/boot.rb', "  #{include_text}\n", :after => "Padrino.#{where} do\n")
      end

      # Registers and Creates Initializer.
      # initializer :test, "some stuff here"
      def initializer(name, data=nil)
        @_init_name, @_init_data = name, data
        register = data.present? ? "  register #{name.to_s.camelize}Initializer\n" : "  register #{name}\n"
        inject_into_file destination_root("/app/app.rb"), register, :after => "Padrino::Application\n"
        template "templates/initializer.rb.tt", destination_root("/lib/#{name}_init.rb") if data.present?
      end

      # Insert the regired gem and add in boot.rb custom contribs.
      def require_contrib(contrib)
        insert_into_gemfile 'padrino-contrib'
        contrib = "require '" + File.join("padrino-contrib", contrib) + "'\n"
        inject_into_file destination_root("/config/boot.rb"), contrib, :before => "\nPadrino.load!"
      end

      # Return true if our project has test component
      def test?
        fetch_component_choice(:test).to_s != 'none'
      end

      # Return true if we have a tiny skeleton
      def tiny?
        File.exist?(destination_root("app/controllers.rb"))
      end

      # Run the bundler
      def run_bundler
        say "Bundling application dependencies using bundler...", :yellow
        in_root { run 'bundle install' }
      end

      # Ask something to the user and receives a response.
      #
      # ==== Example
      #
      #   ask("What is your name?")
      #   ask("Path for ruby", "/usr/local/bin/ruby") => "Path for ruby (leave blank for /usr/local/bin/ruby):"
      #
      def ask(statement, default=nil, color=nil)
        default_text = default ? " (leave blank for #{default}):" : nil
        say("#{statement}#{default_text} ", color)
        result = $stdin.gets.strip
        result.blank? ? default : result
      end

      # Raise SystemExit if the app is inexistent
      def check_app_existence(app)
        unless File.exist?(destination_root(app))
          say
          say "================================================================="
          say "We didn't found #{app.underscore.camelize}!                      "
          say "================================================================="
          say
          # raise SystemExit
        end
      end

      # Generates standard and tiny applications within a project
      def app_skeleton(app, tiny=false)
        directory("app/", destination_root(app))
        if tiny # generate tiny structure
          template "templates/controller.rb.tt", destination_root(app, "controllers.rb")
          template "templates/helper.rb.tt", destination_root(app, "helpers.rb")
          @short_name = 'notifier'
          template "templates/mailer.rb.tt", destination_root(app, "mailers.rb")
        else # generate standard folders
          empty_directory destination_root(app, 'controllers')
          empty_directory destination_root(app, 'helpers')
          empty_directory destination_root(app, 'views')
          empty_directory destination_root(app, 'views', 'layouts')
        end
      end

      # Ensure that project name is valid, else raise an NameError
      def valid_constant?(name)
        if name =~ /^\d/
          raise ::NameError, "Project name #{name} cannot start with numbers"
        elsif name =~ /^\W/
          raise ::NameError, "Project name #{name} cannot start with non-word character"
        end
      end

      module ClassMethods
        # Defines a class option to allow a component to be chosen and add to component type list
        # Also builds the available_choices hash of which component choices are supported
        # component_option :test, "Testing framework", :aliases => '-t', :choices => [:bacon, :shoulda]
        def component_option(name, caption, options = {})
          (@component_types   ||= []) << name # TODO use ordered hash and combine with choices below
          (@available_choices ||= Hash.new)[name] = options[:choices]
          description = "The #{caption} component (#{options[:choices].join(', ')}, none)"
          class_option name, :default => options[:default] || options[:choices].first, :aliases => options[:aliases], :desc => description
        end

        # Tell to padrino that for this Thor::Group is necessary a task to run
        def require_arguments!
          @require_arguments = true
        end

        # Return true if we need an arguments for our Thor::Group
        def require_arguments?
          @require_arguments
        end

        # Returns the compiled list of component types which can be specified
        def component_types
          @component_types
        end

        # Returns the list of available choices for the given component (including none)
        def available_choices_for(component)
          @available_choices[component] + [:none]
        end
      end
    end # Actions
  end # Generators
end # Padrino
