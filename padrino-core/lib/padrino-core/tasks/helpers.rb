module Padrino
  module Tasks
    module Helpers

      def chdir(dir)
        return unless dir
        begin
          Dir.chdir(dir.to_s)
        rescue Errno::ENOENT
          puts "=> You specified Padrino root as #{dir}, " +
               "that seems to be inexistent."
        rescue Errno::EACCES
          puts "=> You specified Padrino root as #{dir}, " +
               "yet the current user does not have access to it."
        end
      end

    end
  end
end
