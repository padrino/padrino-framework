require 'thor'

module Padrino
  module Tasks 
    class Base < Thor
      include Thor::Actions
      
      desc "start", "Starts the Padrino application"
      def start
        say "Starting the Padrino application from root #{destination_root}"
      end
      
      desc "stop", "Stops the Padrino application"
      def stop
        say "Stopping the Padrino application"
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
