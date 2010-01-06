class Symbol

  def method_missing(method, *args)
    super and return if method.to_s =~ /table_name/
    (self.to_s + ".#{method}(#{args.collect(&:inspect).join(",")})").to_sym
  end

  def missing_methods
    self.to_s.gsub(/(\(.*\))/,"").split(".")
  end

end