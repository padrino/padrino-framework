module Padrino
  module Tasks
    module Helpers

      def chdir(dir)
        return unless dir
        begin
          Dir.chdir(dir.to_s)
        rescue Errno::ENOENT
          puts "=> Specified Padrino root '#{dir}' " +
               "does not appear to exist!"
        rescue Errno::EACCES
          puts "=> Specified Padrino root '#{dir}' " +
               "cannot be accessed by the current user!"
        end
      end

    end
  end
end
