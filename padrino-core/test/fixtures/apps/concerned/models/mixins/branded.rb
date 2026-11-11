# frozen_string_literal: true

module Branded
  extend ActiveSupport::Concern

  def self.name
    'Brand'
  end

  included do
    define_method(:brand) { 'b1' }
  end
end
