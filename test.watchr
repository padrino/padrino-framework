#
# install watchr
# $ sudo gem install watchr
#
# Run With:
# $ watchr test.watchr
#

# --------------------------------------------------
# Helpers
# --------------------------------------------------

def run(path, file)
  return unless File.exists?(File.join(path, "test/", file))
  cmd = "ruby -I\"lib:test\" test/#{file}"
  puts(cmd)
  Dir.chdir(path){ system(cmd) }
end

def run_all_tests
  system("rake test")
end

def sudo(cmd)
  run("sudo #{cmd}")
end

def base_name(file)
  File.basename(file,'.rb').gsub(/\-/, '_')
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------

# Padrino-Admin
watch("^padrino-admin/(.*)") do |m|
  if m[1] =~ /generators/
    run("padrino-admin", "generators/test_#{base_name(m[1])}_generator.rb")
  else
    run("padrino-admin", "test_admin_application.rb")
  end
end
# Padrino-Cache
watch("^padrino-cache.*/(.*)\.rb") { |m| run("padrino-cache", "test_#{base_name(m[1])}.rb")}
# Padrino-Core
watch("^padrino-core.*/(.*)\.rb") { |m| run("padrino-core", "test_#{base_name(m[1])}.rb")}
# Padrino-Gen
watch("^padrino-gen/lib/padrino-gen/generators/cli.rb") { |m| run("padrino-gen", "test_cli.rb") }
watch("^padrino-gen/lib/padrino-gen/generators/(.*)\.rb") { |m| run("padrino-gen", "test_#{base_name(m[1])}_generator.rb")}
# Padrino-Helpers
watch("^padrino-helpers/lib/padrino-helpers/(.*)\.rb") { |m| run("padrino-helpers", "test_#{base_name(m[1])}.rb")}
# Padrino-Mailer
watch("^padrino-mailer/lib/padrino-mailer/(.*)\.rb") { |m| run("padrino-mailer", "test_#{base_name(m[1])}.rb")}

# Any tests in test folder.
watch("^(.*)/test/test_(.*)") { |m| run(m[1], "test_#{m[2]}") }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }