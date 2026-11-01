require_relative 'helper'
require 'tmpdir'

describe 'PADRINO_IGNORE_CALLERS' do
  def ignored?(file)
    Padrino::PADRINO_IGNORE_CALLERS.any? { |pattern| file =~ pattern }
  end

  gems = '/usr/lib/ruby/gems/4.0.0/gems'

  [
    "#{gems}/padrino-0.18.1/lib/padrino.rb",
    "#{gems}/padrino-core-0.18.1/lib/padrino-core/application.rb",
    "#{gems}/padrino-helpers-0.18.1/lib/padrino/rendering.rb",
    "#{gems}/padrino-gen-0.18.1/bin/padrino-gen",
    "#{gems}/padrino-contrib-0.3.0/lib/padrino-contrib/helpers/flash.rb",
    '/home/me/.bundle/gems/padrino-framework-abc123/padrino-core/lib/padrino-core/mounter.rb',
    '/home/me/.gem/bin/padrino',
    '/srv/vendor/core/lib/padrino-core/application/application_setup.rb',
    '/srv/vendor/core/lib/padrino-core.rb',
    "#{gems}/acme-padrino-core-1.0/lib/padrino-core/mounter.rb",
    '/home/me/.bundle/gems/fork-abc123/padrino-helpers/lib/padrino/rendering.rb',
    "#{gems}/padrino-performance-0.18.1/lib/suites/json.rb",
    "#{gems}/acme/lib/padrino-acme.rb",
    "#{gems}/padrino-foo-1.0/lib/foo.rb",
    "#{gems}/puma-6.4/lib/rack/handler/puma.rb",
    "#{gems}/thor-1.5.0/lib/thor.rb",
    "#{gems}/thor-1.5.0/lib/thor/base.rb",
    "#{gems}/thor-1.5.0/bin/thor",
    "#{gems}/rack-3.2.8/lib/rack.rb",
    "#{gems}/rack-3.2.8/lib/rack/builder.rb",
    "#{gems}/rack-protection-4.2.1/lib/rack/protection/base.rb",
    "#{gems}/rack-session-2.1.2/lib/rack/session/cookie.rb",
    "#{gems}/rackup-2.3.1/lib/rackup/server.rb",
    "#{gems}/shotgun-0.9/lib/shotgun/loader.rb",
    "#{gems}/shotgun-0.9/bin/shotgun",
    "#{gems}/mongrel-1.1/lib/mongrel/http_response.rb",
    "#{gems}/mocha-3.1.0/lib/mocha/integration/mini_test.rb",
    "#{gems}/test-unit-3.6/lib/test/unit/testcase.rb"
  ].each do |file|
    it "should ignore the library file #{file}" do
      assert ignored?(file), "#{file} should be ignored"
    end
  end

  %w[
    /home/thor/demo/app/app.rb
    /srv/thor-apps/demo/app/app.rb
    /srv/lib/padrino-blog/demo/app/app.rb
    /srv/demo/bin/padrino-worker
    /srv/padrino-demo/app/app.rb
    /srv/lib/rack-app/demo/app/app.rb
    /srv/lib/rack_demo/demo/app/app.rb
    /srv/lib/mongrel-demo/app/app.rb
    /srv/lib/shotgun-demo/app/app.rb
    /srv/test/unit/demo/app/app.rb
    /srv/mocha/integration/demo/app/app.rb
    /srv/demo/app/thor_helpers.rb
  ].each do |file|
    it "should keep the application file #{file}" do
      refute ignored?(file), "#{file} should not be ignored"
    end
  end

  %w[thor-apps lib/padrino-blog lib/rack-app test/unit].each do |parent|
    it "should find the application file of an app under #{parent}" do
      Dir.mktmpdir do |dir|
        app_file = File.join(dir, parent, 'demo', 'app', 'app.rb')
        FileUtils.mkdir_p(File.dirname(app_file))
        File.write(app_file, "Class.new(Padrino::Application) { $caller_test_app = self }\n")
        begin
          load app_file
          assert_equal File.realpath(app_file), File.realpath($caller_test_app.app_file)
        ensure
          $caller_test_app = nil
        end
      end
    end
  end

  it 'should keep the first caller for a file under a matching directory' do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'thor-apps', 'boot.rb')
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, "$caller_test_file = Padrino.first_caller\n")
      begin
        load file
        assert_equal File.realpath(file), File.realpath($caller_test_file)
      ensure
        $caller_test_file = nil
      end
    end
  end
end
