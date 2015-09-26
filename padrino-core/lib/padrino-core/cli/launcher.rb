require 'thor'

module Padrino
  module Cli
    class Launcher < Thor
      include Thor::Actions

      class_option :chdir, :type => :string, :aliases => "-c", :desc => "Change to dir before starting."
      class_option :environment, :type => :string,  :aliases => "-e", :desc => "Padrino Environment."
      class_option :help, :type => :boolean, :desc => "Show help usage"

      desc "start", "Starts the Padrino application (alternatively use 's')."
      map "s" => :start
      method_option :server,    :type => :string,  :aliases => "-a", :desc => "Rack Handler (default: autodetect)"
      method_option :host,      :type => :string,  :aliases => "-h", :desc => "Bind to HOST address (default: 127.0.0.1)"
      method_option :port,      :type => :numeric, :aliases => "-p", :desc => "Use PORT (default: 3000)"
      method_option :daemonize, :type => :boolean, :aliases => "-d", :desc => "Run daemonized in the background."
      method_option :pid,       :type => :string,  :aliases => "-i", :desc => "File to store pid."
      method_option :debug,     :type => :boolean,                   :desc => "Set debugging flags."
      method_option :options,   :type => :array,  :aliases => "-O", :desc => "--options NAME=VALUE NAME2=VALUE2'. pass VALUE to the server as option NAME. If no VALUE, sets it to true. Run '#{$0} --server_options"
      method_option :server_options,   :type => :boolean, :desc => "Tells the current server handler's options that can be used with --options"
      def start(*args)
        prepare :start
        require File.expand_path("../adapter", __FILE__)
        require File.expand_path('config/boot.rb')

        if options[:server_options]
          puts server_options(options)
        else
          Padrino::Cli::Adapter.start(args.last ? options.merge(:config => args.last).freeze : options)
        end
      end

      desc "stop", "Stops the Padrino application (alternatively use 'st')."
      map "st" => :stop
      method_option :pid, :type => :string,  :aliases => "-p", :desc => "File to store pid", :default => 'tmp/pids/server.pid'
      def stop
        prepare :stop
        require File.expand_path("../adapter", __FILE__)
        Padrino::Cli::Adapter.stop(options)
      end

      private

      # https://github.com/rack/rack/blob/master/lib/rack/server.rb\#L100
      def server_options(options)
        begin
          info = []
          server = Rack::Handler.get(options[:server]) || Rack::Handler.default(options)
          if server && server.respond_to?(:valid_options)
            info << ""
            info << "Server-specific options for #{server.name}:"

            has_options = false
            server.valid_options.each do |name, description|
              next if name.to_s.match(/^(Host|Port)[^a-zA-Z]/) # ignore handler's host and port options, we do our own.
              info << "  -O %-21s %s" % [name, description]
              has_options = true
            end
            return "" if !has_options
          end
          info.join("\n")
        rescue NameError
          return "Warning: Could not find handler specified (#{options[:server] || 'default'}) to determine handler-specific options"
        end
      end

      protected

      def prepare(task)
        if options.help?
          help(task.to_s)
          exit
        end
        if options.environment
          ENV["RACK_ENV"] = options.environment.to_s
        else
          ENV["RACK_ENV"] ||= 'development'
        end
        chdir(options.chdir)
        unless File.exist?('config/boot.rb')
          puts "=> Could not find boot file in: #{options.chdir}/config/boot.rb !!!"
          abort
        end
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

      def self.exit_on_failure?
        true
      end
    end
  end
end
