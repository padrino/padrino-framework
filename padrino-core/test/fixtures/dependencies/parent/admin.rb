require_relative 'user'

class ParentAdmin < ParentUser
  include ParentTrackable
end
