project :test => :shoulda, :orm => :activerecord, :dev => true

generate :model, "post title:string body:text"
generate :controller, "posts get:index get:new post:new"
generate :migration, "AddEmailToUser email:string"
generate :fake, "foo bar"

require_dependencies 'nokogiri'

initializer :test, "# Example"

app :testapp do
  generate :controller, "users get:index"
end