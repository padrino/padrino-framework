require 'minitest/benchmark'

# Times each input size several times and keeps the fastest run, so one GC
# pause or scheduler hiccup does not bend the fit that assert_performance_linear checks.
module BestOfRuns
  RUNS = 3

  def assert_performance(validation, &work)
    range = self.class.bench_range
    io.print name
    times = range.map do |x|
      best = Array.new(RUNS) do
        GC.start
        t0 = Minitest.clock_time
        instance_exec(x, &work)
        Minitest.clock_time - t0
      end.min
      io.print format("\t%9.6f", best)
      best
    end
    io.puts
    validation[range, times]
  end
end
