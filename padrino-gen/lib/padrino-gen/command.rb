require 'padrino-core/command'

module Padrino
  ##
  # This method return the correct location of padrino-gen bin or
  # exec it using Kernel#system with the given args.
  #
  # @param [Array<String>] args.
  #   Splat of arguments to pass to padrino-gen.
  #
  # @example
  #   Padrino.bin_gen(:app, name.to_s, "-r=#{destination_root}")
  #
  def self.bin_gen(*args)
    @_padrino_gen_bin ||= [Padrino.ruby_command, File.expand_path("../../../bin/padrino-gen", __FILE__)]
    system *@_padrino_gen_bin, *args
  end
end
