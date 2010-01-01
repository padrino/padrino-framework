require File.dirname(__FILE__) + '/helper'
require 'thor'

class TestDestroyGenerator < Test::Unit::TestCase
  def setup
    Padrino::Generators.lockup!
    @app = Padrino::Generators::App.dup
    @controller_gen = Padrino::Generators::Controller.dup
    @mailer_gen = Padrino::Generators::Mailer.dup
    @migration_gen = Padrino::Generators::Migration.dup
    @model_gen = Padrino::Generators::Model.dup
    @destroyer = Padrino::Generators::Destroy.dup
    `rm -rf /tmp/sample_app`
  end

context "the destruction of models" do
  setup do
    silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=bacon']) }
    silence_logger { @model_gen.start(['user', '-r=/tmp/sample_app']) }
    silence_logger { @destroyer.start(['model','user','-r=/tmp/sample_app']) }
  end
  
  should "destroy model file" do
    assert_no_file_exists('/tmp/sample_app/app/models/user.rb')
  end
  
  should "destroy migration file" do
    assert_no_file_exists('/tmp/sample_app/db/migrate/001_create_users.rb')
  end
  
  should "destroy test file" do
    assert_no_file_exists('/tmp/sample_app/test/models/user_test.rb')
  end
  
end
 
context "the destruction of models using rspec" do
  setup do
    silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=rspec']) }
    silence_logger { @model_gen.start(['user', '-r=/tmp/sample_app']) }
    silence_logger { @destroyer.start(['model','user','-r=/tmp/sample_app']) }
  end
  
  should "destroy spec file" do
    assert_no_file_exists('/tmp/sample_app/test/models/user_spec.rb')
  end
end 

# context "the destruction of models via revoke" do
#   setup do
#     silence_logger { @app.start(['sample_app', '/tmp', '--script=none', '-t=bacon']) }
#     silence_logger { @model_gen.start(['user', '-r=/tmp/sample_app']) }
#     silence_logger { @model_gen.start(['user', '-r=/tmp/sample_app', '-d=true']) }
#   end
#   
#   should "destroy model file" do
#     assert_no_file_exists('/tmp/sample_app/app/models/user.rb')
#   end
#   
#   # should "destroy migration file" do
#   #   assert_no_file_exists('/tmp/sample_app/db/migrate/001_create_users.rb')
#   # end
#   
#   should "destroy test file" do
#     assert_no_file_exists('/tmp/sample_app/test/models/user_test.rb')
#   end
#   
# end

end
