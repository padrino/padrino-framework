require File.expand_path(File.dirname(__FILE__) + "/helper")
require File.expand_path(File.dirname(__FILE__) + "/../lib/padrino-gen/padrino-tasks/sql-helpers")

describe "SqlHelpers" do
  def setup
    Process.expects(:wait)
  end

  describe "create_db" do
    describe "postgres" do
      it "does not set PGPASSWORD when password is nil" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {}
        end
        Padrino::Generators::SqlHelpers.create_db("postgres", nil, nil, nil, "database", nil, nil)
      end

      it "does not set PGPASSWORD when password is blank" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {}
        end
        Padrino::Generators::SqlHelpers.create_db("postgres", nil, "", nil, "database", nil, nil)
      end

      it "sets PGPASSWORD when password is present" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {"PGPASSWORD" => "hunter2"}
        end
        Padrino::Generators::SqlHelpers.create_db("postgres", nil, "hunter2", nil, "database", nil, nil)
      end
    end

    describe "mysql" do
      it "does not set MYSQL_PWD when password is nil" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {}
        end
        Padrino::Generators::SqlHelpers.create_db("mysql", nil, nil, nil, "database", nil, nil)
      end

      it "does not set MYSQL_PWD when password is blank" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {}
        end
        Padrino::Generators::SqlHelpers.create_db("mysql", nil, "", nil, "database", nil, nil)
      end

      it "sets MYSQL_PWD when password is present" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {"MYSQL_PWD" => "hunter2"}
        end
        Padrino::Generators::SqlHelpers.create_db("mysql", nil, "hunter2", nil, "database", nil, nil)
      end
    end
  end

  describe "drop_db" do
    describe "postgres" do
      it "does not set PGPASSWORD when password is nil" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {}
        end
        Padrino::Generators::SqlHelpers.drop_db("postgres", nil, nil, nil, "database")
      end

      it "does not set PGPASSWORD when password is blank" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {}
        end
        Padrino::Generators::SqlHelpers.drop_db("postgres", nil, "", nil, "database")
      end

      it "sets PGPASSWORD when password is present" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {"PGPASSWORD" => "hunter2"}
        end
        Padrino::Generators::SqlHelpers.drop_db("postgres", nil, "hunter2", nil, "database")
      end
    end

    describe "mysql" do
      it "does not set MYSQL_PWD when password is nil" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {}
        end
        Padrino::Generators::SqlHelpers.drop_db("mysql", nil, nil, nil, "database")
      end

      it "does not set MYSQL_PWD when password is blank" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {}
        end
        Padrino::Generators::SqlHelpers.drop_db("mysql", nil, "", nil, "database")
      end

      it "sets MYSQL_PWD when password is present" do
        Process.expects(:spawn).with() do |environment, *args|
          environment == {"MYSQL_PWD" => "hunter2"}
        end
        Padrino::Generators::SqlHelpers.drop_db("mysql", nil, "hunter2", nil, "database")
      end
    end
  end
end

