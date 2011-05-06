project :test => :shoulda, :orm => :activerecord, :template => 'mongochist', :dev => true

generate :model, "post title:string body:text"
generate :controller, "posts get:index get:new post:new"
generate :migration, "AddEmailToUser email:string"
generate :fake, "foo bar"
generate :plugin, "carrierwave"

require_dependencies 'nokogiri'

initializer :test, "# Example"

app :testapp do
  generate :controller, "users get:index"
end
