module Padrino
  module Tasks
    module Test

      class << self

        # This metod start testing for the given app.
        # It look for any test/test_*.rb file in your app root.
        def start
          puts "=> Starting Test"
          tests = Dir['test/**/test_*.rb'] - ['test/test_helper.rb']
          cmd = "ruby -rubygems -I.:lib -e'%w( #{tests.join(' ')} ).each { |file| require file }'"
          system cmd
        end

      end
    end
  end
end