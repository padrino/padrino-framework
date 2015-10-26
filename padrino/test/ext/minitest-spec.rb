class MiniTest::Spec
  # assert_has_tag(:h1, :content => "yellow") { "<h1>yellow</h1>" }
  # In this case, block is the html to evaluate
  def assert_has_tag(name, attributes = {})
    html = yield if block_given?
    assert html.html_safe?, 'output in not #html_safe?'
    matcher = HaveSelector.new(name, attributes)
    assert matcher.matches?(html), matcher.failure_message
  end

  # assert_has_no_tag(:h1, :content => "yellow") { "<h1>green</h1>" }
  # In this case, block is the html to evaluate
  def assert_has_no_tag(name, attributes = {}, &block)
    html = yield if block_given?
    assert html.html_safe?, 'output in not #html_safe?'
    matcher = HaveSelector.new(name, attributes)
    assert !matcher.matches?(html), matcher.negative_failure_message
  end

  # Assert_file_exists('/tmp/app')
  def assert_file_exists(file_path)
    assert File.file?(file_path), "File at path '#{file_path}' does not exist!"
  end

  # Assert_no_file_exists('/tmp/app')
  def assert_no_file_exists(file_path)
    assert !File.exist?(file_path), "File should not exist at path '#{file_path}' but was found!"
  end

  # assert_dir_exists('/tmp/app')
  def assert_dir_exists(file_path)
    assert File.directory?(file_path), "Folder at path '#{file_path}' does not exist"
  end

  # assert_no_dir_exists('/tmp/app')
  def assert_no_dir_exists(file_path)
    assert !File.exist?(file_path), "Folder should not exist at path '#{file_path}' but was found"
  end

  # Asserts that a file matches the pattern
  def assert_match_in_file(pattern, file)
    File.file?(file) ? assert_match(pattern, File.read(file)) : assert_file_exists(file)
  end

  def assert_no_match_in_file(pattern, file)
    File.file?(file) ? refute_match(pattern, File.read(file)) : assert_file_exists(file)
  end
end
