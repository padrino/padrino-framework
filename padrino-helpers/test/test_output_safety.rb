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

  it 'should not warn when Padrino renders erb with the stdlib ERB engine' do
    out, err = run_script(<<~'RUBY')
      require 'padrino-core'
      require 'padrino-helpers'
      require 'padrino/rendering/erb_template'
      abort Tilt[:erb].name unless Tilt[:erb] == Padrino::Rendering::ERBTemplate
      app = Sinatra.new(Padrino::Application) do
        register Padrino::Helpers
        get('/erb') { render :erb, '<%= "<b>" %><% form_tag("/") do %><%= text_field_tag :q %><% end %>' }
      end
      body = Rack::MockRequest.new(app).get('/erb').body
      abort body unless body.include?('&lt;b&gt;') && body.include?('<form')
      print Object.autoload?(:SafeBuffer) ? 'not loaded' : 'loaded'
    RUBY
    refute_includes err, deprecation
    assert_equal 'not loaded', out
  end

  it 'should name the reference, not a require wrapper, and warn once if loaded again' do
    out, err = run_script(<<~'RUBY')
      require 'padrino-helpers'
      module Wrapper
        def load_dependency(file)
          yield
        end

        def require(file)
          load_dependency(file) { super }
        end
      end
      Object.include(Wrapper)
      SafeBuffer.new
      load Object.const_source_location(:SafeBuffer).first if Object.respond_to?(:const_source_location)
      print 'done'
    RUBY
    assert_equal 'done', out
    assert_equal 1, err.scan(deprecation).size, err
    assert_includes err, '(first referenced at -e:12)'
  end

  it 'should name a reference at the top of a required file or in a method named like require' do
    [['EMPTY = SafeBuffer.new', 'thing.rb:1'],
     ["def require_permission\n  SafeBuffer.new\nend\nrequire_permission", 'thing.rb:2']].each do |code, location|
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'thing.rb'), code)
        _out, err = run_script(<<~RUBY)
          require 'padrino-helpers'
          require #{File.join(dir, 'thing').inspect}
        RUBY
        assert_includes err, "first referenced at #{File.join(dir, location)})", err
      end
    end
  end

  it 'should stay defined when the warning raises, as with warnings turned into errors' do
    out, _err = run_script(<<~'RUBY')
      require 'padrino-helpers'
      def Warning.warn(message, *)
        raise message
      end
      begin
        SafeBuffer
      rescue RuntimeError
        nil
      end
      print SafeBuffer.equal?(Padrino::SafeBuffer)
    RUBY
    assert_equal 'true', out
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

describe 'Padrino::SafeBuffer mutations' do
  it 'should escape plain strings passed to insert' do
    buffer = Padrino::SafeBuffer.new('<p></p>')
    buffer.insert(3, '<b>x</b>')
    assert_equal '<p>&lt;b&gt;x&lt;/b&gt;</p>', buffer
    assert_predicate buffer, :html_safe?

    safe = Padrino::SafeBuffer.new('<p></p>')
    safe.insert(3, Padrino::SafeBuffer.new('<b>x</b>'))
    assert_equal '<p><b>x</b></p>', safe
    assert_predicate safe, :html_safe?
  end

  it 'should escape plain strings passed to []=' do
    buffer = Padrino::SafeBuffer.new('<p>X</p>')
    buffer['X'] = '<b>x</b>'
    assert_equal '<p>&lt;b&gt;x&lt;/b&gt;</p>', buffer
    assert_predicate buffer, :html_safe?

    indexed = Padrino::SafeBuffer.new('<p>X</p>')
    indexed[3, 1] = '<i>y</i>'
    assert_equal '<p>&lt;i&gt;y&lt;/i&gt;</p>', indexed
    assert_predicate indexed, :html_safe?

    safe = Padrino::SafeBuffer.new('<p>X</p>')
    safe['X'] = Padrino::SafeBuffer.new('<b>x</b>')
    assert_equal '<p><b>x</b></p>', safe
    assert_predicate safe, :html_safe?
  end

  it 'should escape plain strings passed to replace' do
    buffer = Padrino::SafeBuffer.new('<p></p>')
    buffer.replace('<b>x</b>')
    assert_equal '&lt;b&gt;x&lt;/b&gt;', buffer
    assert_predicate buffer, :html_safe?

    safe = Padrino::SafeBuffer.new('<p></p>')
    safe.replace(Padrino::SafeBuffer.new('<b>x</b>'))
    assert_equal '<b>x</b>', safe
    assert_predicate safe, :html_safe?
  end

  it 'should clear html_safe? on setbyte' do
    buffer = Padrino::SafeBuffer.new('<p>X</p>')
    buffer.setbyte(3, 60)
    assert_equal '<p><</p>', buffer
    refute_predicate buffer, :html_safe?
  end

  it 'should clear html_safe? on bytesplice' do
    skip 'String#bytesplice not defined' unless String.method_defined?(:bytesplice)

    buffer = Padrino::SafeBuffer.new('<p>X</p>')
    buffer.bytesplice(3, 1, '<b>x</b>')
    refute_predicate buffer, :html_safe?
  end

  it 'should clear html_safe? on append_as_bytes' do
    skip 'String#append_as_bytes not defined' unless String.method_defined?(:append_as_bytes)

    buffer = Padrino::SafeBuffer.new('<p>')
    buffer.append_as_bytes('<b>x</b>', 33)
    assert_equal '<p><b>x</b>!', buffer
    refute_predicate buffer, :html_safe?
  end

  it 'should clear html_safe? for delete_prefix, delete_suffix, scrub, unicode_normalize and encode' do
    refute_predicate Padrino::SafeBuffer.new('<a>').delete_prefix('<'), :html_safe?
    refute_predicate Padrino::SafeBuffer.new('<a>').delete_suffix('>'), :html_safe?
    refute_predicate Padrino::SafeBuffer.new('<a>').scrub, :html_safe?
    refute_predicate Padrino::SafeBuffer.new('<a>').unicode_normalize, :html_safe?
    refute_predicate Padrino::SafeBuffer.new('<a>').encode('UTF-8', invalid: :replace), :html_safe?

    buf1 = Padrino::SafeBuffer.new('<a>')
    buf1.delete_prefix!('<')
    refute_predicate buf1, :html_safe?

    buf2 = Padrino::SafeBuffer.new('<a>')
    buf2.delete_suffix!('>')
    refute_predicate buf2, :html_safe?

    buf3 = Padrino::SafeBuffer.new('<a>')
    buf3.scrub!
    refute_predicate buf3, :html_safe?

    buf4 = Padrino::SafeBuffer.new('<a>')
    buf4.unicode_normalize!
    refute_predicate buf4, :html_safe?

    buf5 = Padrino::SafeBuffer.new('<a>')
    buf5.encode!('UTF-8', invalid: :replace)
    refute_predicate buf5, :html_safe?
  end
end
