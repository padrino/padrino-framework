def setup_mock
  require_dependencies 'mocha', group: 'test', require: false

  test = options[:test].to_s
  test = fetch_component_choice(:test).to_s if test.empty?
  case test
  when 'rspec'
    inject_into_file 'spec/spec_helper.rb', "  conf.mock_with :mocha\n", after: "RSpec.configure do |conf|\n"
  when 'minitest'
    inject_into_file 'test/test_config.rb', "require 'mocha/minitest'\n", after: "require_relative '../config/boot'\n"
  when 'testunit'
    inject_into_file 'test/test_config.rb', "require 'mocha/test_unit'\n", after: "require_relative '../config/boot'\n"
  when 'shoulda'
    inject_into_file 'test/test_config.rb', "require 'mocha/test_unit'\n", after: "require \"test/unit\"\n"
  else
    say "Mocha is in the Gemfile but not set up for the '#{test}' test component. To use it, require mocha/api " \
        'and call mocha_setup, mocha_verify and mocha_teardown around each test: https://github.com/freerange/mocha#readme', :yellow
  end
end
