ENV['PADRINO_ENV'] = 'development'

require File.expand_path('../../../load_paths', __FILE__)
require File.dirname(__FILE__)+'/../../padrino-core/test/helper'
require 'padrino-auth'

# Helper methods for testing Padrino::Access
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

module Character
  extend self

  def authenticate(credentials)
    case
    when credentials[:email] && credentials[:password]
      target = all.find{ |resource| resource.id.to_s == credentials[:email] }
      target.name.gsub(/[^A-Z]/,'') == credentials[:password] ? target : nil
    when credentials.has_key?(:session_id)
      all.find{ |resource| resource.id == credentials[:session_id] }
    else
      puts credentials
      false
    end
  end

  def all
    @all = [
      OpenStruct.new(:id => :bender,   :name => 'Bender Bending Rodriguez', :role => :robots  ),
      OpenStruct.new(:id => :leela,    :name => 'Turanga Leela',            :role => :mutants ),
      OpenStruct.new(:id => :fry,      :name => 'Philip J. Fry',            :role => :humans  ),
      OpenStruct.new(:id => :ami,      :name => 'Amy Wong',                 :role => :humans  ),
      OpenStruct.new(:id => :zoidberg, :name => 'Dr. John A. Zoidberg',     :role => :lobsters),
    ]
  end
end
