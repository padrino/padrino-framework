require 'rubygems'
require 'thor'

module Padrino
  module Cli

    class Base < Thor
      include Thor::Actions
      include Thor::RakeCompat

      class_option :chdir, :type => :string, :aliases => "-c", :desc => "Change to dir before starting"
      class_option :environment, :type => :string,  :aliases => "-e", :required => true, :default => :development, :desc => "Padrino Environment"
      class_option :help, :type => :boolean, :desc => "Show help usage"

      desc "start", "Starts the Padrino application"
      method_option :adapter,     :type => :string,  :aliases => "-a", :desc => "Rack Handler (default: autodetect)"
      method_option :host,        :type => :string,  :aliases => "-h", :required => true, :default => "localhost", :desc => "Bind to HOST address"
      method_option :port,        :type => :numeric, :aliases => "-p", :required => true, :default => 3000, :desc => "Use PORT"
      method_option :daemonize,   :type => :boolean, :aliases => "-d", :desc => "Run daemonized in the background"
      def start
        prepare :start
        require File.expand_path(File.dirname(__FILE__) + "/adapter")
        require File.expand_path('config/boot.rb')
        Padrino::Cli::Adapter.start(options)
      end

      desc "stop", "Stops the Padrino application"
      def stop
        require File.expand_path(File.dirname(__FILE__) + "/adapter")
        Padrino::Cli::Adapter.stop
      end

      desc "rake", "Execute rake tasks"
      method_option :environment, :type => :string,  :aliases => "-e", :required => true, :default => :development
      method_option :list,        :type => :string,  :aliases => "-T", :desc => "Display the tasks (matching optional PATTERN) with descriptions, then exit."
      method_option :trace,       :type => :boolean, :aliases => "-t", :desc => "Turn on invoke/execute tracing, enable full backtrace."
      method_option :verbose,     :type => :boolean, :aliases => "-v", :desc => "Log message to standard output."
      def rake(*args)
        prepare :rake
        args << "-T" if options[:list]
        args << options[:list]  unless options[:list].nil? || options[:list].to_s == "list"
        args << "--trace" if options[:trace]
        args << "--verbose" if options[:verbose]
        ARGV.clear
        ARGV.concat(args)
        puts "=> Executing Rake #{ARGV.join(' ')} ..."
        ENV['PADRINO_LOG_LEVEL'] ||= "test"
        require File.expand_path(File.dirname(__FILE__) + '/rake')
        silence(:stdout) { require File.expand_path('config/boot.rb') }
        PadrinoTasks.init
      end

      desc "console", "Boots up the Padrino application irb console"
      def console
        prepare :console
        require File.expand_path(File.dirname(__FILE__) + "/../version")
        ARGV.clear
        puts "=> Loading #{options.environment} console (Padrino v.#{Padrino.version})"
        require 'irb'
        require "irb/completion"
        require File.expand_path('config/boot.rb')
        require File.expand_path(File.dirname(__FILE__) + '/console')
        IRB.start
      end

      desc "version", "Show current Padrino Version"
      map "-v" => :version, "--version" => :version
      def version
        require 'padrino-core/version'
        puts "Padrino v. #{Padrino.version}"
      end

      private
        def prepare(task)
          if options.help?
            help(task.to_s)
            raise SystemExit
          end
          ENV["PADRINO_ENV"] ||= options.environment.to_s
          ENV["RACK_ENV"] = ENV["PADRINO_ENV"] # Also set this for middleware
          chdir(options.chdir)
          unless File.exist?('config/boot.rb')
            puts "=> Could not find boot file in: #{options.chdir}/config/boot.rb !!!"
            raise SystemExit
          end
        end

      protected
        def self.banner(task)
          "padrino #{task.name}"
        end

        def chdir(dir)
          return unless dir
          begin
            Dir.chdir(dir.to_s)
          rescue Errno::ENOENT
            puts "=> Specified Padrino root '#{dir}' does not appear to exist!"
          rescue Errno::EACCES
            puts "=> Specified Padrino root '#{dir}' cannot be accessed by the current user!"
          end
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
    end # Base
  end # Cli
end # Padrino