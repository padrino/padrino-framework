require_relative 'helper'

require_relative 'fixtures/apps/serving/app'

describe 'Reloader while serving' do
  before do
    Padrino.clear!
    Padrino.mount('serving_other_demo').to('/other')
    Padrino.mount('serving_demo').to('/')
    Padrino.reload!
    @app = Padrino.application
  end

  after do
    ServingDemo.on_hold = nil
    Padrino.clear!
  end

  def request(path)
    response = Rack::MockRequest.new(@app).get(path)
    [response.status, response.body]
  end

  # Makes the next Padrino.reload! reload the fixture's apps.
  def change_apps!
    Padrino::Reloader::MTIMES[ServingDemo.app_file] = Time.at(0)
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

  # Waits until the thread ends or waits for its turn to serve or reload.
  def wait_for_turn(thread)
    deadline = Time.now + 5
    Thread.pass until !thread.alive? || waiting_for_turn?(thread) || Time.now > deadline
  end

  # True while the thread sleeps at Padrino::Reloader's gate: the gate's methods are among its
  # innermost frames, above only the condition variable's wait.
  def waiting_for_turn?(thread)
    thread.status == 'sleep' && thread.backtrace_locations.to_a.first(4).any? do |location|
      %w[serve wait_for_exclusive_turn].include?(location.base_label)
    end
  end

  # Returns the threads' values, failing if one doesn't finish.
  def values_of(*threads)
    threads.map do |thread|
      unless thread.join(5)
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

  it 'waits for the requests in progress before a request reloads the code' do
    entered = Queue.new
    release = Queue.new
    ServingDemo.on_hold = lambda do
      entered << true
      release.pop
      'held'
    end
    reloads = 0
    Padrino.before_load { reloads += 1 }

    begin
      holder = Thread.new { request('/hold') }
      pop_from(entered, holder)
      change_apps!
      # The other app's first request checks for changes and reloads them.
      reloader = Thread.new { request('/other') }
      wait_for_turn(reloader)
      assert_equal 0, reloads, 'the code reloaded while a request was in progress'
      assert waiting_for_turn?(reloader), 'the reload did not wait for the request in progress'
    ensure
      release << true
    end

    assert_equal [[200, 'held'], [200, 'other']], values_of(holder, reloader)
    assert_equal 1, reloads
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
end
