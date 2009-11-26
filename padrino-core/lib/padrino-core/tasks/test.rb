module Padrino
  module Tasks
    module Test

      class << self

        # This method executes tests found for the given app.
        # It look for any spec/*_spec.rb and test/test_*.rb files in your app root.
        def start
          puts "=> Executing Tests..."
          tests  = Dir['test/**/test_*.rb'] - ['test/test_helper.rb']         # TestUnit
          tests << Dir['test/**/*_test.rb'] - ['test/test_config.rb']         # Bacon
          tests << Dir['spec/**/*_spec.rb'] - Dir['spec/**/spec_helper.rb']   # Rspec
          cmd = "ruby -rubygems -I.:lib -e'%w( #{tests.join(' ')} ).each { |file| require file }'"
          system cmd
        end

      end
    end
  end
end