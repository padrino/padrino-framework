require 'thor'

module Padrino
  module Tasks 
    class Base < Thor
      include Thor::Actions

      desc "start ", "Starts the Padrino application"

      method_option :environment, :type => :string,  :aliases => "-e", :required => true, :default => :development
      method_option :adapter,     :type => :string,  :aliases => "-a", :required => true, :default => :thin
      method_option :host,        :type => :string,  :aliases => "-h", :required => true, :default => "localhost"
      method_option :port,        :type => :numeric, :aliases => "-p", :required => true, :default => 3000
      method_option :daemonize,   :type => :boolean, :aliases => "-d"
      method_option :chdir,       :type => :string,  :aliases => "-c"

      desc "start", "Start the Padrino application"
      def start
        require File.dirname(__FILE__) + "/tasks/adapter"
        require File.join(options.chdir.to_s, 'config/boot')
        Padrino::Tasks::Adapter.start(options)
      end

      desc "stop", "Stops the Padrino application"

      method_option :chdir, :type => :string,  :aliases => "-c"

      def stop
        require File.dirname(__FILE__) + "/tasks/adapter"
        Padrino::Tasks::Adapter.stop(options.chdir)
      end

      desc "test", "Executes all the Padrino test files"
      def test
        say "Executing Padrino test files"
      end

      desc "console ENVIRONMENT", "Boots up the Padrino application irb console"
      def console(environment="development")
        require File.dirname(__FILE__) + "/version.rb"
        raise "Are you in a Padrino Project? We didn't find config/boot.rb !!!" unless File.exist?("config/boot.rb")
        ENV["PADRINO_ENV"] ||= environment
        puts "=> Loading #{environment} console (Padrino v.#{Padrino.version})"
        irb   = RUBY_PLATFORM =~ /(:?mswin|mingw)/ ? 'irb.bat' : 'irb'
        libs  =  " -r irb/completion"
        libs <<  " -r config/boot"
        libs <<  " -r #{File.dirname(__FILE__)}/tasks/console"
        exec "#{irb} #{libs} --simple-prompt"
      end
    end
  end
end
