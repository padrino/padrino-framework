require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "Dependencies" do
  describe 'when we require a dependency that have another dependency' do
    before do
      @log_level = Padrino::Logger::Config[:test]
      @io = StringIO.new
      Padrino::Logger::Config[:test] = { :log_level => :error, :stream => @io }
      Padrino::Logger.setup!
    end

    after do
      Padrino::Logger::Config[:test] = @log_level
      Padrino::Logger.setup!
    end

    it 'should raise an error without reloading it twice' do
      capture_io do
        assert_raises(RuntimeError) do
          Padrino.require_dependencies(
            Padrino.root("fixtures/dependencies/a.rb"),
            Padrino.root("fixtures/dependencies/b.rb"),
            Padrino.root("fixtures/dependencies/c.rb"),
            Padrino.root("fixtures/dependencies/d.rb")
          )
        end
      end
      assert_equal 1, D
      assert_match /RuntimeError - SomeThing/, @io.string
    end

    it 'should resolve dependency problems' do
      capture_io do
        Padrino.require_dependencies(
          Padrino.root("fixtures/dependencies/a.rb"),
          Padrino.root("fixtures/dependencies/b.rb"),
          Padrino.root("fixtures/dependencies/c.rb")
        )
      end
      assert_equal ["B", "C"], A_result
      assert_equal "C", B_result
      assert_equal "", @io.string
    end

    it 'should remove partially loaded constants' do
      capture_io do
        Padrino.require_dependencies(
          Padrino.root("fixtures/dependencies/circular/e.rb"),
          Padrino.root("fixtures/dependencies/circular/f.rb"),
          Padrino.root("fixtures/dependencies/circular/g.rb")
        )
      end
      assert_equal ["name"], F.fields
      assert_equal "", @io.string
    end

    it 'should not silence LoadError raised in dependencies excluded from reloading' do
      capture_io do
        assert_raises(LoadError) do
          Padrino::Reloader.exclude << Padrino.root("fixtures/dependencies/linear/h.rb")
          Padrino.require_dependencies(
            Padrino.root("fixtures/dependencies/linear/h.rb"),
            Padrino.root("fixtures/dependencies/linear/i.rb"),
          )
        end
      end
    end

    it 'should not remove constants that are newly commited in nested require_dependencies' do
      capture_io do
        Padrino.require_dependencies(
          Padrino.root("fixtures/dependencies/nested/j.rb"),
          Padrino.root("fixtures/dependencies/nested/k.rb"),
          Padrino.root("fixtures/dependencies/nested/l.rb")
        )
      end
      assert_equal "hello", M.hello
    end


    describe "change log level for :devel" do
      before do
        @log_level_devel = Padrino::Logger::Config[:test]
        @io = StringIO.new
        Padrino::Logger::Config[:test] = { :log_level => :devel, :stream => @io }
        Padrino::Logger.setup!
      end

      after do
        Padrino::Logger::Config[:test] = @log_level_devel
        Padrino::Logger.setup!
      end

      it 'should resolve interdependence by out/in side nested require_dependencies' do
        capture_io do
          Padrino.require_dependencies(
            Padrino.root("fixtures/dependencies/nested/ooo.rb"),
            Padrino.root("fixtures/dependencies/nested/ppp.rb"),
            Padrino.root("fixtures/dependencies/nested/qqq.rb")
          )
        end
        assert_equal "hello", RRR.hello
        assert_equal "hello", OOO.hello
        assert_equal "hello", RollbackTarget.hello
        assert_match /Removed constant RollbackTarget from Object/, @io.string
      end
    end
  end
end
