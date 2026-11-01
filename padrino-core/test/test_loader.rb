require_relative 'helper'

describe 'Padrino loaded state' do
  before { Padrino.clear! }
  after { Padrino.clear! }

  def in_thread(&block)
    thread = Thread.new(&block)
    assert thread.join(5), 'thread did not finish'
    thread.value
  end

  it 'is loaded in another thread after load! in this one' do
    Padrino.load!
    assert Padrino.loaded?
    other_loaded = in_thread { Padrino.loaded? }
    other_load = in_thread { Padrino.load! }
    assert other_loaded
    refute other_load
  end

  it 'runs the load hooks once when two threads call load! together' do
    before_calls = 0
    after_calls = 0
    entered = Queue.new
    release = Queue.new
    Padrino.before_load do
      before_calls += 1
      entered << true
      release.pop
    end
    Padrino.after_load { after_calls += 1 }

    first = Thread.new { Padrino.load! }
    entered.pop
    second = Thread.new { Padrino.load! }
    deadline = Time.now + 5
    Thread.pass until second.status == 'sleep' || !second.alive? || Time.now > deadline
    2.times { release << true }

    assert first.join(5) && second.join(5), 'load! did not finish'
    assert_equal 1, before_calls
    assert_equal 1, after_calls
    assert first.value
    refute second.value
    assert Padrino.loaded?
  end

  it 'returns false from a load! called inside a before_load hook' do
    calls = 0
    nested = nil
    Padrino.before_load do
      calls += 1
      nested = Padrino.load! if calls == 1
    end

    outer = in_thread { Padrino.load! }
    assert outer
    refute nested
    assert_equal 1, calls
    assert Padrino.loaded?
  end

  it 'loads again after a load! that raised' do
    calls = 0
    Padrino.before_load do
      calls += 1
      raise 'boom' if calls == 1
    end

    assert_raises(RuntimeError) { Padrino.load! }
    refute Padrino.loaded?
    retried = in_thread { Padrino.load! }
    assert retried
    assert_equal 2, calls
  end

  it 'is not loaded in any thread after clear!' do
    jobs = Queue.new
    results = Queue.new
    worker = Thread.new do
      while (job = jobs.pop)
        results << job.call
      end
    end
    jobs << -> { Padrino.load! }
    assert results.pop

    Padrino.clear!
    jobs << -> { Padrino.loaded? }
    refute results.pop
    refute Padrino.loaded?
  ensure
    jobs << nil
    worker.join(5)
  end
end
