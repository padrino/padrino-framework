class MiniTest::Spec
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
