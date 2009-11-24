PADRINO_ROOT = File.dirname(__FILE__) unless defined? PADRINO_ROOT

module LibDemo
  module_function
  
  def give_me_a_random
    @rand ||= rand(100)
  end
end

class Multi1Demo < Padrino::Application
  get("/old"){ "Old Sinatra Way" }
end

class Mutli2Demo < Padrino::Application
  get("/old"){ "Old Sinatra Way" }
end

Multi1Demo.controllers do
  get(""){ "Given random #{LibDemo.give_me_a_random}" }
end

Multi2Demo.controllers do
  get(""){ "The magick number is: 86!" } # Change only the number!!!
end

Padrino.load!
