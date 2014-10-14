
class RackApp
  def self.call(_)
    [200, {}, ["hello rack app"]]
  end
end

RackApp2 = lambda{|_| [200, {}, ["hello rack app2"]] }

class SinatraApp < Sinatra::Base
  set :public_folder, File.dirname(__FILE__)
  get "/" do
    "hello sinatra app"
  end
end
