require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'Padrino::Colorizer' do
  it 'should colorize text correctly' do
    assert_equal "\e[0;9mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :default)
    assert_equal "\e[0;30mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :black)
    assert_equal "\e[0;31mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :red)
    assert_equal "\e[0;32mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :green)
    assert_equal "\e[0;33mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :yellow)
    assert_equal "\e[0;34mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :blue)
    assert_equal "\e[0;35mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :magenta)
    assert_equal "\e[0;36mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :cyan)
    assert_equal "\e[0;37mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :white)
  end

  it 'should be possible to set the mode' do
    assert_equal "\e[1;34mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :blue, :bold)
    assert_equal "\e[0;34mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :blue, :default)
  end

  it 'should use the default mode for nil or an unknown mode' do
    assert_equal "\e[0;31mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :red, nil)
    assert_equal "\e[0;31mHello world\e[0m", Padrino::Colorizer.colorize('Hello world', :red, :blink)
  end

  it 'should accept a color given as a String' do
    assert_equal "\e[0;31mx\e[0m", Padrino::Colorizer.colorize('x', 'red')
  end

  it 'should raise for an unknown color' do
    assert_raises(KeyError) { Padrino::Colorizer.colorize('Hello world', :purple) }
  end

  it 'should accept a frozen string and keep its encoding' do
    text = 'héllo'.freeze
    result = Padrino::Colorizer.colorize(text, :green)
    assert_equal "\e[0;32mhéllo\e[0m", result
    assert_equal Encoding::UTF_8, result.encoding
    assert_equal 'héllo', text
  end
end

describe 'String#colorize' do
  def deprecation
    'String#colorize and String::Colorizer are deprecated'
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

  it 'should match Padrino::Colorizer for every color and mode, and warn once naming the first use' do
    out, err = run_script(<<~'RUBY')
      require 'padrino-support'
      same = 'Hi'.colorize(:red) == Padrino::Colorizer.colorize('Hi', :red)
      Padrino::Colorizer::COLORS.each_key do |color|
        same &&= 'Hi'.colorize(color) == Padrino::Colorizer.colorize('Hi', color)
        same &&= String::Colorizer.public_send(color, 'Hi') == Padrino::Colorizer.colorize('Hi', color)
        [*Padrino::Colorizer::MODES.keys, nil].each do |mode|
          same &&= 'Hi'.colorize(color: color, mode: mode) == Padrino::Colorizer.colorize('Hi', color, mode)
          same &&= String::Colorizer.public_send(color, 'Hi', mode) == Padrino::Colorizer.colorize('Hi', color, mode)
        end
      end
      same &&= String::Colorizer.colors == Padrino::Colorizer::COLORS && String::Colorizer.modes == Padrino::Colorizer::MODES
      same &&= 'Hi'.colorize(color: 'red') == Padrino::Colorizer.colorize('Hi', :red)
      print same && 'Hi'.colorize('red').nil?
    RUBY
    assert_equal 'true', out
    assert_equal 1, err.scan(deprecation).size, err
    assert_includes err, 'Padrino 1.0'
    assert_includes err, 'Use Padrino::Colorizer.colorize(text, color, mode) instead (first used at -e:2)'
  end

  it 'should warn once, naming the first use, when String::Colorizer is used first' do
    _out, err = run_script(<<~RUBY)
      require 'padrino-support'
      String::Colorizer.blue('Hi', :bold)
      String::Colorizer.colors
      'Hi'.colorize(:blue)
    RUBY
    assert_equal 1, err.scan(deprecation).size, err
    assert_includes err, '(first used at -e:2)'
  end

  it 'should warn when first used from a thread with no caller' do
    out, err = run_script(<<~'RUBY')
      require 'padrino-support'
      print Thread.new('Hi', &String::Colorizer.method(:red)).value == Padrino::Colorizer.colorize('Hi', :red)
    RUBY
    assert_equal 'true', out
    assert_includes err, deprecation
  end

  it 'should warn while warnings are off, as they are while the reloader loads app files' do
    _out, err = run_script(<<~RUBY)
      require 'padrino-support'
      $VERBOSE = nil
      'Hi'.colorize(:red)
    RUBY
    assert_includes err, deprecation
  end
end
