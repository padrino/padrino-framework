Dir[File.dirname(__FILE__) + "/generators/{components}/**/*.rb"].each { |lib| require lib }
require File.dirname(__FILE__) + "/generators/actions.rb"
Dir[File.dirname(__FILE__) + "/generators/{skeleton,mailer,controller,model}.rb"].each { |lib| require lib }
