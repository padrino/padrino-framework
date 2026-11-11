PADRINO_ROOT = __dir__ unless defined? PADRINO_ROOT

class ServingDemo < Padrino::Application
  set :reload, true

  # Called by the /hold routes, so a test can keep a request in progress.
  class << self
    attr_accessor :on_hold
  end

  get('/') { 'served' }
  get('/hold') { settings.on_hold.call }
end

class ServingOtherDemo < Padrino::Application
  set :reload, true
  get('/') { 'other' }
  get('/hold') { ServingDemo.on_hold.call }
end

class ServingThirdDemo < Padrino::Application
  set :reload, true
  get('/hold') { ServingDemo.on_hold.call }
end

Padrino.load!
