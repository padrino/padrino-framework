if defined? ActiveSupport
  require 'active_support/core_ext/string/inflections'
else
  require 'padrino-support/inflections'

  class String
    def pluralize
      Padrino::Inflections.pluralize(TemporaryString.new(to_str)).to_str
    end

    def underscore
      Padrino::Inflections.underscore(TemporaryString.new(to_str)).to_str
    end

    def camelize
      Padrino::Inflections.camelize(TemporaryString.new(to_str)).to_str
    end

    def classify
      Padrino::Inflections.classify(TemporaryString.new(to_str)).to_str
    end

    def constantize
      Padrino::Inflections.constantize(TemporaryString.new(to_str))
    end
  end

  class TemporaryString < String
    undef_method :pluralize
    undef_method :underscore
    undef_method :camelize
    undef_method :classify
    undef_method :constantize
    def to_s; self; end
  end
end
