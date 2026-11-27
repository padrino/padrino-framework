# Apps mounted next to the reloading ones that don't reload themselves.

class ServingSteadyDemo < Padrino::Application
  set :reload, false
  get('/') { 'steady' }
  get('/hold') { ServingDemo.on_hold.call }
end

class ServingSinatraDemo < Sinatra::Base
  get('/') { 'sinatra' }
  get('/hold') { ServingDemo.on_hold.call }
end
