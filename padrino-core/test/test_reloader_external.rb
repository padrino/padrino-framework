require File.expand_path(File.dirname(__FILE__) + '/helper')
require File.expand_path(File.dirname(__FILE__) + '/fixtures/reloadable_apps/main/app')

describe "ExternalReloader" do
  describe "for external app" do
    before do
      Padrino.clear!
      Padrino.mount("ReloadableApp::External").to("/reloadable/external")
      Padrino.mount("ReloadableApp::Main").to("/reloadable")
      Padrino.load!
    end

    it "should avoid reloading the file if its path is not started with Padrino.root" do
      @app = Padrino.application
      Padrino.stub(:root, File.expand_path(File.dirname(__FILE__) + '/fixtures/reloadable_apps/main')) do
        get "/reloadable/external/base"
      end
      assert_equal "Hello External App", body
    end
  end
end
