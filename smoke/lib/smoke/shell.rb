require 'bundler'
require 'fileutils'
require 'open3'

module Smoke
  # Runs commands for a generated project outside the checkout's bundle.
  module Shell
    module_function

    def run(step, cmd, chdir:, env: {}, input: nil, expect: :success)
      output, status = Bundler.with_unbundled_env do
        Open3.capture2e(env, *cmd, chdir: chdir, stdin_data: input.to_s)
      end
      return output if status.success? == (expect == :success)

      described = expect == :success ? status.to_s : "expected failure, got #{status}"
      raise StepFailed.new(step, cmd, chdir, described, output)
    end

    def spawn(cmd, chdir:, env: {})
      log = File.join(chdir, 'log/smoke-server.log')
      FileUtils.mkdir_p(File.dirname(log))
      Bundler.with_unbundled_env do
        Process.spawn(env, *cmd, chdir: chdir, in: File::NULL, %i[out err] => [log, 'w'])
      end
    end
  end
end
