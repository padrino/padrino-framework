# The lines setup_mock adds for a test component: the helper file, the line they follow, and the lines.
# %<conf>s is the project's RSpec.configure block variable (MOCK_SETUP_NAME in actions.rb).
# A switch to another mock removes them through remove_previous_mock_setup.
def mock_setup_lines(test)
  rspec = "  %<conf>s.mock_with :rr\n" \
          "  # On ExampleGroup, not %<conf>s.include, so RSpec's own matchers (satisfy) stay ahead of rr's DSL.\n" \
          "  RSpec::Core::ExampleGroup.include RR::DSL\n"
  {
    'rspec' => { path: 'spec/spec_helper.rb', after: "RSpec.configure do |%<conf>s|\n", text: rspec },
    'minitest' => { path: 'test/test_config.rb', after: "require_relative '../config/boot'\n", text: "require 'rr'\n" },
    'testunit' => { path: 'test/test_config.rb', after: "require_relative '../config/boot'\n", text: "require 'test/unit/rr'\n" },
    'shoulda' => { path: 'test/test_config.rb', after: "require \"test/unit\"\n", text: "require 'test/unit/rr'\n" }
  }[test.to_s]
end

def setup_mock
  require_dependencies 'rr', require: false, group: 'test'

  test = applied_component_choice(:test)
  require_dependencies 'test-unit-rr', require: false, group: 'test' if %w[testunit shoulda].include?(test)
  if (setup = mock_setup_lines(test))
    insert_mock_setup('RR', test, setup)
  else
    say "RR is in the Gemfile but not set up for the '#{test}' test component. To use it, require 'rr', include RR::DSL " \
        'where your tests run, and call RR.reset before and RR.verify after each test: https://github.com/rr/rr#readme', :yellow
  end
end
