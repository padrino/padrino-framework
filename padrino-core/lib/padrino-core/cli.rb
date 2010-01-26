require 'thor'
require 'thor/rake_compat'

module Padrino
  module Cli
    class Base < Thor
      include Thor::Actions
      include Thor::RakeCompat

      class_option :chdir, :type => :string, :aliases => "-c"

      desc "start", "Starts the Padrino application"
      method_option :environment, :type => :string,  :aliases => "-e", :required => true, :default => :development
      method_option :adapter,     :type => :string,  :aliases => "-a", :required => true, :default => :thin
      method_option :host,        :type => :string,  :aliases => "-h", :required => true, :default => "localhost"
      method_option :port,        :type => :numeric, :aliases => "-p", :required => true, :default => 3000
      method_option :boot,        :type => :string,  :aliases => "-b", :required => true, :default => "config/boot.rb"
      method_option :daemonize,   :type => :boolean, :aliases => "-d"
      def start
        require File.dirname(__FILE__) + "/cli/adapter"
        boot = check_boot
        return unless boot
        require boot
        Padrino::Cli::Adapter.start(options)
      end

      desc "stop", "Stops the Padrino application"
      def stop
        require File.dirname(__FILE__) + "/cli/adapter"
        Padrino::Cli::Adapter.stop
      end

      desc "test", "Executes all the Padrino test files"
      def test
        require File.dirname(__FILE__) + "/cli/test"
        Padrino::Cli::Test.start
      end

      desc "rake", "Execute rake tasks in {Padrino.root}/lib/tasks"
      method_option :boot,        :type => :string, :aliases => "-b", :required => true, :default => "config/boot.rb"
      method_option :environment, :type => :string, :aliases => "-e", :required => true, :default => :development
      method_option :task_list,   :type => :string, :aliases => "-T"  # Only for accept rake
      def rake(task="")
        ENV['PADRINO_LOG_LEVEL'] ||= "test"
        boot = check_boot
        return unless boot
        require 'rake'
        require boot
        puts "=> Executing Rake..."
        Rake.application.init
        load(File.dirname(__FILE__) + "/cli/rake.rb")
        Rake.application.top_level
      end

      desc "console", "Boots up the Padrino application irb console"
      method_option :boot,        :type => :string, :aliases => "-b", :required => true, :default => "config/boot.rb"
      method_option :environment, :type => :string, :aliases => "-e", :required => true, :default => :development
      def console
        require File.dirname(__FILE__) + "/version"
        boot = check_boot
        return unless boot
        ARGV.clear
        puts "=> Loading #{options.environment} console (Padrino v.#{Padrino.version})"
        require 'irb'
        require "irb/completion"
        require boot
        require File.dirname(__FILE__) + '/cli/console'
        IRB.start
      end

      private
        def check_boot
          ENV["PADRINO_ENV"] ||= options.environment.to_s
          chdir(options.chdir)
          unless File.exist?(options.boot)
            puts "=> Could not find boot file: #{options.boot.inspect} !!!"
            return
          end
          options.boot
        end

      protected
        def self.banner(task)
          "padrino-gen #{task.name}"
        end

        def chdir(dir)
          return unless dir
          begin
            Dir.chdir(dir.to_s)
          rescue Errno::ENOENT
            puts "=> Specified Padrino root '#{dir}' " +
                 "does not appear to exist!"
          rescue Errno::EACCES
            puts "=> Specified Padrino root '#{dir}' " +
                 "cannot be accessed by the current user!"
          end
        end
    end # Base
  end # Cli
end # Padrino