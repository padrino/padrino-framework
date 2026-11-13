class LoadedExcludedThing < LoadedExcludedBase
  def self.other_value
    2
  end
end

class LoadedExcludedPoint < Struct.new(:x, :y)
  def sum
    x + y
  end
end

class LoadedExcludedLabel
  alias label inspect
end
