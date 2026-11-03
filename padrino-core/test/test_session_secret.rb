require_relative 'helper'
require 'fileutils'
require 'securerandom'
require 'tmpdir'

class SessionSecretApp < Padrino::Application; end
class SessionSecretApp2 < Padrino::Application; end

class SessionSecretRackApp
  def self.call(_env)
    [200, {}, ['rack']]
  end
end

describe 'Session secret warning' do
  before do
    Padrino.clear!
    @saved_env = ENV.delete('SESSION_SECRET')
    @root = Dir.mktmpdir
    @fallback = SecureRandom.hex(32)
    write 'config/apps.rb', <<~RUBY
      Padrino.configure_apps do
        enable :sessions
        set :session_secret, ENV.fetch('SESSION_SECRET') { '#{@fallback}' }
      end
    RUBY
  end

  after do
    ENV['SESSION_SECRET'] = @saved_env
    %i[SessionSecretFileApp SessionSecretOutsideApp].each do |name|
      Object.send(:remove_const, name) if Object.const_defined?(name, false)
    end
    FileUtils.rm_rf(@root)
    FileUtils.rm_rf(@outside) if @outside
    Padrino.clear!
  end

  def write(path, content, dir = @root)
    path = File.join(dir, path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def project_root
    ->(*args) { File.expand_path(File.join(@root, *args)) }
  end

  # Loads config/apps.rb, configures and mounts the apps as a project's boot
  # does, then builds Padrino.application and returns what it printed on stderr.
  def boot(apps: [SessionSecretApp], env: :production, &app_config)
    Padrino.stub(:root, project_root) do
      load File.join(@root, 'config/apps.rb')
      apps.each_with_index do |app, index|
        app.send(:default_configuration!)
        app.class_eval(&app_config) if app_config
        Padrino.mount(app.name).to("/#{index}")
      end
    end
    build(env)
  end

  # Loads config/apps.rb, then an app file that defines the app class +name+, and mounts it.
  def boot_app_file(name, app_file)
    Padrino.stub(:root, project_root) do
      load File.join(@root, 'config/apps.rb')
      load app_file
      Padrino.mount(name).to('/')
    end
    build
  end

  def build(env = :production)
    Padrino.stub(:root, project_root) do
      Padrino.stub(:env, env) { capture_io { Padrino.application }.last }
    end
  end

  def app_file_setting_secret(name, secret)
    <<~RUBY
      class #{name} < Padrino::Application
        set :session_secret, "#{secret}"
      end
    RUBY
  end

  it 'warns in production when the session secret is the fallback in config/apps.rb' do
    err = boot { set :sessions, same_site: :lax, secure: true }
    assert_includes err, 'WARNING! The session secret appears in config/apps.rb.'
    assert_includes err, 'set the SESSION_SECRET environment variable to a new value'
    assert_includes err, 'padrino rake secret'
    refute_includes err, @fallback
  end

  it 'warns when the secret is double-quoted in config/apps.rb' do
    write 'config/apps.rb', <<~RUBY
      Padrino.configure_apps do
        enable :sessions
        set :session_secret, "#{@fallback}"
      end
    RUBY
    assert_includes boot, 'The session secret appears in config/apps.rb.'
  end

  it 'does not warn when SESSION_SECRET is set' do
    ENV['SESSION_SECRET'] = SecureRandom.hex(32)
    assert_empty boot
  end

  it 'does not warn outside production' do
    assert_empty boot(env: :development)
  end

  it 'does not warn with sessions off' do
    assert_empty(boot { disable :sessions })
  end

  it 'does not warn when the secret comes from another source' do
    credentials = write('credentials/secret', SecureRandom.hex(32))
    assert_empty(boot { set :session_secret, File.read(credentials) })
  end

  it 'does not warn when a session store that takes no secret is used' do
    assert_empty(boot { set :sessions, use: Rack::Session::Pool })
  end

  it 'warns when the secret is in the session store config' do
    err = boot { set :sessions, use: Rack::Session::Cookie, config: { secret: settings.session_secret } }
    assert_includes err, 'The session secret appears in config/apps.rb.'
  end

  it 'warns when one of the rotated secrets is in config/apps.rb' do
    ENV['SESSION_SECRET'] = SecureRandom.hex(32)
    write 'config/apps.rb', <<~RUBY
      Padrino.configure_apps do
        set :sessions, secrets: [ENV.fetch('SESSION_SECRET'), '#{@fallback}']
      end
    RUBY
    assert_includes boot, 'The session secret appears in config/apps.rb.'
  end

  it 'warns when one of the rotated secrets in the session store config is in config/apps.rb' do
    ENV['SESSION_SECRET'] = SecureRandom.hex(32)
    write 'config/apps.rb', <<~RUBY
      Padrino.configure_apps do
        set :sessions, use: Rack::Session::Cookie, config: { secrets: [ENV.fetch('SESSION_SECRET'), '#{@fallback}'] }
      end
    RUBY
    assert_includes boot, 'The session secret appears in config/apps.rb.'
  end

  it 'warns when the secret is written in the app file' do
    secret = SecureRandom.hex(32)
    app_file = write('app/app.rb', app_file_setting_secret('SessionSecretFileApp', secret))
    err = boot_app_file('SessionSecretFileApp', app_file)
    assert_includes err, 'The session secret appears in app/app.rb.'
    refute_includes err, secret
  end

  it 'skips a file it cannot read' do
    app_file = write('app/app.rb', app_file_setting_secret('SessionSecretFileApp', SecureRandom.hex(32)))
    binread = File.method(:binread)
    unreadable = lambda do |path, *args|
      raise Errno::EACCES, path if path == app_file

      binread.call(path, *args)
    end
    err = File.stub(:binread, unreadable) { boot_app_file('SessionSecretFileApp', app_file) }
    assert_empty err
  end

  it 'names an app file outside the project by its absolute path' do
    @outside = Dir.mktmpdir
    app_file = write('app.rb', app_file_setting_secret('SessionSecretOutsideApp', SecureRandom.hex(32)), @outside)
    err = boot_app_file('SessionSecretOutsideApp', app_file)
    assert_includes err, "The session secret appears in #{app_file}."
  end

  it 'skips a mounted Rack app that has no sessions setting' do
    rack_file = write('rack/app.rb', "# SessionSecretRackApp is defined by the test\n")
    Padrino.stub(:root, project_root) do
      Padrino.mount('SessionSecretRackApp', app_file: rack_file).to('/rack')
    end
    err = boot
    assert_equal 1, err.scan('The session secret appears').size
  end

  it 'warns once for several mounted apps and later builds' do
    err = boot(apps: [SessionSecretApp, SessionSecretApp2])
    assert_equal 1, err.scan('The session secret appears').size
    assert_empty build
  end

  it 'warns again after Padrino.clear! and a new boot' do
    refute_empty boot
    Padrino.clear!
    refute_empty boot
  end
end
