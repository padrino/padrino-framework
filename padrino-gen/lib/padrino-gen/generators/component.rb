module Padrino
  module Generators

    ##
    # Responsible for add components within a Padrino project.
    #
    class Component < Thor::Group

      Padrino::Generators.add_generator(:component, self)

      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen component [options]"; end

      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Description:\n\n\tpadrino-gen component add components into a Padrino project"

      class_option :app,     :desc => 'The application name',                                             :aliases => '-n', :default => nil,         :type => :string
      class_option :root,    :desc => 'The root destination',                                             :aliases => '-r', :default => '.',         :type => :string
      class_option :adapter, :desc => 'SQL adapter for ORM (sqlite, mysql, mysql2, mysql-gem, postgres)', :aliases => '-a', :default => 'sqlite',    :type => :string

      defines_component_options :default => false

      ##
      # For each component, retrieve a valid choice and then execute the associated generator.
      #
      def setup_components
        self.destination_root = options[:root]
        if in_app_root?
          @_components = options.class.new options.select{ |key,_| self.class.component_types.include?(key.to_sym) }
          @app_name = (options[:app] || "App").gsub(/\W/, '_').camelize
          if @_components.values.delete_if(&:empty?).empty?
            self.class.start(["-h"])
            say
            say "Current Selected Components:"
            list = []
            self.class.component_types.each do |comp|
              list << [comp, fetch_component_choice(comp)]
            end
            print_table(list, :indent => 2)
            exit
          end

          self.class.component_types.each do |comp|
            next if @_components[comp].empty?

            choice = @_components[comp] = resolve_valid_choice(comp)
            existing = fetch_component_choice(comp)
            if existing != 'none' && existing != choice
              next unless yes?("Switch #{comp} to '#{choice}' from '#{existing}' ?[yes/no]:")
            end
            @project_name = fetch_component_choice(:namespace)
            if comp.to_s == 'test' && !already_exists?(@app_name, @project_name)
              say "#{@project_name}::#{@app_name} does not exist."
              say "Please, change app name."
              next
            end
            execute_component_setup(comp, choice)
            store_component_choice(comp, choice)
            if comp.to_s == 'orm' && choice.to_s != 'none'
              inject_into_file destination_root('Rakefile'), "PadrinoTasks.use(:database)\n", :before => "PadrinoTasks.init"
              inject_into_file destination_root('Rakefile'), "PadrinoTasks.use(#{choice.to_sym.inspect})\n", :before => "PadrinoTasks.init"
            end
          end
        else
          say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        end
      end
    end
  end
end
