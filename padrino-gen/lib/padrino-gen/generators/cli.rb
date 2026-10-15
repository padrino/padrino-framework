require 'thor/group'

module Padrino
  module Generators
    ##
    # This class bootstrap +config/boot+ and perform
    # +Padrino::Generators.load_components!+ for handle 3rd party generators.
    #
    class Cli < Thor::Group
      include Thor::Actions

      class_option :root, desc: 'The root destination', aliases: '-r', default: '.', type: :string
      class_option :help, type: :boolean, desc: 'Show help usage'

      ##
      # We need to try to load boot because some of our app dependencies maybe have
      # custom generators, so is necessary know who are.
      #
      def load_boot
        saved_env = { 'BUNDLE_GEMFILE' => ENV['BUNDLE_GEMFILE'], 'PADRINO_LOG_LEVEL' => ENV['PADRINO_LOG_LEVEL'] }
        ENV['PADRINO_LOG_LEVEL'] ||= 'test'
        root = File.expand_path(options[:root] || '.')
        ENV['BUNDLE_GEMFILE'] = File.join(root, 'Gemfile') if options[:root]
        boot = File.join(root, 'config/boot.rb')
        if File.exist?(boot)
          # Boot from the project root, as `padrino start`, rake and the binstubs do, so that its relative paths
          # (such as a sqlite database in config/database.rb) don't resolve against the caller's directory.
          # ceiling: only the boot runs there; a path the project opens lazily after boot (an ActiveRecord connection
          # to a relative path) still resolves against the caller's directory. Running the whole generator from the
          # root would cover it.
          Dir.chdir(root) { require boot }
        else
          require 'padrino-support'
        end
      rescue StandardError => e
        puts "=> Problem loading #{boot}"
        puts ["=> #{e.message}", *e.backtrace].join("\n  ")
      ensure
        ENV.update(saved_env) # restores the caller's values, or removes the ones it didn't have
      end

      ##
      # Loads the components available for all generators.
      #
      def setup
        Padrino::Generators.load_components!

        generator_kind  = ARGV.delete_at(0).to_s.downcase.to_sym if ARGV[0] && !ARGV[0].empty?
        generator_class = Padrino::Generators.mappings[generator_kind]

        if generator_class
          if ARGV.empty? && generator_class.require_arguments?
            generator_class.start(['-h'])
            exit 1
          end
          generator_class.start(ARGV)
        else
          puts "Please specify generator to use (#{Padrino::Generators.mappings.keys.join(', ')})"
          exit 1 unless generator_kind == :help
        end
      end
    end
  end
end
