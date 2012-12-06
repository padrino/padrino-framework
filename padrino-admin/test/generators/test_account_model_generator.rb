require File.expand_path(File.dirname(__FILE__) + '/../helper')

describe "AccountModelGenerator" do
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
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}", '-d=couchrest') }
      capture_io { generate(:admin_app,"-a=/admin", "--root=#{@apptmp}/sample_project") }

      @model = "#{@apptmp}/sample_project/admin/models/account.rb"
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
