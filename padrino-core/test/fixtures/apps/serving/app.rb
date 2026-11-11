PADRINO_ROOT = __dir__ unless defined? PADRINO_ROOT

class ServingDemo < Padrino::Application
  set :reload, true

  # Called by /hold, so a test can keep a request in progress.
  class << self
    attr_accessor :on_hold
  end

  get('/') { 'served' }
  get('/hold') { settings.on_hold.call }
end

class ServingOtherDemo < Padrino::Application
  set :reload, true
  get('/') { 'other' }
end

Padrino.load!
