if PadrinoTasks.load?(:spec, false)
  require 'rspec/core/rake_task'
  require 'padrino-gen/padrino-tasks/test-helpers'

  app_tasks = Padrino::Generators::TestHelpers.app_tasks(Padrino::Generators::TestHelpers.spec_glob)
  app_tasks.each do |app, tests|
    tests.each do |name, folder|
      desc "Run specs in #{folder}"
      RSpec::Core::RakeTask.new("spec:#{name}") do |t|
        t.pattern = Padrino::Generators::TestHelpers.spec_glob(folder)
        t.verbose = true
      end
    end

    next unless app && app != 'app'

    desc "Run all the specs for the #{app} app"
    RSpec::Core::RakeTask.new("spec:#{app}") do |t|
      t.pattern = Padrino::Generators::TestHelpers.spec_glob("spec/#{app}")
      t.verbose = true
    end
  end

  desc 'Run application test suite'
  RSpec::Core::RakeTask.new do |t|
    t.verbose = true
  end

  task :default => 'spec'
end
