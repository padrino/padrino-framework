require_relative 'helper'
require 'padrino-support/inflections'

describe 'Padrino::Inflections' do
  # Each row is a word, its singular and its plural as ActiveSupport's default inflections give them.
  # Rows without a plural are words whose Padrino plural differs from ActiveSupport's on purpose:
  # Sequel derives default table names from pluralize, so changing a plural would rename existing tables.
  activesupport_inflections = [
    %w[status status statuses],
    %w[statuses status statuses],
    %w[address address addresses],
    %w[addresses address addresses],
    %w[user_address user_address user_addresses],
    %w[class class classes],
    %w[process process processes],
    %w[business business businesses],
    %w[alias alias aliases],
    %w[aliases alias aliases],
    %w[bus bus buses],
    %w[buses bus buses],
    %w[analysis analysis analyses],
    %w[analyses analysis analyses],
    %w[basis basis bases],
    %w[crisis crisis crises],
    %w[diagnosis diagnosis diagnoses],
    %w[thesis thesis theses],
    %w[database database databases],
    %w[databases database databases],
    %w[octopi octopus],
    %w[virus virus],
    %w[police police],
    %w[person person people],
    %w[people person],
    %w[men man],
    %w[children child],
    %w[testis testis testes],
    %w[slice slice slices],
    %w[blouse blouse],
    %w[mouse mouse mice],
    %w[post post posts],
    %w[categories category categories],
    %w[boxes box boxes],
    %w[wives wife wives]
  ]

  it 'should be tested without ActiveSupport, which it would delegate to' do
    refute_respond_to '', :singularize
  end

  activesupport_inflections.each do |word, singular, plural|
    it "should singularize #{word} as #{singular}" do
      assert_equal singular, Padrino::Inflections.singularize(word)
    end

    next unless plural

    it "should pluralize #{word} as #{plural}" do
      assert_equal plural, Padrino::Inflections.pluralize(word)
    end
  end
end
