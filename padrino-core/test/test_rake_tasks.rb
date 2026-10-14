require_relative 'helper'
require 'open3'
require 'tmpdir'

describe 'PadrinoTasks' do
  def run_init(*task_bodies)
    Dir.mktmpdir do |dir|
      files = task_bodies.each_with_index.map do |body, index|
        path = File.join(dir, "task_#{index}.rb")
        File.write(path, body)
        path
      end
      script = <<~RUBY
        require 'padrino-core/cli/rake'
        Padrino::Tasks.files.concat(#{files.inspect})
        PadrinoTasks.init
        puts "TASKS \#{Rake::Task.tasks.map(&:name).grep(/\\Ademo_/).inspect}"
      RUBY
      lib = File.expand_path('../lib', __dir__)
      Open3.capture3(RbConfig.ruby, '-I', lib, '-e', script)
    end
  end

  it 'should load every registered task file' do
    out, err, status = run_init('task :demo_one', 'task :demo_two')
    assert status.success?, err
    assert_includes out.lines.map(&:strip), "TASKS #{%w[demo_one demo_two].inspect}"
  end

  it 'should raise the error of a task file that fails to load' do
    out, err, status = run_init('task :demo_one', 'raise "broken task file"')
    refute status.success?
    refute_match(/^TASKS/, out)
    assert_match(/broken task file/, err)
    refute_match(/Failed load/, err + out)
  end
end
