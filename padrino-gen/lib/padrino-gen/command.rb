require 'padrino-core/command'

module Padrino
  ##
  # This method return the correct location of padrino-gen bin or
  # exec it using Kernel#system with the given args
  #
  def self.bin_gen(*args)
    @_padrino_gen_bin ||= [Padrino.ruby_command, File.expand_path("../../../bin/padrino-gen", __FILE__)]
    args.empty? ? @_padrino_gen_bin : system(args.unshift(@_padrino_gen_bin).join(" "))
  end
end # Padrino