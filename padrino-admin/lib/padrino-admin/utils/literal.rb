module Padrino
  module Admin
    module Utils
      # This module it's used for convert a string in a literal json variable
      module Literal
        # This method return a json literal variable
        def to_l
          Padrino::ExtJs::Variable.new(self)
        end
      end
    end
  end
end