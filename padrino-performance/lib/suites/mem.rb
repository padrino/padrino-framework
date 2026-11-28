require 'English'
require_relative '../padrino-performance/os'

module Padrino
  class << self
    def before_load(&block)
      @_before_load ||= []
      @_before_load << block if block_given?
      @_before_load
    end

    def after_load(&block)
      @_after_load ||= []
      @_after_load << block if block_given?
      @_after_load
    end

    def perf_memusage_command
      if Performance::OS.mac?
        "vmmap #{$PROCESS_ID} | tail -5"
      elsif Performance::OS.linux?
        "pmap #{$PROCESS_ID} | tail -1"
      elsif Performance::OS.windows?
        "tasklist /FI \"PID eq #{$PROCESS_ID}\""
      end
    end

    def perf_memusage
      command = perf_memusage_command
      command ? `#{command}`.strip : 'unknown on this system'
    end
  end

  before_load do
    puts "Memory before the application is loaded: #{perf_memusage}"
  end

  after_load do
    puts "Memory usage after loading the application: #{perf_memusage}"
  end
end
