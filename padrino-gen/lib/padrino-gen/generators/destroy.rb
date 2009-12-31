require 'thor'

module Padrino
  module Generators
    
    class Destroy < Thor::Group
    
      #add this generator of destruction to padrino-gen
      Padrino::Generators.add_generator(:destroy, self)
      
      # Define the source template root
      def self.source_root; File.expand_path(File.dirname(__FILE__)); end
      def self.banner; "padrino-gen destroy [component] [name]"; end

      # Include related modules
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions
      
      desc "Description:\n\n\tpadrino-gen destroy destroys a component and all associated files"

      argument :component, :desc => "The type of component to destroy"
      argument :name, :desc => "The name of your padrino component"
      class_option :root, :aliases => '-r', :default => nil, :type => :string
      
      def destroy_component
        if in_app_root?(options[:root])
          include_component_module_for(:destroyer, options[:root], component)
          destroy(name)
        else
          say "You are not at the root of a Padrino application! (config/boot.rb not found)" and return unless in_app_root?
        end
      end
    end
  end
end