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

require 'smoke/combination'
