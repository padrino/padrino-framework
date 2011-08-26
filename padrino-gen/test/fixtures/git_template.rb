project :test => :rspec, :orm => :activerecord
git :init
git :add, "."
git :commit, "hello"
