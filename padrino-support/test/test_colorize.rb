require File.expand_path(File.dirname(__FILE__) + '/helper')

describe "String#colorize" do
  it "should colorize text correctly" do
    assert_equal "Hello world".colorize(:blue), "\e[34mHello world\e[0m"
    assert_equal "Hello world".colorize(:black), "\e[30mHello world\e[0m"
    assert_equal "Hello world".colorize(:red), "\e[31mHello world\e[0m"
    assert_equal "Hello world".colorize(:green), "\e[32mHello world\e[0m"
    assert_equal "Hello world".colorize(:yellow), "\e[33mHello world\e[0m"
    assert_equal "Hello world".colorize(:blue), "\e[34mHello world\e[0m"
    assert_equal "Hello world".colorize(:magenta), "\e[35mHello world\e[0m"
    assert_equal "Hello world".colorize(:cyan), "\e[36mHello world\e[0m"
    assert_equal "Hello world".colorize(:white), "\e[37mHello world\e[0m"
  end

  it "should colorize text when using color name method" do
    assert_equal String::Colorizer.black("Hello world"), "\e[30mHello world\e[0m"
    assert_equal String::Colorizer.red("Hello world"), "\e[31mHello world\e[0m"
    assert_equal String::Colorizer.green("Hello world"), "\e[32mHello world\e[0m"
    assert_equal String::Colorizer.yellow("Hello world"), "\e[33mHello world\e[0m"
    assert_equal String::Colorizer.blue("Hello world"), "\e[34mHello world\e[0m"
    assert_equal String::Colorizer.magenta("Hello world"), "\e[35mHello world\e[0m"
    assert_equal String::Colorizer.cyan("Hello world"), "\e[36mHello world\e[0m"
    assert_equal String::Colorizer.white("Hello world"), "\e[37mHello world\e[0m"
  end
end
