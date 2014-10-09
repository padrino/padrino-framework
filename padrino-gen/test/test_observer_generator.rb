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
    end
  end
end
