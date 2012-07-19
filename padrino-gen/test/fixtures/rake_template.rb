project :test => :shoulda, :orm => :activerecord
# create_file "lib/tasks/test.rake", <<-RAKE
# task :custom do
#   File.open('#{destination_root("/tmp/custom.txt")}', 'w') { |f|
#     f.puts('Completed custom rake test')
#   }
# end
# RAKE
rake "custom"
