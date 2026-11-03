module Padrino
  # The servers Padrino runs on, in the order Padrino::Server tries them.
  SERVERS = %w[thin puma falcon webrick].freeze
  # The servers Padrino no longer runs on: none of them supports Rack 3.
  REMOVED_SERVERS = %w[mongrel spider-gazelle trinidad].freeze

  ##
  # Returns the message for a server Padrino no longer runs on, or nil. Names compare the way
  # Rackup::Handler.get resolves them, so Mongrel, spider_gazelle and SpiderGazelle match too.
  #
  def self.removed_server_message(name)
    normalized = name.to_s.gsub(/(?<=[a-z\d])(?=[A-Z])/, '_').downcase.tr('_', '-')
    return unless REMOVED_SERVERS.include?(normalized)

    "The #{name} server was removed from Padrino; use one of #{SERVERS.join(', ')} instead."
  end
end
