require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'SafeBuffer' do
  def deprecation
    'The top-level SafeBuffer constant is deprecated'
  end

  # Runs script in a new process (the deprecation warns once per process) and returns the last
  # line it prints (the Gemfile may print first) and its stderr.
  def run_script(script)
    Dir.mktmpdir do |dir|
      env = { 'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__) }
      out, err, status = Open3.capture3(env, RbConfig.ruby, '-rbundler/setup', '-e', script, chdir: dir)
      assert status.success?, err
      [out.lines.last, err]
    end
  end

  it 'should warn once, naming Padrino::SafeBuffer and the line, when the top-level SafeBuffer is used' do
    out, err = run_script(<<~RUBY)
      require 'padrino-helpers'
      buffer = SafeBuffer.new('a')
      ::SafeBuffer.new('b')
      print buffer.html_safe? && SafeBuffer.equal?(Padrino::SafeBuffer)
    RUBY
    assert_equal 'true', out
    assert_equal 1, err.scan(deprecation).size, err
    assert_includes err, 'Padrino 1.0'
    assert_includes err, 'Use Padrino::SafeBuffer instead (first referenced at -e:2)'
  end

  it 'should warn while warnings are off, as they are while the reloader loads app files' do
    _out, err = run_script(<<~RUBY)
      require 'padrino-helpers'
      $VERBOSE = nil
      SafeBuffer.new
    RUBY
    assert_includes err, deprecation
  end

  it 'should not warn when Padrino renders erb, haml and slim templates with helpers' do
    out, err = run_script(<<~'RUBY')
      require 'padrino-core'
      require 'padrino-helpers'
      app = Sinatra.new(Padrino::Application) do
        register Padrino::Helpers
        get('/erb') { render :erb, '<%= "<b>" %><% form_tag("/") do %><%= text_field_tag :q %><% end %>' }
        get('/haml') { render :haml, "= '<b>'\n= form_tag('/') do\n  = text_field_tag :q" }
        get('/slim') { render :slim, "= '<b>'\n= form_tag('/') do\n  = text_field_tag :q" }
        get('/helpers') { content_tag(:p, 'ok') + 'x'.html_safe + link_to('a', '/') }
      end
      request = Rack::MockRequest.new(app)
      bodies = %w[erb haml slim helpers].map { |path| request.get("/#{path}").body }
      abort bodies.inspect unless bodies.first(3).all? { |body| body.include?('&lt;b&gt;') && body.include?('<form') }
      print Object.autoload?(:SafeBuffer) ? 'not loaded' : 'loaded'
    RUBY
    refute_includes err, deprecation
    assert_equal 'not loaded', out
  end

  it 'should be Padrino::SafeBuffer when ActiveSupport defines its own' do
    out, err = run_script(<<~RUBY)
      begin
        require 'active_support/core_ext/string/output_safety'
      rescue LoadError
        print 'no activesupport'
        exit
      end
      require 'padrino-helpers'
      print Padrino::SafeBuffer.equal?(ActiveSupport::SafeBuffer) && SafeBuffer.equal?(ActiveSupport::SafeBuffer)
    RUBY
    skip 'activesupport is not in the bundle' if out == 'no activesupport'
    assert_equal 'true', out
    assert_equal 1, err.scan(deprecation).size, err
  end
end
