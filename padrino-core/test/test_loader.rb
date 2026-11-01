require_relative 'helper'

describe 'Padrino loaded state' do
  # load! adds constants to the reloader's exclusions and records its caller; clear! resets neither.
  before do
    @excluded_constants = Padrino::Reloader.exclude_constants.dup
    @called_from = Padrino.instance_variable_get(:@_called_from)
    Padrino.clear!
  end

  after do
    Padrino.clear!
    Padrino::Reloader.exclude_constants.replace(@excluded_constants)
    Padrino.instance_variable_set(:@_called_from, @called_from)
  end

  # Runs the block in a new thread and returns its value, raising the thread's error if it raised.
  def in_thread(&block)
    thread = Thread.new(&block)
    unless thread.join(5)
      thread.kill
      flunk 'thread did not finish'
    end
    thread.value
  end

  # Pops from the queue that the thread fills, raising the thread's error if it dies first.
  def pop_from(queue, thread)
    deadline = Time.now + 5
    while queue.empty?
      flunk 'thread ended without a result' if thread.join(0.01) && queue.empty?
      flunk 'timed out waiting for the thread' if Time.now > deadline
    end
    queue.pop
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

    begin
      first = Thread.new { Padrino.load! }
      pop_from(entered, first)
      second = Thread.new { Padrino.load! }
      deadline = Time.now + 5
      Thread.pass until second.status == 'sleep' || !second.alive? || Time.now > deadline
      assert_equal 'sleep', second.status, 'the second load! did not wait'
      assert_empty entered, 'the second load! ran the load hooks'
    ensure
      2.times { release << true }
      threads = [first, second].compact
      threads.each { |thread| thread.kill unless thread.join(5) }
    end

    assert_equal 1, before_calls
    assert_equal 1, after_calls
    assert first.value
    refute second.value
    assert Padrino.loaded?
  end

  it 'runs the load in a waiting thread when the first load raised' do
    calls = 0
    entered = Queue.new
    release = Queue.new
    Padrino.before_load do
      calls += 1
      next unless calls == 1
      entered << true
      release.pop
      raise 'boom'
    end

    begin
      first = Thread.new do
        Padrino.load!
      rescue RuntimeError => e
        e
      end
      pop_from(entered, first)
      second = Thread.new { Padrino.load! }
      deadline = Time.now + 5
      Thread.pass until second.status == 'sleep' || !second.alive? || Time.now > deadline
      assert_equal 'sleep', second.status, 'the second load! did not wait'
    ensure
      release << true
      threads = [first, second].compact
      threads.each { |thread| thread.kill unless thread.join(5) }
    end

    assert_instance_of RuntimeError, first.value
    assert second.value
    assert_equal 2, calls
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

  it 'returns false from a load! called in another fiber of the loading thread' do
    calls = 0
    nested = nil
    Padrino.before_load do
      calls += 1
      nested = Fiber.new { Padrino.load! }.resume if calls == 1
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
    assert Padrino.load!
    assert_equal 2, calls
  end

  it 'keeps the loaded state when Loader is extended again' do
    Padrino.load!
    Padrino.extend(Padrino::Loader)
    assert Padrino.loaded?
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
    assert pop_from(results, worker)

    Padrino.clear!
    jobs << -> { Padrino.loaded? }
    refute pop_from(results, worker)
    refute Padrino.loaded?
  ensure
    worker&.kill
  end

  it 'waits for a load in progress before clear! resets it' do
    entered = Queue.new
    release = Queue.new
    Padrino.before_load do
      entered << true
      release.pop
    end

    begin
      loader = Thread.new { Padrino.load! }
      pop_from(entered, loader)
      clearer = Thread.new { Padrino.clear! }
      deadline = Time.now + 5
      Thread.pass until clearer.status == 'sleep' || !clearer.alive? || Time.now > deadline
      assert_equal 'sleep', clearer.status, 'clear! did not wait for the load'
    ensure
      release << true
      threads = [loader, clearer].compact
      threads.each { |thread| thread.kill unless thread.join(5) }
    end

    assert loader.value
    refute Padrino.loaded?
  end
end
