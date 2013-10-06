require File.expand_path(File.dirname(__FILE__) + '/helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/apps/system')

describe "SystemReloader" do
  context 'for wierd and difficult reload events' do
    should 'reload system features if they were required only in helper' do
      @app = SystemDemo
      @app.reload!
      get '/'
      assert_equal 'Resolv', body
    end
  end
end
