require 'padrino-core/support_lite'
require 'padrino-gen/generators'
# Add our rakes when padrino core require this file.
require 'padrino-core/tasks'
Padrino::Tasks.files << Dir[File.dirname(__FILE__) + "/padrino-gen/padrino-tasks/**/*.rb"]