##
# Removes indentation
#
# @example
#   help <<-EOS.undent
#     Here my help usage
#      sample_code
#
#     Fix
#   EOS
#   puts help.red.bold
#
class String
  # Strip unnecessary indentation of the front of a string
  def undent
    warn "##{__method__} is deprecated"
    gsub(/^.{#{slice(/^ +/).size}}/, '')
  end
end
