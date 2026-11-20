require 'minitest/autorun'
require 'minitest/pride'
require 'open3'
require 'rbconfig'
require 'tmpdir'
require_relative 'helper'

describe 'padrino-performance suites' do
  BIN = File.expand_path('../bin/padrino-performance', __dir__)

  def run_with_suites(*flags)
    Dir.mktmpdir do |dir|
      script = File.join(dir, 'boot.rb')
      File.write(script, <<~RUBY)
        require 'bundler/setup'
        PADRINO_ROOT = #{dir.dump}
        require 'padrino-core'
        Padrino.load!
        puts "json suite loaded: \#{!!defined?(Padrino::Performance::JSON::InfectedRequire)}"
      RUBY
      Open3.capture2e(RbConfig.ruby, BIN, *flags, '--', script)
    end
  end

  it 'prints the memory usage around Padrino.load! with --mem' do
    output, status = run_with_suites('-m')
    assert status.success?, output
    assert_match(/^Memory before the application is loaded: /, output)
    assert_match(/^Memory usage after loading the application: /, output)
    refute_match(/application[^\n]*: (pmap|vmmap|tasklist) /, output)
  end

  it 'loads every suite given at once' do
    output, status = run_with_suites('-m', '-j')
    assert status.success?, output
    assert_match(/^Memory before the application is loaded: /, output)
    assert_match(/^json suite loaded: true$/, output)
  end
end
