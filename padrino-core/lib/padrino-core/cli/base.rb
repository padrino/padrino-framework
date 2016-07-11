require 'padrino-core/cli/launcher'

module Padrino
  module Cli
    class Base < Launcher
      desc "rake", "Execute rake tasks."
      method_option :environment, :type => :string,  :aliases => "-e"
      method_option :list,        :type => :string,  :aliases => "-T", :desc => "Display the tasks (matching optional PATTERN) with descriptions, then exit."
      method_option :trace,       :type => :boolean, :aliases => "-t", :desc => "Turn on invoke/execute tracing, enable full backtrace."
      def rake(*args)
        prepare :rake
        args << "-T" if options[:list]
        args << options[:list]  unless options[:list].nil? || options[:list].to_s == "list"
        args << "--trace" if options[:trace]
        args << "--verbose" if options[:verbose]
        ARGV.clear
        ARGV.concat(args)
        puts "=> Executing Rake #{ARGV.join(' ')} ..."
        load File.expand_path('../rake.rb', __FILE__)
        Rake.application.init
        Rake.application.instance_variable_set(:@rakefile, __FILE__)
        load File.expand_path('Rakefile')
        Rake.application.top_level
      end

      desc "console", "Boots up the Padrino application irb console (alternatively use 'c')."
      map "c" => :console
      def console(*args)
        prepare :console
        require File.expand_path("../../version", __FILE__)
        require File.expand_path('config/boot.rb')
        puts "=> Loading #{Padrino.env} console (Padrino v.#{Padrino.version})"
        require File.expand_path('../console', __FILE__)
        ARGV.clear
        if defined? Pry
          Pry.start
        else
          require 'irb'
          begin
            require "irb/completion"
          rescue LoadError
          end
          IRB.start
        end
      end

      desc "generate", "Executes the Padrino generator with given options (alternatively use 'gen' or 'g')."
      map ["gen", "g"] => :generate
      def generate(*args)
        begin
          # We try to load the vendored padrino-gen if exist
          padrino_gen_path = File.expand_path('../../../../../padrino-gen/lib', __FILE__)
          $:.unshift(padrino_gen_path) if File.directory?(padrino_gen_path) && !$:.include?(padrino_gen_path)
          require 'padrino-core/command'
          require 'padrino-gen/command'
          ARGV.shift
          ARGV << 'help' if ARGV.empty?
          Padrino.bin_gen(*ARGV)
        rescue
          puts "<= You need padrino-gen! Run: gem install padrino-gen"
        end
      end

      desc "version", "Show current Padrino version."
      map ["-v", "--version"] => :version
      def version
        require 'padrino-core/version'
        puts "Padrino v. #{Padrino.version}"
      end

      desc "runner", "Run a piece of code in the Padrino application environment (alternatively use 'run' or 'r')."
      map ["run", "r"] => :runner
      def runner(*args)
        prepare :runner

        code_or_file = args.shift
        abort "Please specify code or file" if code_or_file.nil?

        require File.expand_path('config/boot.rb')

        if File.exist?(code_or_file)
          eval(File.read(code_or_file), nil, code_or_file)
        else
          eval(code_or_file)
        end
      end

      protected

      def self.banner(task=nil, *args)
        "padrino #{task.name}"
      end

      def capture(stream)
        begin
          stream = stream.to_s
          eval "$#{stream} = StringIO.new"
          yield
          result = eval("$#{stream}").string
        ensure
          eval("$#{stream} = #{stream.upcase}")
        end

        result
      end
      alias :silence :capture
    end
  end
end
