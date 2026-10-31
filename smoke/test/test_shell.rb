require_relative 'helper'
require 'tmpdir'

describe 'Smoke::Shell' do
  let(:dir) { Dir.pwd }

  def ruby(code)
    [Gem.ruby, '-e', code]
  end

  it 'returns the output of a command that succeeds' do
    assert_equal '42', Smoke::Shell.run('print', ruby('print 42'), chdir: dir)
  end

  it 'raises StepFailed naming the step, command and output when a command fails' do
    error = assert_raises(Smoke::StepFailed) { Smoke::Shell.run('broken', ruby('puts "boom"; exit 3'), chdir: dir) }
    assert_includes error.message, 'broken'
    assert_includes error.message, 'exit 3'
    assert_includes error.message, 'boom'
    assert_includes error.message, dir
  end

  it 'passes an expected failure and rejects an unexpected success' do
    assert_equal 'no', Smoke::Shell.run('fail', ruby('print "no"; exit 1'), chdir: dir, expect: :failure)
    error = assert_raises(Smoke::StepFailed) { Smoke::Shell.run('fail', ruby('exit 0'), chdir: dir, expect: :failure) }
    assert_includes error.message, 'expected failure'
  end

  it 'feeds input on stdin' do
    assert_equal "a\nb\n", Smoke::Shell.run('stdin', ruby('print $stdin.read'), chdir: dir, input: "a\nb\n")
  end

  it 'passes env to the command' do
    assert_equal 'x', Smoke::Shell.run('env', ruby('print ENV["SMOKE_X"]'), chdir: dir, env: { 'SMOKE_X' => 'x' })
  end

  it 'does not leak the caller bundle into the command' do
    out = Smoke::Shell.run('env', ruby('print ENV["BUNDLE_GEMFILE"].inspect, "|", ENV["RUBYOPT"].to_s'), chdir: dir)
    assert_equal 'nil', out.split('|').first
    refute_includes out, 'bundler/setup'
  end

  it 'spawns a background process that logs to a file' do
    Dir.mktmpdir do |tmp|
      pid = Smoke::Shell.spawn(ruby('puts "up"'), chdir: tmp)
      Process.wait(pid)
      assert_includes File.read(File.join(tmp, 'log/smoke-server.log')), 'up'
    end
  end
end
