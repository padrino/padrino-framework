module Padrino
  module Generators

    class << self
      def load_paths
        @load_paths ||= Dir[File.dirname(__FILE__) + '/generators/{app,mailer,controller,model,migration}.rb']
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

    class Cli < Thor::Group

      # Include related modules
      include Thor::Actions

      class_option :root, :desc => "The root destination", :aliases => '-r', :default => nil, :type => :string

      # We need to TRY to load boot because some of our app dependencies maybe have 
      # custom generators, so is necessary know who are.
      def load_boot
        require 'padrino-gen/generators/actions'
        Dir[File.dirname(__FILE__) + '/generators/{components}/**/*.rb'].each { |lib| require lib }

        begin
          if options[:root]
            require File.join(options[:root], 'config/boot.rb') if File.exist?(File.join(options[:root], 'config/boot.rb'))
          else
            require 'config/boot.rb' if File.exist?('config/boot.rb')
          end
        rescue Exception => e
          puts "=> Problem loading config/boot.rb"
        end
      end

      def setup
        Padrino::Generators.lockup!

        generator_kind  = ARGV.delete_at(0).to_s.downcase.to_sym if ARGV[0].present?
        generator_class = Padrino::Generators.mappings[generator_kind]

        if generator_class
          generator_class.start(ARGV)
        else
          puts "Please specify generator to use (#{Padrino::Generators.mappings.keys.join(", ")})"
        end
      end

    end

  end
end