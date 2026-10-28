# frozen_string_literal: true

module Filterable
  extend ActiveSupport::Concern

  included do
    define_method(:filter) { 'v1' }
  end

  def label
    'l1'
  end
end
