def setup_mock
  require_dependencies 'rr', require: false, group: 'test'

  test = options[:test].to_s
  test = fetch_component_choice(:test).to_s if test.empty?
  case test
  when 'rspec'
    setup = "  conf.mock_with :rr\n" \
            "  # On ExampleGroup, not conf.include, so RSpec's own matchers (satisfy) stay ahead of rr's DSL.\n" \
            "  RSpec::Core::ExampleGroup.include RR::DSL\n"
    inject_into_file 'spec/spec_helper.rb', setup, after: "RSpec.configure do |conf|\n"
  when 'minitest'
    inject_into_file 'test/test_config.rb', "require 'rr'\n", after: "require_relative '../config/boot'\n"
  when 'testunit'
    require_dependencies 'test-unit-rr', require: false, group: 'test'
    inject_into_file 'test/test_config.rb', "require 'test/unit/rr'\n", after: "require_relative '../config/boot'\n"
  when 'shoulda'
    require_dependencies 'test-unit-rr', require: false, group: 'test'
    inject_into_file 'test/test_config.rb', "require 'test/unit/rr'\n", after: "require \"test/unit\"\n"
  else
    say "RR is in the Gemfile but not set up for the '#{test}' test component. To use it, require 'rr', include RR::DSL " \
        'where your tests run, and call RR.reset before and RR.verify after each test: https://github.com/rr/rr#readme', :yellow
  end
end
