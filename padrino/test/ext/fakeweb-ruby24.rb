# FakeWeb is dead. Ruby 2.4 apparently calls #close even if a socked is already closed.
class FakeWeb::StubSocket
  def close
  end
end
