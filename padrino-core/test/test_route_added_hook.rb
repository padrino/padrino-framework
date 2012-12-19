require File.expand_path('../helper', __FILE__)

module RouteAddedTest
  @routes, @procs = [], []
  def self.routes ; @routes ; end
  def self.procs ; @procs ; end
  def self.route_added(verb, path, proc)
    @routes << [verb, path]
    @procs << proc
  end
end

# describe 'Route Added Hook' do

#   before do
#     RouteAddedTest.routes.clear
#     RouteAddedTest.procs.clear
#   end

#   it "should be notified of an added route" do
#     mock_app {
#       register RouteAddedTest
#       get('/') {}
#     }

#     assert_equal [["GET", "/"], ["HEAD", "/"]],
#       RouteAddedTest.routes
#   end

#   it "should include hooks from superclass" do
#     a = Padrino.new
#     b = Class.new(a)

#     a.register RouteAddedTest
#     b.class_eval { post("/sub_app_route") {} }

#     assert_equal [["POST", "/sub_app_route"]],
#       RouteAddedTest.routes
#   end

#   it "should only run once per extension" do
#     mock_app {
#       register RouteAddedTest
#       register RouteAddedTest
#       get('/') {}
#     }

#     assert_equal [["GET", "/"], ["HEAD", "/"]],
#       RouteAddedTest.routes
#   end

#   it "should pass route blocks as an argument" do
#     mock_app {
#       register RouteAddedTest
#       get('/') {}
#     }

#     assert_kind_of Proc, RouteAddedTest.procs.first    
#   end
# end
