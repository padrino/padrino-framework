# This file will be safe loaded three times.
# The first one fail because B and C constant are not defined but Foo::Bar will be set to 1
# The second one file because B requires C constant so will not be loaded Foo::Bar still be 1 (because safe load clear the object space)
# The third one B and C are defined but Foo::Bar still be 1 (because safe load clear the object space)

# Initialize Foo
class Foo
  Bar  = 0 unless defined?(Bar)
  Bar += 1
end

# But here we need some of b.rb
A_result = [B, C]

A = "A"