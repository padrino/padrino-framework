require 'thor'
require File.dirname(__FILE__) + "/tasks/helpers"

module Padrino
  module Tasks 
    class Base < Thor
      include Thor::Actions
      include Padrino::Tasks::Helpers

      class_option :chdir, :type => :string, :aliases => "-c"

      desc "start ", "Starts the Padrino application"

      method_option :environment, :type => :string,  :aliases => "-e", :required => true, :default => :development
      method_option :adapter,     :type => :string,  :aliases => "-a", :required => true, :default => :thin
      method_option :host,        :type => :string,  :aliases => "-h", :required => true, :default => "localhost"
      method_option :port,        :type => :numeric, :aliases => "-p", :required => true, :default => 3000
      method_option :daemonize,   :type => :boolean, :aliases => "-d"

      desc "start", "Start the Padrino application"
      def start
        require File.dirname(__FILE__) + "/tasks/adapter"
        chdir(options.chdir)
        Padrino::Tasks::Adapter.start(options)
      end

      desc "stop", "Stops the Padrino application"
      def stop
        require File.dirname(__FILE__) + "/tasks/adapter"
        chdir(options.chdir)
        Padrino::Tasks::Adapter.stop
      end

      desc "test", "Executes all the Padrino test files"
      def test
        require File.dirname(__FILE__) + "/tasks/test"
        chdir(options.chdir)
        Padrino::Tasks::Test.start
      end

      desc "console ENVIRONMENT", "Boots up the Padrino application irb console"
      def console(environment="development")
        require File.dirname(__FILE__) + "/version.rb"
        boot = 'config/boot.rb'
        boot = File.join(options.chdir, boot) if options.chdir
        raise "Are you in a Padrino Project? We didn't find #{boot} !!!" unless File.exist?(boot)
        ENV["PADRINO_ENV"] ||= environment
        puts "=> Loading #{environment} console (Padrino v.#{Padrino.version})"
        irb   = RUBY_PLATFORM =~ /(:?mswin|mingw)/ ? 'irb.bat' : 'irb'
        libs  = " -r irb/completion"
        libs << " -r #{boot}"
        libs << " -r #{File.dirname(__FILE__)}/tasks/console"
        exec "#{irb} #{libs} --simple-prompt"
      end
    end
  end
end
