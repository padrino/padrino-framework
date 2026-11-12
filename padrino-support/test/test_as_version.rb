require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'AS_VERSION' do
  # Runs script in a new process, as padrino-support reads AS_VERSION when it loads, and returns
  # the last line it prints (the Gemfile may print first) and its stderr. The script sets
  # AS_VERSION after Bundler has read the Gemfile, which reads it too.
  def run_script(script)
    Dir.mktmpdir do |dir|
      env = { 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
      lib = File.expand_path('../lib', __dir__)
      out, err, status = Open3.capture3(env, RbConfig.ruby, '-rbundler/setup', '-I', lib, '-e', script, chdir: dir)
      assert status.success?, err
      [out.lines.last, err]
    end
  end

  it 'should load the ActiveSupport extensions and warn once that the switch goes in Padrino 1.0' do
    out, err = run_script(<<~RUBY)
      unless Gem.loaded_specs['activesupport']
        print 'no activesupport'
        exit
      end
      ENV['AS_VERSION'] = '1'
      require 'padrino-support'
      load 'padrino-support.rb'
      print ''.respond_to?(:blank?)
    RUBY
    skip 'activesupport is not in the bundle' if out == 'no activesupport'
    assert_equal 'true', out
    assert_equal 1, err.scan('Loading ActiveSupport extensions through AS_VERSION is deprecated').size, err
    assert_includes err, 'will be removed in Padrino 1.0. Require the ones your app uses before Padrino instead.'
  end

  it 'should not warn without AS_VERSION' do
    _out, err = run_script(<<~RUBY)
      ENV.delete('AS_VERSION')
      require 'padrino-support'
    RUBY
    refute_includes err, 'AS_VERSION'
  end
end
