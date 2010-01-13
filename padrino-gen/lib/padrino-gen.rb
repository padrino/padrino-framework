require 'padrino-core/support_lite'

Dir[File.dirname(__FILE__) + '/padrino-gen/generators/{components}/**/*.rb'].each { |lib| require lib }
require File.dirname(__FILE__) + '/padrino-gen/generators/actions'
require File.dirname(__FILE__) + '/padrino-gen/generators/base'
require File.dirname(__FILE__) + '/padrino-gen/generators'


# Add our rakes when padrino core require this file.
require 'padrino-core/tasks'
Padrino::Tasks.files << Dir[File.dirname(__FILE__) + "/padrino-gen/padrino-tasks/**/*.rb"]