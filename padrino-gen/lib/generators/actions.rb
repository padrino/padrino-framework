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
        self.class.send(:include, generator_module_for(choice, component))
        send("setup_#{component}") if respond_to?("setup_#{component}")
      end
      
      # Includes the component module for the given component and choice
      # Determines the choice using .components file
      # include_component_module_for(:mock)
      # include_component_module_for(:mock, 'rr')
      def include_component_module_for(component, root=nil, choice=nil)
        choice = fetch_component_choice(component, root) unless choice
        self.class.send(:include, generator_module_for(choice, component))
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

      # Returns the related module for a given component and option
      # generator_module_for('rr', :mock)
      def generator_module_for(choice, component)
        "Padrino::Generators::Components::#{component.to_s.capitalize.pluralize}::#{choice.to_s.capitalize}Gen".constantize
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

      # Loads the component config back into a hash
      # i.e retrieve_component_config(...) => { :mock => 'rr', :test => 'riot', ... }
      def retrieve_component_config(target)
        YAML.load_file(target)
      end
      
      # Returns the component choice stored within the .component file of an application
      # fetch_component_choice(:mock)
      def fetch_component_choice(component, root=nil)
        comp_path = root ? File.join(root, '.components') : '.components'
        retrieve_component_config(comp_path)[component]
      end
      
      # Returns true if inside a Padrino application
      def in_app_root?(root=nil)
        root ? File.exist?(File.join(root, 'config/boot.rb')) : File.exist?('config/boot.rb')
      end
      
      # Returns the app_name for the application at root
      def fetch_app_name(root=nil)
        app_path = root ? File.join(root, 'app.rb') : 'app.rb'
        @app_name ||= File.read(app_path).scan(/class\s(.*?)\s</).flatten[0]
      end
      
      # Constructs a path from the specified app root
      # build_target_path("app/mailers", "#{@mailer_basename}.rb")
      def app_root_path(*paths)
        settings = paths.extract_options!
        File.join(settings[:root] || options[:root] || '.', *paths)
      end

      module ClassMethods
        # Defines a class option to allow a component to be chosen and add to component type list
        # Also builds the available_choices hash of which component choices are supported
        # component_option :test, "Testing framework", :aliases => '-t', :choices => [:bacon, :shoulda]
        def component_option(name, caption, options = {})
          (@component_types ||= []) << name # TODO use ordered hash and combine with choices below
          (@available_choices ||= Hash.new({}))[name] = options[:choices]
          description = "The #{caption} component (#{options[:choices].join(', ')})"
          class_option name, :default => options[:choices].first, :aliases => options[:aliases], :desc => description
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
    end
  end
end
