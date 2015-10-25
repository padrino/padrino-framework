module Padrino
  module Generators
    module TestHelpers
      def self.spec_glob(root = 'spec')
        "#{root}/**/*_spec.rb"
      end

      def self.test_glob(root = 'test')
        "#{root}/**/*_test.rb"
      end

      def self.app_tasks(glob)
        app_tasks = Hash.new { |apps, name| apps[name] = [] }

        Dir[glob].each do |path|
          dirs = path.split('/')
          app = nil
          if dirs[2].end_with?('.rb') && File.file?(path)
            app = 'app'
            name = dirs[1]
          else
            app = dirs[1]
            name = app == 'app' ? dirs[2] : "#{dirs[1]}:#{dirs[2]}"
          end

          test = [ name, File.dirname(path) ]
          next if app_tasks[app].include?(test)

          app_tasks[app] << test
        end

        app_tasks
      end
    end
  end
end
