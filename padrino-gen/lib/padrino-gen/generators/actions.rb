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
        self.class.available_choices_for(component).include? choice.to_sym
      end

      # Creates a component_config file at the destination containing all component options
      # Content is a yamlized version of a hash containing component name mapping to chosen value
      def store_component_config(destination)
        create_file(destination) do
          self.class.component_types.inject({}) { |result, component|
            result[component] = options[component].to_s; result
          }.to_yaml
        end
      end

      # Returns the root for this thor class (also aliased as destination root).
      def destination_root(*paths)
        File.join(@destination_stack.last, paths)
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
      def require_dependencies(*gem_names)
        options = gem_names.extract_options!
        gem_names.reverse.each { |lib| insert_into_gemfile(lib, options) }
      end

      # Inserts a required gem into the Gemfile to add the bundler dependency
      # insert_into_gemfile(name)
      # insert_into_gemfile(name, :group => 'test', :require => 'foo')
      def insert_into_gemfile(name, options={})
        after_pattern = options[:group] ? "#{options[:group].to_s.capitalize} requirements\n" : "Component requirements\n"
        gem_options   = options.map { |k, v| "#{k.inspect} => #{v.inspect}" }.join(", ")
        include_text  = "gem '#{name}'" << (gem_options.present? ? ", #{gem_options}" : "") << "\n"
        inject_into_file('Gemfile', include_text, :after => after_pattern)
      end

      ## Return true if our project has test component
      def test?
        fetch_component_choice(:test).to_s != 'none'
      end

      ## Raise SystemExit if the app is inexistent
      def check_app_existence(app)
        unless File.exist?(destination_root(app))
          say
          say "================================================================="
          say "We didn't found #{app.underscore.classify}! Available apps are:"
          say "================================================================="
          Padrino.mounted_apps.each do |app|
            say " - #{app.app_object}"
          end
          say "================================================================="
          say
          raise SystemExit
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