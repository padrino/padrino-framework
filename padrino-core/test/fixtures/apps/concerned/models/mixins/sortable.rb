# frozen_string_literal: true

module Sortable
  extend ActiveSupport::Concern

  included do
    define_method(:sort_key) { 's1' }
  end

  def sort_label
    's1'
  end
end
