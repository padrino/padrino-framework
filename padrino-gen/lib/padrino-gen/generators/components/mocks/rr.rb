def setup_mock
  require_dependencies 'rr', :require => false, :group => 'test'
  case options[:test].to_s
    when 'rspec'
      inject_into_file 'spec/spec_helper.rb', "require 'rr'\n", :after => "\"/../config/boot\")\n"
    when 'minitest'
      insert_mocking_include "RR::Adapters::MiniTest", :path => "test/test_config.rb"
    else
      insert_mocking_include "RR::Adapters::TestUnit", :path => "test/test_config.rb"
  end
end
