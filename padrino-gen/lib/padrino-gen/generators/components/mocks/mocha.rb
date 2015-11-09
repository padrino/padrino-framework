def setup_mock
  require_dependencies 'mocha', :group => 'test', :require => false
  case options[:test].to_s
    when 'rspec'
      inject_into_file 'spec/spec_helper.rb', "  conf.mock_with :mocha\n", :after => "RSpec.configure do |conf|\n"
    else
      inject_into_file 'test/test_config.rb', "require 'mocha/api'\n", :after => "require File.expand_path(File.dirname(__FILE__) + \"/../config/boot\")\n"
      insert_mocking_include "Mocha::API"
  end
end
