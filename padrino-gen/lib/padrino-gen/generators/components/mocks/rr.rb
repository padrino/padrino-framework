# The lines setup_mock adds for a test component: the helper file, the line they follow, and the lines.
# A switch to another mock removes them through remove_previous_mock_setup.
def mock_setup_lines(test)
  rspec = "  conf.mock_with :rr\n" \
          "  # On ExampleGroup, not conf.include, so RSpec's own matchers (satisfy) stay ahead of rr's DSL.\n" \
          "  RSpec::Core::ExampleGroup.include RR::DSL\n"
  {
    'rspec' => { path: 'spec/spec_helper.rb', after: "RSpec.configure do |conf|\n", text: rspec },
    'minitest' => { path: 'test/test_config.rb', after: "require_relative '../config/boot'\n", text: "require 'rr'\n" },
    'testunit' => { path: 'test/test_config.rb', after: "require_relative '../config/boot'\n", text: "require 'test/unit/rr'\n" },
    'shoulda' => { path: 'test/test_config.rb', after: "require \"test/unit\"\n", text: "require 'test/unit/rr'\n" }
  }[test.to_s]
end

def setup_mock
  require_dependencies 'rr', require: false, group: 'test'

  test = options[:test].to_s
  test = fetch_component_choice(:test).to_s if test.empty?
  require_dependencies 'test-unit-rr', require: false, group: 'test' if %w[testunit shoulda].include?(test)
  if (setup = mock_setup_lines(test))
    inject_into_file setup[:path], setup[:text], after: setup[:after]
    # After the insert, so a helper Thor fails to read keeps the previous mock.
    remove_previous_mock_setup(test)
  else
    say "RR is in the Gemfile but not set up for the '#{test}' test component. To use it, require 'rr', include RR::DSL " \
        'where your tests run, and call RR.reset before and RR.verify after each test: https://github.com/rr/rr#readme', :yellow
  end
end
