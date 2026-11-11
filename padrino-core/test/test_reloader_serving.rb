require_relative 'helper'

require_relative 'fixtures/apps/serving/app'
require_relative 'fixtures/apps/serving/steady'

# A minimal fiber scheduler, so that one thread serves several requests at once, as Falcon does.
# It resumes the thread's fibers in turn, each when what it waits for (a Mutex, ConditionVariable
# or Queue) wakes it, from any thread. Ruby only resumes them from #run_until.
class ServingFiberScheduler
  def initialize
    @ready = Thread::Queue.new
    @sleeping = {}
  end

  def fiber(&block)
    fiber = Fiber.new(blocking: false, &block)
    fiber.resume
    fiber
  end

  def block(_blocker, timeout = nil)
    wake_after(timeout)
    Fiber.yield
  end

  def unblock(_blocker, fiber)
    @ready << fiber
  end

  # Where a fiber waits on a ConditionVariable, as at Padrino::Reloader's gate.
  def kernel_sleep(duration = nil)
    wake_after(duration)
    @sleeping[Fiber.current] = true
    Fiber.yield
  ensure
    @sleeping.delete(Fiber.current)
  end

  def io_wait(*)
    raise NotImplementedError
  end

  def close; end

  def sleeping?(fiber)
    @sleeping.key?(fiber)
  end

  # Resumes the fibers as they wake, until the block returns true.
  def run_until
    until yield
      fiber = @ready.pop
      fiber.resume if fiber.alive?
    end
  end

  private

  def wake_after(timeout)
    fiber = Fiber.current
    return unless timeout

    Thread.new do
      sleep(timeout)
      @ready << fiber
    end
  end
end

describe 'Reloader while serving' do
  # Raised into a request to interrupt it, as Timeout does.
  class ServingInterrupt < StandardError; end

  before do
    @max_wait = Padrino::Reloader.max_wait
    @log_config = Padrino::Logger::Config[:test]
    @log = StringIO.new
    Padrino::Logger::Config[:test] = { log_level: :warn, stream: @log }
    Padrino::Logger.setup!
    Padrino.clear!
    steady = File.expand_path('fixtures/apps/serving/steady.rb', __dir__)
    Padrino.mount('serving_steady_demo', app_file: steady).to('/steady')
    Padrino.mount('serving_sinatra_demo', app_file: steady).to('/sinatra')
    Padrino.mount('serving_other_demo').to('/other')
    Padrino.mount('serving_third_demo').to('/third')
    Padrino.mount('serving_demo').to('/')
    Padrino.reload!
    @app = Padrino.application
  end

  after do
    ServingDemo.on_hold = nil
    Padrino.clear!
    Padrino::Reloader.max_wait = @max_wait
    Padrino::Logger::Config[:test] = @log_config
    Padrino::Logger.setup!

    # A test that failed with a turn taken mustn't hold up the next ones. Its threads may still
    # be giving their turns back.
    gate = { :@readers => 0, :@writers_waiting => 0, :@writing => false }
    read_gate = -> { gate.to_h { |name, _| [name, Padrino::Reloader.instance_variable_get(name)] } }
    deadline = Time.now + 2
    sleep 0.01 until (left = read_gate.call) == gate || Time.now > deadline
    gate.each { |name, value| Padrino::Reloader.instance_variable_set(name, value) }
    turns = Thread.current.thread_variables.grep(/\Apadrino_reloader_/)
    taken = turns.select { |name| Thread.current.thread_variable_get(name) }
    turns.each { |name| Thread.current.thread_variable_set(name, nil) }
    assert_equal gate, left, 'a turn was left taken at the gate'
    assert_empty taken, 'a turn was left taken by the test thread'
  end

  def request(path)
    response = Rack::MockRequest.new(@app).get(path)
    [response.status, response.body]
  end

  # Makes the next Padrino.reload! reload the fixture's apps.
  def change_apps!
    Padrino::Reloader::MTIMES[ServingDemo.app_file] = Time.at(0)
  end

  # Makes /hold signal entered, then wait until release is pushed and answer 'held'.
  def hold_requests(entered, release)
    ServingDemo.on_hold = lambda do
      entered << true
      release.pop
      'held'
    end
  end

  def count_reloads
    reloads = Queue.new
    Padrino.before_load { reloads << true }
    reloads
  end

  def warnings
    @log.string.lines.grep(/max_wait/)
  end

  # Pops from the queue that the thread fills, failing if the thread ends first.
  def pop_from(queue, thread)
    deadline = Time.now + 5
    while queue.empty?
      flunk 'thread ended without a result' if thread.join(0.01) && queue.empty?
      flunk 'timed out waiting for the thread' if Time.now > deadline
    end
    queue.pop
  end

  # Waits until the thread ends or waits at Padrino::Reloader's gate.
  def wait_for_turn(thread)
    deadline = Time.now + 5
    Thread.pass until !thread.alive? || waiting_for_turn?(thread) || Time.now > deadline
  end

  # True while the thread sleeps at Padrino::Reloader's gate: the gate's methods are among its
  # innermost frames, above only the mutex, the condition variable and the interrupt mask.
  def waiting_for_turn?(thread)
    thread.status == 'sleep' && thread.backtrace_locations.to_a.first(6).any? do |location|
      %w[serve take_serving_turn give_serving_turn wait_for_exclusive_turn].include?(location.base_label)
    end
  end

  # Returns the threads' values, failing if one doesn't finish in time.
  def values_of(*threads, within: 5)
    threads.map do |thread|
      unless thread.join(within)
        thread.kill
        flunk 'thread did not finish'
      end
      thread.value
    end
  end

  # Runs the block with the reload of ServingDemo pausing once its routes are reset, until
  # release is pushed; then it calls resumed, if given.
  def pause_reload_after_reset(entered, release, resumed = nil, &block)
    reset_router = ServingDemo.method(:reset_router!)
    paused = lambda do
      reset_router.call
      entered << true
      release.pop
      resumed&.call
    end
    ServingDemo.stub(:reset_router!, paused, &block)
  end

  it 'answers every request while the code reloads over and over' do
    Padrino::Reloader.max_wait = 10
    # Two clients of ServingDemo, so that one can come in while the other reloads the code.
    expected = [%w[/ served], %w[/ served], %w[/other other], %w[/steady steady], %w[/sinatra sinatra]]
    answered = Queue.new
    # The requests each client has started and finished, written by that client only.
    counts = expected.map { [0, 0] }
    done = false
    clients = expected.each_with_index.map do |(path, body), index|
      Thread.new do
        failures = []
        until done
          counts[index][0] += 1
          answer = request(path)
          counts[index][1] += 1
          failures << "#{path}: #{answer[0]} #{answer[1][0, 80]}" unless answer == [200, body]
          answered << index
          # Lets the reloading thread run between requests, as a server's I/O would.
          Thread.pass
        end
        failures
      end
    end

    # Each reload pauses once ServingDemo's routes are reset, until a client of ServingDemo
    # comes in: it waits for the reload, or (without the gate) runs in the middle of it.
    resets = overlaps = 0
    reset_router = ServingDemo.method(:reset_router!)
    paused = lambda do
      reset_router.call
      resets += 1
      index = clients.index { |client| client != Thread.current }
      count = counts[index]
      started = count[0]
      deadline = Time.now + 5
      Thread.pass until (came_in = waiting_for_turn?(clients[index]) || (count[0] > started && count[1] >= count[0])) ||
                        Time.now > deadline
      overlaps += 1 if came_in
    end
    ServingDemo.stub(:reset_router!, paused) do
      # An edit made while a client's reload runs can be reloaded with it.
      until resets >= 10
        # Every client is serving requests when the code changes.
        seen = Set.new
        seen << pop_from(answered, clients.first) until seen.size == expected.size
        change_apps!
        Padrino.reload!
      end
    ensure
      done = true
    end
    assert_empty values_of(*clients).flatten
    assert_equal resets, overlaps, 'no request came in during a reload'
    assert_empty warnings
  end

  it 'waits for the requests in progress before a request reloads the code' do
    Padrino::Reloader.max_wait = 10
    entered = Queue.new
    release = Queue.new
    hold_requests(entered, release)
    reloads = count_reloads

    begin
      holder = Thread.new { request('/hold') }
      pop_from(entered, holder)
      change_apps!
      # The other app's first request checks for changes and reloads them.
      reloader = Thread.new { request('/other') }
      wait_for_turn(reloader)
      assert_equal 0, reloads.size, 'the code reloaded while a request was in progress'
      assert waiting_for_turn?(reloader), 'the reload did not wait for the request in progress'
    ensure
      release << true
    end

    assert_equal [[200, 'held'], [200, 'other']], values_of(holder, reloader)
    assert_equal 1, reloads.size
    assert_empty warnings
  end

  it 'reloads anyway, and logs it, when a request in progress holds it up past max_wait' do
    Padrino::Reloader.max_wait = 0.2
    entered = Queue.new
    release = Queue.new
    hold_requests(entered, release)
    reloads = count_reloads

    begin
      # A request paused in a debugger, say.
      holder = Thread.new { request('/hold') }
      pop_from(entered, holder)
      change_apps!
      assert_equal [[200, 'other']], values_of(Thread.new { request('/other') })
      assert_equal 1, reloads.size
      assert_equal 1, warnings.size
      assert_match(/after waiting 0.2s .*; 1 still running/, warnings.first)
      assert_equal [200, 'served'], request('/')
    ensure
      release << true
    end

    assert_equal [[200, 'held']], values_of(holder)
  end

  it 'holds the requests that arrive while a reload waits, until it finishes' do
    Padrino::Reloader.max_wait = 10
    entered = Queue.new
    release = Queue.new
    reloaded = Queue.new
    Padrino.after_load { reloaded << true }
    calls = 0
    ServingDemo.on_hold = lambda do
      next "reloads: #{reloaded.size}" unless (calls += 1) == 1

      entered << true
      release.pop
      'held'
    end
    reloader = newcomer = nil

    begin
      holder = Thread.new { request('/hold') }
      pop_from(entered, holder)
      change_apps!
      reloader = Thread.new { Padrino.reload! }
      wait_for_turn(reloader)
      assert waiting_for_turn?(reloader), 'the reload did not wait for the request in progress'
      # To an app that doesn't reload, so only the gate can hold it.
      newcomer = Thread.new { request('/steady/hold') }
      wait_for_turn(newcomer)
      assert waiting_for_turn?(newcomer), 'a new request went ahead of the waiting reload'
    ensure
      release << true
    end

    assert_equal [[200, 'held'], [200, 'reloads: 1']], values_of(holder, newcomer)
    values_of(reloader)
    assert_empty warnings
  end

  it 'holds a request whose reload was skipped while a newer reload runs' do
    Padrino::Reloader.max_wait = 10
    entered = Queue.new
    release = Queue.new
    hold_requests(entered, release)
    reloads = count_reloads
    reloader = Padrino::Reloader
    change_gate = lambda do |changes|
      reloader.instance_variable_get(:@gate).synchronize do
        changes.each { |name, value| reloader.instance_variable_set(name, value) }
        reloader.instance_variable_get(:@gate_changed).broadcast
      end
    end

    begin
      holder = Thread.new { request('/hold') }
      pop_from(entered, holder)
      change_apps!
      # The other app's first request sees the changes, and its reload waits for the holder.
      skipped = Thread.new { request('/other') }
      wait_for_turn(skipped)
      assert waiting_for_turn?(skipped), 'the reload did not wait for the request in progress'

      # Meanwhile, as far as the waiting reload can tell, another reload has reloaded the changes,
      # and a newer one has started.
      change_gate.call(:@generation => reloader.instance_variable_get(:@generation) + 1, :@writing => true)
      refute skipped.join(0.5), 'the request ran during the newer reload'
      assert waiting_for_turn?(skipped), 'the request did not wait for the newer reload'

      change_gate.call(:@writing => false)
      assert_equal [[200, 'other']], values_of(skipped)
      assert_equal 0, reloads.size
    ensure
      release << true
    end

    assert_equal [[200, 'held']], values_of(holder)
    assert_empty warnings
  end

  [nil, Float::INFINITY].each do |max_wait|
    it "waits as long as the requests in progress take with max_wait #{max_wait.inspect}" do
      Padrino::Reloader.max_wait = max_wait
      entered = Queue.new
      release = Queue.new
      hold_requests(entered, release)
      reloads = count_reloads
      reloader = nil

      begin
        holder = Thread.new { request('/hold') }
        pop_from(entered, holder)
        change_apps!
        reloader = Thread.new { Padrino.reload! }
        wait_for_turn(reloader)
        assert waiting_for_turn?(reloader), 'the reload did not wait for the request in progress'
        assert_equal 0, reloads.size, 'the code reloaded while a request was in progress'
      ensure
        release << true
      end

      assert_equal [[200, 'held']], values_of(holder)
      values_of(reloader)
      assert_equal 1, reloads.size
      assert_empty warnings
    end
  end

  it 'refuses a max_wait that is not a number of seconds' do
    ['3', :forever, Complex(1, 1), Float::NAN].each do |max_wait|
      assert_raises(ArgumentError) { Padrino::Reloader.max_wait = max_wait }
    end
    assert_equal @max_wait, Padrino::Reloader.max_wait
  end

  it 'serves a request that calls its own server while the code changes' do
    Padrino::Reloader.max_wait = 0.2
    ServingDemo.on_hold = lambda do
      change_apps!
      # Served by another thread, as a request to the server over HTTP would be. Its app's
      # first request reloads the changes, so it waits for the request that called it.
      Thread.new { request('/other') }.value.last
    end

    assert_equal [[200, 'other']], values_of(Thread.new { request('/hold') })
    assert_equal 1, warnings.size
  end

  it 'serves a call nested in a request from another fiber while a reload waits' do
    Padrino::Reloader.max_wait = 10
    entered = Queue.new
    release = Queue.new
    ServingDemo.on_hold = lambda do
      entered << true
      release.pop
      Fiber.new { request('/') }.resume.last
    end
    holder = reloader = nil

    begin
      holder = Thread.new { request('/hold') }
      pop_from(entered, holder)
      change_apps!
      reloader = Thread.new { Padrino.reload! }
      wait_for_turn(reloader)
      assert waiting_for_turn?(reloader), 'the reload did not wait for the request in progress'
    ensure
      release << true
    end

    assert_equal [[200, 'served']], values_of(holder)
    values_of(reloader)
    assert_empty warnings
  end

  it 'holds the other fibers of a thread whose reload waits for the requests in progress' do
    skip 'needs a fiber scheduler that CRuby runs Mutex waits through' unless RUBY_ENGINE == 'ruby' && Fiber.respond_to?(:set_scheduler)

    Padrino::Reloader.max_wait = 10
    entered = Queue.new
    release = Queue.new
    hold_requests(entered, release)
    reloads = count_reloads
    scheduler = ServingFiberScheduler.new
    seen = Queue.new
    answers = Queue.new
    fibers = nil

    begin
      holder = Thread.new { request('/hold') }
      pop_from(entered, holder)
      change_apps!
      # One thread serving several requests: one of them reloads, then two more arrive.
      server = Thread.new do
        Fiber.set_scheduler(scheduler)
        first = Fiber.schedule { Padrino.reload! }
        scheduler.run_until { scheduler.sleeping?(first) }
        fibers = [first, Fiber.schedule { Padrino.reload! }, Fiber.schedule { answers << request('/') }]
        scheduler.run_until { fibers.all? { |fiber| !fiber.alive? || scheduler.sleeping?(fiber) } }
        seen << reloads.size
        scheduler.run_until { fibers.none?(&:alive?) }
      ensure
        Fiber.set_scheduler(nil)
      end
      assert_equal 0, pop_from(seen, server), 'the code reloaded while a request was in progress'
    ensure
      release << true
    end

    assert_equal [[200, 'held']], values_of(holder)
    values_of(server)
    assert_equal 1, reloads.size
    assert_equal [200, 'served'], answers.pop
    assert_empty warnings
  end

  it 'reloads the changes once when two requests see them while reloading is disabled' do
    enabled = Padrino::Reloader.instance_variable_get(:@enabled)
    Padrino::Reloader.max_wait = 10
    entered = Queue.new
    release = Queue.new
    reloads = count_reloads
    Padrino.before_load do
      entered << true
      release.pop
    end
    clients = []

    begin
      # As in development with Padrino::Reloader.enabled = false: the apps still set :reload.
      Padrino::Reloader.enabled = false
      @app = Padrino.application
      change_apps!
      clients << Thread.new { request('/other') }
      pop_from(entered, clients.first)
      # The second request comes in while the first one reloads the changes.
      clients << Thread.new { request('/other') }
      wait_for_turn(clients.last)
      assert_equal 1, reloads.size, 'two reloads ran at once'
      assert waiting_for_turn?(clients.last), 'the request did not wait for the reload'
    ensure
      clients.size.times { release << true }
      Padrino::Reloader.enabled = enabled
    end

    assert_equal [[200, 'other']] * 2, values_of(*clients)
    assert_equal 1, reloads.size
    assert_empty warnings
  end

  it 'counts a dependency outside Padrino.root as changed only once it is edited' do
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'serving_outside.rb')
      File.write(file, "module ServingOutside; end\n")
      Padrino.dependency_paths << File.join(dir, '*.rb')
      Padrino.require_dependencies(file)
      refute Padrino::Reloader.changed?, 'the dependency counts as changed after loading it'

      File.utime(Time.now + 10, Time.now + 10, file)
      assert Padrino::Reloader.changed?, 'an edit of the dependency went unnoticed'
      Padrino.reload!
      refute Padrino::Reloader.changed?, 'the dependency counts as changed after reloading'
    ensure
      Object.send(:remove_const, :ServingOutside) if defined?(ServingOutside)
      $LOADED_FEATURES.delete(File.realpath(file)) if File.exist?(file)
      $LOADED_FEATURES.delete(file)
    end
  end

  it 'gives the turn back when a request is interrupted as it does' do
    Padrino::Reloader.max_wait = 10
    entered = Queue.new
    release = Queue.new
    hold_requests(entered, release)
    holder = Thread.new do
      request('/hold')
    rescue ServingInterrupt => e
      e
    end
    pop_from(entered, holder)

    # The request ends while the gate is busy, then is interrupted as it waits to give its turn back.
    Padrino::Reloader.instance_variable_get(:@gate).synchronize do
      release << true
      wait_for_turn(holder)
      assert waiting_for_turn?(holder), 'the request did not wait to give its turn back'
      holder.raise(ServingInterrupt)
    end
    assert_kind_of ServingInterrupt, values_of(holder).first

    change_apps!
    values_of(Thread.new { Padrino.reload! })
    assert_empty warnings
  end

  %w[steady sinatra].each do |app|
    it "waits for the requests in progress to an app that doesn't reload (#{app})" do
      Padrino::Reloader.max_wait = 10
      entered = Queue.new
      release = Queue.new
      hold_requests(entered, release)
      reloads = count_reloads

      begin
        holder = Thread.new { request("/#{app}/hold") }
        pop_from(entered, holder)
        change_apps!
        reloader = Thread.new { request('/other') }
        wait_for_turn(reloader)
        assert_equal 0, reloads.size, 'the code reloaded while a request was in progress'
        assert waiting_for_turn?(reloader), 'the reload did not wait for the request in progress'
      ensure
        release << true
      end

      assert_equal [[200, 'held'], [200, 'other']], values_of(holder, reloader)
      assert_equal 1, reloads.size
    end
  end

  it 'reloads the changes once when several requests see them' do
    Padrino::Reloader.max_wait = 10
    entered = Queue.new
    release = Queue.new
    hold_requests(entered, release)
    reloads = count_reloads
    holders = []

    begin
      # A request in progress keeps both reloads waiting.
      holders << Thread.new { request('/hold') }
      pop_from(entered, holders.first)
      change_apps!
      # Each app's first request checks for changes, sees them and reloads them.
      holders << Thread.new { request('/other/hold') } << Thread.new { request('/third/hold') }
      holders.drop(1).each { |holder| wait_for_turn(holder) }
      assert holders.drop(1).all? { |holder| waiting_for_turn?(holder) }, 'a reload did not wait'
      release << true

      # Once one has reloaded the changes, neither waits for the other.
      holders.drop(1).each { |holder| pop_from(entered, holder) }
      assert_equal 1, reloads.size
      assert_equal [200, 'served'], request('/')
    ensure
      holders.size.times { release << true }
    end

    assert_equal [[200, 'held']] * 3, values_of(*holders)
    assert_empty warnings
  end

  it 'holds the requests that arrive during a reload until it finishes' do
    entered = Queue.new
    release = Queue.new
    reloader = waiting = nil
    change_apps!

    pause_reload_after_reset(entered, release) do
      reloader = Thread.new { Padrino.reload! }
      pop_from(entered, reloader)
      waiting = Thread.new { request('/') }
      wait_for_turn(waiting)
      assert waiting_for_turn?(waiting), 'a request ran during the reload'
    ensure
      release << true
      values_of(reloader) if reloader
    end

    assert_equal [[200, 'served']], values_of(waiting)
  end

  it 'lets the waiting requests through when the reload raises' do
    entered = Queue.new
    release = Queue.new
    reloader = waiting = nil
    change_apps!

    pause_reload_after_reset(entered, release, -> { raise 'boom' }) do
      reloader = Thread.new do
        Padrino.reload!
      rescue RuntimeError => e
        e
      end
      pop_from(entered, reloader)
      waiting = Thread.new { request('/') }
      wait_for_turn(waiting)
      assert waiting_for_turn?(waiting), 'a request ran during the reload'
    ensure
      release << true
      values_of(reloader) if reloader
    end

    assert_equal 'boom', reloader.value.message
    values_of(waiting)

    # Requests and reloads still take turns once the error is fixed.
    change_apps!
    Padrino.reload!
    assert_equal [200, 'served'], request('/')
  end

  it 'takes no turns while reloading is disabled and no app reloads, as in production' do
    enabled = Padrino::Reloader.instance_variable_get(:@enabled)
    Padrino::Reloader.enabled = false
    Padrino.clear!
    steady = File.expand_path('fixtures/apps/serving/steady.rb', __dir__)
    Padrino.mount('serving_sinatra_demo', app_file: steady).to('/sinatra')
    Padrino.mount('serving_steady_demo', app_file: steady).to('/')
    @app = Padrino.application
    Padrino::Reloader::MTIMES[steady] = Time.at(0)

    Padrino::Reloader.stub(:serve, ->(*) { flunk 'the request took a turn' }) do
      Padrino::Reloader.stub(:exclusively, ->(*) { flunk 'the request reloaded the code' }) do
        assert_equal [200, 'steady'], request('/')
        assert_equal [200, 'sinatra'], request('/sinatra')
      end
    end
  ensure
    Padrino::Reloader.enabled = enabled
  end
end
