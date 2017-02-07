
class RackApp
  def self.call(env)
    if env['PATH_INFO'] == '/404'
      [404, {}, ["not found ;("]]
    else
      [200, {}, ["hello rack app"]]
    end
  end

  def self.prerequisites
    super
  end
end

RackApp2 = lambda{|_| [200, {}, ["hello rack app2"]] }

class SinatraApp < Sinatra::Base
  set :public_folder, File.dirname(__FILE__)
  get "/" do
    "hello sinatra app"
  end
end
