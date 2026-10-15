require_relative 'helper'
require 'minitest/mock'
require 'padrino-core'

describe 'AssetTagHelpers for an app mounted under a sub-path' do
  after do
    Object.send(:remove_const, :StampedSubApp) if defined?(::StampedSubApp)
    Padrino.clear!
  end

  it 'should stamp an asset from the shared public folder when public/<uri_root> lacks it' do
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, 'public', 'myapp'))
      css = File.join(root, 'public', 'stylesheets', 'site.css')
      FileUtils.mkdir_p(File.dirname(css))
      File.write(css, 'body {}')
      File.utime(Time.at(1_577_836_800), Time.at(1_577_836_800), css)
      Padrino.stub(:root, proc { |*args| File.expand_path(File.join(root, *args)) }) do
        ::StampedSubApp = Class.new(Padrino::Application) do
          register Padrino::Helpers
          get('/tag') { stylesheet_link_tag('site') }
        end
        Padrino.mount('stamped_sub_app', app_file: __FILE__).to('/myapp')
        res = Rack::MockRequest.new(Padrino.application).get('/myapp/tag')
        assert_includes res.body, 'site.css?1577836800'
      end
    end
  end

  it 'should stamp assets in a standalone Sinatra app that registers Padrino::Routing' do
    app = Class.new(Sinatra::Base) do
      register Padrino::Routing
      register Padrino::Helpers
      get('/tag') { stylesheet_link_tag('nope') }
    end
    res = Rack::MockRequest.new(app).get('/tag')
    assert_equal 200, res.status
    assert_match(/nope\.css\?\d+/, res.body)
  end
end
