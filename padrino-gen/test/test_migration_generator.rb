require File.dirname(__FILE__) + '/helper'
require 'thor'

class TestMigrationGenerator < Test::Unit::TestCase
  def setup
    @skeleton = Padrino::Generators::Skeleton.dup
    # @mig_gen = Padrino::Generators::Migration.dup
    `rm -rf /tmp/sample_app`
  end

  context 'the migration generator' do
    should "work" do

    end
  end

end