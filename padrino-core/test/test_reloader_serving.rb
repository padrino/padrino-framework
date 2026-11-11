require_relative 'helper'

require_relative 'fixtures/apps/serving/app'
require_relative 'fixtures/apps/serving/steady'

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
    expected = { '/' => 'served', '/other' => 'other', '/steady' => 'steady', '/sinatra' => 'sinatra' }
    answered = Queue.new
    done = false
    clients = expected.map do |path, body|
      Thread.new do
        failures = []
        until done
          answer = request(path)
          failures << "#{path}: #{answer[0]} #{answer[1][0, 80]}" unless answer == [200, body]
          answered << path
          # Lets the reloading thread run between requests, as a server's I/O would.
          Thread.pass
        end
        failures
      end
    end

    # Gives the clients a chance to run in the middle of each reload.
    reset_router = ServingDemo.method(:reset_router!)
    ServingDemo.stub(:reset_router!, -> { reset_router.call.tap { 10.times { Thread.pass } } }) do
      10.times do
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

  it 'takes no turns while reloading is disabled' do
    enabled = Padrino::Reloader.instance_variable_get(:@enabled)
    Padrino::Reloader.enabled = false
    Padrino.clear!
    Padrino.mount('serving_steady_demo', app_file: File.expand_path('fixtures/apps/serving/steady.rb', __dir__)).to('/')
    @app = Padrino.application

    Padrino::Reloader.stub(:serve, ->(*) { flunk 'the request took a turn' }) do
      assert_equal [200, 'steady'], request('/')
    end
  ensure
    Padrino::Reloader.enabled = enabled
  end
end
