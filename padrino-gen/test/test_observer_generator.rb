require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "ObserverGenerator" do
  def setup
    @apptmp = "#{Dir.tmpdir}/padrino-tests/#{SecureRandom.hex}"
    `mkdir -p #{@apptmp}`
  end

  def teardown
    `rm -rf #{@apptmp}`
  end

  describe 'the observer generator' do
    it 'fail outside app root' do
       out, err = capture_io { generate(:observer, 'foo', "-r=#{@apptmp}") }
       assert_match(/not at the root/, out)
    end

    it 'should generate filename properly' do
      capture_io { generate(:project, 'sample_project', "--root=#{@apptmp}") }
      capture_io { generate(:observer, 'DemoObserver', "-r=#{@apptmp}/sample_project") }
      assert_file_exists("#{@apptmp}/sample_project/app/models/demo_observer.rb")
    end
  end
end
