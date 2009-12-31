require 'padrino-core/support_lite'
Dir[File.dirname(__FILE__) + '/padrino-gen/generators/{components}/**/*.rb'].each { |lib| require lib }
require File.dirname(__FILE__) + '/padrino-gen/generators/actions.rb'
require File.dirname(__FILE__) + '/padrino-gen/generators/base.rb'

module Padrino
  module Generators

    class << self
      def load_paths
        @load_paths ||= Dir[File.dirname(__FILE__) + '/padrino-gen/generators/{app,mailer,controller,model,migration,destroy}.rb']
      end

      def mappings
        @mappings ||= SupportLite::OrderedHash.new
      end

      def add_generator(name, klass)
        mappings[name] = klass
      end

      def lockup!
        load_paths.each { |lib| require lib  }
      end
    end
  end
end