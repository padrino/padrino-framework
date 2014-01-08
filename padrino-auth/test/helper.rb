ENV['PADRINO_ENV'] = 'development'

require File.expand_path('../../../load_paths', __FILE__)
require File.dirname(__FILE__)+'/../../padrino-core/test/helper'
require 'padrino-auth'

class MiniTest::Spec
  def set_access(*args)
    @app.set_access(*args)
  end

  def allow(subject = nil, path = '/')
    @app.fake_session[:visitor] = nil
    get "/login/#{subject.id}" if subject
    get path
    assert_equal 200, status, caller.first.to_s
  end

  def deny(subject = nil, path = '/')
    @app.fake_session[:visitor] = nil
    get "/login/#{subject.id}" if subject
    get path
    assert_equal 403, status, caller.first.to_s
  end
end
