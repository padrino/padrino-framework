Dir[File.dirname(__FILE__) + "/generators/{components}/**/*.rb"].each { |lib| require lib }
require File.dirname(__FILE__) + "/generators/actions.rb"
require File.dirname(__FILE__) + "/generators/skeleton.rb"
require File.dirname(__FILE__) + "/generators/controller.rb"
