require_relative 'helper'

describe 'Dependencies' do
  describe 'when we require a dependency that have another dependency' do
    before do
      @log_level = Padrino::Logger::Config[:test]
      @io = StringIO.new
      Padrino::Logger::Config[:test] = { log_level: :error, stream: @io }
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
            Padrino.root('fixtures/dependencies/a.rb'),
            Padrino.root('fixtures/dependencies/b.rb'),
            Padrino.root('fixtures/dependencies/c.rb'),
            Padrino.root('fixtures/dependencies/d.rb')
          )
        end
      end
      assert_equal 1, D
      assert_match(/RuntimeError - SomeThing/, @io.string)
    end

    it 'should resolve dependency problems' do
      capture_io do
        Padrino.require_dependencies(
          Padrino.root('fixtures/dependencies/a.rb'),
          Padrino.root('fixtures/dependencies/b.rb'),
          Padrino.root('fixtures/dependencies/c.rb')
        )
      end
      assert_equal %w[B C], A_result
      assert_equal 'C', B_result
      assert_equal '', @io.string
    end

    it 'should remove partially loaded constants' do
      capture_io do
        Padrino.require_dependencies(
          Padrino.root('fixtures/dependencies/circular/e.rb'),
          Padrino.root('fixtures/dependencies/circular/f.rb'),
          Padrino.root('fixtures/dependencies/circular/g.rb')
        )
      end
      assert_equal ['name'], F.fields
      assert_equal '', @io.string
    end

    it 'should not silence LoadError raised in dependencies excluded from reloading' do
      capture_io do
        assert_raises(LoadError) do
          Padrino::Reloader.exclude << Padrino.root('fixtures/dependencies/linear/h.rb')
          Padrino.require_dependencies(
            Padrino.root('fixtures/dependencies/linear/h.rb'),
            Padrino.root('fixtures/dependencies/linear/i.rb')
          )
        end
      end
    end

    it 'should not remove constants that are newly commited in nested require_dependencies' do
      capture_io do
        Padrino.require_dependencies(
          Padrino.root('fixtures/dependencies/nested/j.rb'),
          Padrino.root('fixtures/dependencies/nested/k.rb'),
          Padrino.root('fixtures/dependencies/nested/l.rb')
        )
      end
      assert_equal 'hello', M.hello
    end

    it 'should not remove constants that are already `remove_const`ed' do
      enabled = Padrino::Reloader.instance_variable_get(:@enabled)
      Padrino::Reloader.enabled = true
      capture_io do
        Padrino.require_dependencies(
          Padrino.root('fixtures/dependencies/gc/t.rb'),
          Padrino.root('fixtures/dependencies/gc/u.rb')
        )
      end
      assert_equal 'hello', V.hello
    ensure
      Padrino::Reloader.enabled = enabled
    end

    describe 'change log level for :devel' do
      before do
        @log_level_devel = Padrino::Logger::Config[:test]
        @io = StringIO.new
        Padrino::Logger::Config[:test] = { log_level: :devel, stream: @io }
        Padrino::Logger.setup!
      end

      after do
        Padrino::Logger::Config[:test] = @log_level_devel
        Padrino::Logger.setup!
      end

      it 'should resolve interdependence by out/in side nested require_dependencies' do
        capture_io do
          Padrino.require_dependencies(
            Padrino.root('fixtures/dependencies/nested/ooo.rb'),
            Padrino.root('fixtures/dependencies/nested/ppp.rb'),
            Padrino.root('fixtures/dependencies/nested/qqq.rb')
          )
        end
        assert_equal 'hello', RRR.hello
        assert_equal 'hello', OOO.hello
        assert_equal 'hello', RollbackTarget.hello
        assert_match(/Removed constant RollbackTarget from Object/, @io.string)
      end
    end
  end

  describe 'when reloading is disabled' do
    before do
      @enabled = Padrino::Reloader.instance_variable_get(:@enabled)
      Padrino::Reloader.enabled = false
      @log_level = Padrino::Logger::Config[:test]
      @io = StringIO.new
      Padrino::Logger::Config[:test] = { log_level: :warn, stream: @io }
      Padrino::Logger.setup!
    end

    after do
      Padrino::Reloader.enabled = @enabled
      Padrino::Logger::Config[:test] = @log_level
      Padrino::Logger.setup!
    end

    it 'should resolve dependency problems without tracking files' do
      Padrino::Reloader::Storage.stub(:prepare, ->(*) { flunk 'should not track files' }) do
        Padrino.require_dependencies(
          Padrino.root('fixtures/dependencies/untracked/a.rb'),
          Padrino.root('fixtures/dependencies/untracked/b.rb')
        )
      end
      assert_equal UntrackedBase, Untracked.superclass
    end

    it 'should remove constants of a file that failed partway before retrying it' do
      capture_io do
        Padrino.require_dependencies(
          Padrino.root('fixtures/dependencies/partial/a.rb'),
          Padrino.root('fixtures/dependencies/partial/b.rb')
        )
      end
      assert_includes PartialPoint.ancestors, PartialConcern
    end

    it 'should load files required by a file that failed partway again on retry' do
      capture_io do
        Padrino.require_dependencies(
          Padrino.root('fixtures/dependencies/parent/admin.rb'),
          Padrino.root('fixtures/dependencies/parent/user.rb'),
          Padrino.root('fixtures/dependencies/parent/trackable.rb')
        )
      end
      assert_equal ParentUser, ParentAdmin.superclass
      assert_includes ParentAdmin.ancestors, ParentTrackable
    end

    it 'should keep autoloads declared by a file that failed partway' do
      capture_io do
        Padrino.require_dependencies(
          Padrino.root('fixtures/dependencies/autoload/a.rb'),
          Padrino.root('fixtures/dependencies/autoload/b.rb')
        )
      end
      assert_includes AutoloadUser.ancestors, AutoloadConcern
      assert_kind_of Class, AutoloadLazy
    end

    it 'should not re-run files on reload' do
      file = Padrino.root('fixtures/dependencies/reload/untracked.rb')
      Object.const_set(:UNTRACKED_LOADS, [])
      # Only the fixture is checked for changes, not files other tests left mounted.
      Padrino.stub(:dependency_paths, [file]) do
        Padrino.stub(:mounted_apps, []) do
          Padrino::Reloader.stub(:special_files, Set.new) do
            Padrino.require_dependencies(file)
            refute Padrino::Reloader.changed?
            Padrino.reload!

            mtime = File.mtime(file)
            File.utime(mtime + 60, mtime + 60, file)
            begin
              assert Padrino::Reloader.changed?
              Padrino.reload!
              refute Padrino::Reloader.changed?
            ensure
              File.utime(mtime, mtime, file)
            end
          end
        end
      end
      assert_equal [:untracked], UNTRACKED_LOADS
      assert_match(/Skipping reload of .*untracked\.rb/, @io.string)
    end

    it 'should track and reload files loaded with force' do
      file = Padrino.root('fixtures/dependencies/reload/forced.rb')
      Object.const_set(:FORCED_LOADS, [])
      Padrino.require_dependencies(file, force: true)
      Padrino.require_dependencies(file, force: true)
      assert_equal %i[forced forced], FORCED_LOADS
    end

    it 'should not force reload files loaded without tracking' do
      file = Padrino.root('fixtures/dependencies/reload/untracked_forced.rb')
      Object.const_set(:UNTRACKED_FORCED_LOADS, [])
      Padrino.require_dependencies(file)
      Padrino.require_dependencies(file, force: true)
      assert_equal [:untracked_forced], UNTRACKED_FORCED_LOADS
      assert_match(/Skipping reload of .*untracked_forced\.rb/, @io.string)
    end
  end

  describe 'Padrino::Reloader.enabled?' do
    before do
      @enabled = Padrino::Reloader.instance_variable_get(:@enabled)
      Padrino::Reloader.enabled = nil
    end

    after do
      Padrino::Reloader.enabled = @enabled
    end

    it 'should be enabled only in development by default' do
      refute Padrino::Reloader.enabled?
      Padrino.stub(:env, :development) { assert Padrino::Reloader.enabled? }
    end

    it 'should be configurable' do
      Padrino::Reloader.enabled = true
      assert Padrino::Reloader.enabled?
    end
  end

  describe 'Padrino::Reloader.remove_constant' do
    after do
      Object.send(:remove_const, :RemoveConstantTarget) if Object.autoload?(:RemoveConstantTarget) || Object.const_defined?(:RemoveConstantTarget, false)
    end

    it 'should not remove a newer class defined under the same name' do
      old_class = Object.const_set(:RemoveConstantTarget, Class.new)
      Object.send(:remove_const, :RemoveConstantTarget)
      new_class = Object.const_set(:RemoveConstantTarget, Class.new)
      Padrino::Reloader.remove_constant(old_class)
      assert_same new_class, Object.const_get(:RemoveConstantTarget)
      Padrino::Reloader.remove_constant(new_class)
      refute Object.const_defined?(:RemoveConstantTarget, false)
    end

    it 'should leave an autoload registered under the removed name alone' do
      old_class = Object.const_set(:RemoveConstantTarget, Class.new)
      Object.send(:remove_const, :RemoveConstantTarget)
      Object.autoload(:RemoveConstantTarget, '/nonexistent/padrino_missing_autoload.rb')
      Padrino::Reloader.remove_constant(old_class)
      assert Object.autoload?(:RemoveConstantTarget)
    end
  end
end
