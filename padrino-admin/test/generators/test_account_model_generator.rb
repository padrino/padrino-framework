require File.expand_path(File.dirname(__FILE__) + '/../helper')

class TestAccountModelGenerator < Test::Unit::TestCase
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{UUID.new.generate}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end
  
  # COUCHREST
  context 'account model using couchrest' do
    setup do
      silence_logger { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=couchrest') }
      silence_logger { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      
      @model = "#{@apptmp}/sample_project/app/models/account.rb"
    end
    
    should 'be a couchrest model instance' do
      assert_match_in_file(/class Account < CouchRest::Model::Base/m, @model)
    end
    
    should 'not require additional validations' do
      assert_no_match_in_file(/include CouchRest::Validation/m, @model)
    end
    
    should 'no longer have validates_with_method' do
      assert_no_match_in_file(/validates_with_method/m, @model)
    end
    
    should 'validate report errors using ActiveModel errors method' do
      assert_match_in_file(/errors\.add\(:email, "is not unique"\)/m, @model)
    end
  end
end