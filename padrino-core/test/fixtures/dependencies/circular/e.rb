class E
  def self.fields
    @fields ||= []
  end

  def self.inherited(subclass)
    super
    subclass.fields.replace fields.dup
  end

  fields << "name"
end
