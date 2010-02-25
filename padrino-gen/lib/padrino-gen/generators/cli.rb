require 'thor/group'
require 'padrino-core/support_lite'

module Padrino
  module Generators
    ##
    # This class bootstrap +config/boot+ and perform +Padrino::Generators.load_components!+ for handle
    # 3rd party generators
    # 
    class Cli < Thor::Group

      # Include related modules
      include Thor::Actions

      class_option :root, :desc => "The root destination", :aliases => '-r', :default => nil, :type => :string

      # We need to TRY to load boot because some of our app dependencies maybe have 
      # custom generators, so is necessary know who are.
      def load_boot
        begin
          ENV['PADRINO_LOG_LEVEL'] ||= "test"
          if options[:root]
            require File.join(options[:root], 'config/boot.rb') if File.exist?(File.join(options[:root], 'config/boot.rb'))
          else
            require 'config/boot.rb' if File.exist?('config/boot.rb')
          end
        rescue Exception => e
          puts "=> Problem loading config/boot.rb"
          puts ["=> #{e.message}", *e.backtrace].join("\n  ")
        end
      end

      def setup
        Padrino::Generators.load_components!

        generator_kind  = ARGV.delete_at(0).to_s.downcase.to_sym if ARGV[0].present?
        generator_class = Padrino::Generators.mappings[generator_kind]

        if generator_class
          args = ARGV.empty? && generator_class.require_arguments? ? ["-h"] : ARGV
          generator_class.start(args)
        else
          puts "Please specify generator to use (#{Padrino::Generators.mappings.keys.join(", ")})"
        end
      end
    end # Cli
  end # Generators
end # Padrino