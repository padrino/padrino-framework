require 'padrino-core/support_lite'
require 'padrino-core/version'
require 'padrino-gen/generators'
require 'padrino-core/tasks'
Padrino::Tasks.files << Dir[File.dirname(__FILE__) + "/padrino-gen/padrino-tasks/**/*.rb"]