require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'

# Skip the releasing tag
class Bundler::GemHelper
  def release_gem(*args)
    guard_clean
    built_gem_path = build_gem
    rubygem_push(built_gem_path)
  end
end

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.libs << '../padrino/test'
  test.test_files = Dir['test/**/test_*.rb']
  test.verbose = true
end

YARD::Rake::YardocTask.new

task :default => :test
