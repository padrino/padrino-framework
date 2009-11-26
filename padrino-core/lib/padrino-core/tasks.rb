require 'thor'
require File.dirname(__FILE__) + "/tasks/helpers"

module Padrino
  module Tasks
    class Base < Thor
      include Thor::Actions
      include Padrino::Tasks::Helpers

      class_option :chdir, :type => :string, :aliases => "-c"

      desc "start", "Starts the Padrino application"
      method_option :environment, :type => :string,  :aliases => "-e", :required => true, :default => :development
      method_option :adapter,     :type => :string,  :aliases => "-a", :required => true, :default => :thin
      method_option :host,        :type => :string,  :aliases => "-h", :required => true, :default => "localhost"
      method_option :port,        :type => :numeric, :aliases => "-p", :required => true, :default => 3000
      method_option :boot,        :type => :string,  :aliases => "-b", :required => true, :default => "config/boot.rb"
      method_option :daemonize,   :type => :boolean, :aliases => "-d"
      def start
        require File.dirname(__FILE__) + "/tasks/adapter"
        boot = check_boot
        return unless boot
        require boot
        Padrino::Tasks::Adapter.start(options)
      end

      desc "stop", "Stops the Padrino application"
      def stop
        require File.dirname(__FILE__) + "/tasks/adapter"
        Padrino::Tasks::Adapter.stop
      end

      desc "test", "Executes all the Padrino test files"
      def test
        require File.dirname(__FILE__) + "/tasks/test"
        Padrino::Tasks::Test.start
      end

      desc "rake", "Execute rake tasks in {Padrino.root}/lib/tasks"
      method_option :boot,        :type => :string, :aliases => "-b", :required => true, :default => "config/boot.rb"
      method_option :environment, :type => :string, :aliases => "-e", :required => true, :default => :development
      def rake
        boot = check_boot
        return unless boot
        require 'rake'
        # TODO: better way for do that
        # 
        # This hack is necessary for remove from ARGV (that's it's used by rake) thor things.
        options.each do |k,v| 
          ARGV.each_with_index do |a,i| 
            if ARGV[i] == v # if we found a thor value
              ARGV.delete_at(i) # we remove this value
              ARGV.delete_at(i-1) # and their method_option
            end
          end
        end
        puts "=> Executing Rake #{ARGV.first}..."
        Rake.application.init
        load(File.dirname(__FILE__) + "/tasks/rakefile.rb")
        Padrino::Tasks::RakeFile.boot_file = boot
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
        require File.dirname(__FILE__) + '/tasks/console'
        IRB.start
      end

      private
        def check_boot
          ENV["PADRINO_ENV"] ||= options.environment.to_s
          chdir(options.chdir)
          boot = options.chdir ? File.join(options.chdir, options.boot) : options.boot
          unless File.exist?(boot)
            puts "=> Could not find boot file: #{boot.inspect} !!!"
            return
          end
          boot
        end
    end
  end
end