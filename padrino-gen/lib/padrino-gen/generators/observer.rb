module Padrino
  module Generators
    class Observer < Thor::Group
      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Runner

      Padrino::Generators.add_generator(:observer, self)

      class << self
        def source_root; File.expand_path(File.dirname(__FILE__)); end
        def banner; "padrino-gen observer [name]"; end
      end

      desc "Description:\n\n\tpadrino-gen observer generates a new observer file."

      argument     :name,        :desc => 'The name of your observer'

      def create_model
        if in_app_root?

        else
          say 'You are not at the root of a Padrino application! (config/boot.rb not found)'
        end
      end
    end
  end
end
