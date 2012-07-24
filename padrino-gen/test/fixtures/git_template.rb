project :test => :rspec, :orm => :activerecord
git :init
git :add, "."
git :commit, "-m 'hello'"
