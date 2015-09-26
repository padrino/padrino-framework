require File.expand_path(File.dirname(__FILE__) + '/../helper')

describe "AccountModelGenerator" do
  before do
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    %x[mkdir -p #{@apptmp}]
  end

  after do
    %[rm -rf #{@apptmp}]
  end

  describe 'activerecord' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=activerecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should be an activerecord model instance' do
      assert_match_in_file(/class Account < ActiveRecord::Base/m, @model)
    end
  end

  describe 'minirecord' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=minirecord') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should be an activerecord model instance' do
      assert_match_in_file(/class Account < ActiveRecord::Base/m, @model)
    end
  end

  describe 'datamapper' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=datamapper') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should include the datamapper resource' do
      assert_match_in_file(/include DataMapper::Resource/m, @model)
    end
  end

  describe 'mongoid' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=mongoid') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should include the mongoid document' do
      assert_match_in_file(/include Mongoid::Document/m, @model)
    end
  end

  describe 'mongomapper' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=mongomapper') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should include the mongomapper document' do
      assert_match_in_file(/include MongoMapper::Document/m, @model)
    end
  end

  describe 'ohm' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=ohm') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should be an ohm model instance' do
      assert_match_in_file(/class Account < Ohm::Model/m, @model)
    end
  end

  describe 'sequel' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=sequel') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should be a sequel model instance' do
      assert_match_in_file(/class Account < Sequel::Model/m, @model)
    end
  end

  describe 'couchrest' do
    before do
      capture_io { generate(:project, 'sample_project', '-e=slim', "--root=#{@apptmp}", '-d=couchrest') }
      capture_io { generate(:admin_app, "--root=#{@apptmp}/sample_project") }
      @model = "#{@apptmp}/sample_project/models/account.rb"
    end

    it 'should be a couchrest model instance' do
      assert_match_in_file(/class Account < CouchRest::Model::Base/m, @model)
    end
  end
end
