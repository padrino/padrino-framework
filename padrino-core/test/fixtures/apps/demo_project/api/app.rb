module DemoProject
  class API
    def self.call(_)
      [200, {}, ["api app"]]
    end
  end
end
