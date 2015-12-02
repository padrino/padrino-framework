if PadrinoTasks.load?(:test, false)
  require 'rake/testtask'
  require 'padrino-gen/padrino-tasks/test-helpers'

  app_tasks = Padrino::Generators::TestHelpers.app_tasks(Padrino::Generators::TestHelpers.test_glob)
  app_tasks.each do |app, tests|
    tests.each do |name, folder|
      Rake::TestTask.new("test:#{name}") do |t|
        t.description = "Run tests in #{folder}"
        t.pattern = Padrino::Generators::TestHelpers.test_glob(folder)
        t.verbose = true
      end
    end

    next unless app && app != 'app'

    Rake::TestTask.new("test:#{app}") do |t|
      t.description = "Run all the tests for the #{app} app"
      t.pattern = Padrino::Generators::TestHelpers.test_glob("test/#{app}")
      t.verbose = true
    end
  end

  Rake::TestTask.new do |t|
    t.description = 'Run application test suite'
    t.pattern = Padrino::Generators::TestHelpers.test_glob
    t.verbose = true
  end

  task :default => 'test'
end
