require 'pathname'

# Generates real Padrino projects and checks that they bundle, migrate, render, test and boot.
module Smoke
  ROOT = Pathname.new(File.expand_path('..', __dir__))
  CHECKOUT = ROOT.parent

  # A command in a smoke step failed, or succeeded when it should have failed.
  class StepFailed < StandardError
    attr_reader :step, :cmd, :chdir, :status, :output

    def initialize(step, cmd, chdir, status, output)
      @step = step
      @cmd = cmd
      @chdir = chdir
      @status = status
      @output = output
      super("step #{step} failed: #{Array(cmd).join(' ')}\n  in #{chdir}\n  #{status}\n#{output}")
    end
  end
end

$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)
require 'smoke/combination'
require 'smoke/shell'
require 'smoke/project'
require 'smoke/runner'
