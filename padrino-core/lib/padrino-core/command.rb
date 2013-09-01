require 'rbconfig'

module Padrino
  ##
  # This method return the correct location of padrino bin or
  # exec it using Kernel#system with the given args.
  #
  # @param [Array] args
  #   command or commands to execute
  #
  # @return [Boolean]
  #
  # @example
  #   Padrino.bin('start', '-e production')
  #
  def self.bin(*args)
    @padrino_bin ||= [self.ruby_command, File.expand_path("../../../bin/padrino", __FILE__)]
    args.empty? ? @padrino_bin : system(args.unshift(@padrino_bin).join(" "))
  end

  ##
  # Return the path to the ruby interpreter taking into account multiple
  # installations and windows extensions.
  #
  # @return [String]
  #   path to ruby bin executable
  #
  def self.ruby_command
    @ruby_command ||= begin
      ruby = File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name'])
      ruby << RbConfig::CONFIG['EXEEXT']
      escape_spaces_from_ruby_executable_path
    end
  end

  private
    def escape_spaces_from_ruby_executable_path
      ruby.sub!(/.*\s.*/m, '"\&"')
    end
end
