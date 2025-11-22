require 'English'
require File.expand_path('lib/app_gem/version', __dir__)

Gem::Specification.new do |gem|
  gem.authors       = ['Florian Gilcher']
  gem.email         = ['florian.gilcher@asquera.de']
  gem.description   = 'TODO: Write a gem description'
  gem.summary       = 'TODO: Write a gem summary'
  gem.homepage      = ''

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'app_gem'
  gem.require_paths = ['app', 'lib']
  gem.version       = AppGem::VERSION
end
