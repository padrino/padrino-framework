require 'bundler/setup'
require 'padrino-core'

class Classy < Padrino::Application

  set :foo, 'baf'

  get '/' do
    settings.foo
  end
end

Padrino.mount(Classy).to('/')
Padrino.run!
