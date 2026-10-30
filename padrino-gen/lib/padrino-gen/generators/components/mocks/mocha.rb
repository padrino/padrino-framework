# The lines setup_mock adds for a test component: the helper file, the line they follow, and the lines.
# A switch to another mock removes them through remove_previous_mock_setup.
def mock_setup_lines(test)
  {
    'rspec' => { path: 'spec/spec_helper.rb', after: "RSpec.configure do |conf|\n", text: "  conf.mock_with :mocha\n" },
    'minitest' => { path: 'test/test_config.rb', after: "require_relative '../config/boot'\n", text: "require 'mocha/minitest'\n" },
    'testunit' => { path: 'test/test_config.rb', after: "require_relative '../config/boot'\n", text: "require 'mocha/test_unit'\n" },
    'shoulda' => { path: 'test/test_config.rb', after: "require \"test/unit\"\n", text: "require 'mocha/test_unit'\n" }
  }[test.to_s]
end

def setup_mock
  require_dependencies 'mocha', group: 'test', require: false

  test = options[:test].to_s
  test = fetch_component_choice(:test).to_s if test.empty?
  remove_previous_mock_setup(test)
  if (setup = mock_setup_lines(test))
    inject_into_file setup[:path], setup[:text], after: setup[:after]
  else
    say "Mocha is in the Gemfile but not set up for the '#{test}' test component. To use it, require mocha/api " \
        'and call mocha_setup, mocha_verify and mocha_teardown around each test: https://github.com/freerange/mocha#readme', :yellow
  end
end
