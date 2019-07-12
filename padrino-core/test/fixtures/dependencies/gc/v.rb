class V
  $prevent_from_being_gced ||= []
  $prevent_from_being_gced.push(self)

  def self.hello
    "hello"
  end

  W
end
