require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'

# Skip the releasing tag
class Bundler::GemHelper
  def version_tag
    "#{version}"
  end
end

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.libs << '../padrino/test'
  test.test_files = Dir['test/**/test_*.rb']
  test.verbose = true
  test.warning = false
end

YARD::Rake::YardocTask.new

task :default => :test
