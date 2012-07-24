def setup_mock
  require_dependencies 'rr', :group => 'test'
  case options[:test].to_s
    when 'rspec'
      inject_into_file 'spec/spec_helper.rb', "  conf.mock_with :rr\n", :after => "RSpec.configure do |conf|\n"
    when 'riot'
      inject_into_file "test/test_config.rb","require 'riot/rr'\n", :after => "\"/../config/boot\")\n"
    when 'minitest'
      insert_mocking_include "RR::Adapters::MiniTest", :path => "test/test_config.rb"
    else # default include
      insert_mocking_include "RR::Adapters::RRMethods", :path => "test/test_config.rb"
  end
end
