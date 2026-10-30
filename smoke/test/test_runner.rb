require_relative 'helper'

describe 'Smoke::Runner' do
  # Records the steps called on it, and fails the step named by FAIL_AT.
  class RecordingProject
    class << self
      attr_accessor :calls, :fail_at, :roots
    end

    def initialize(_combination, root:)
      self.class.roots << root
      @root = root
    end

    def path
      File.join(@root, 'smoke')
    end

    Smoke::Runner::STEPS.each do |step|
      define_method(step) do
        self.class.calls << step
        raise Smoke::StepFailed.new(step, %w[false], @root, 'exit 1', '') if step == self.class.fail_at
      end
    end
  end

  before do
    RecordingProject.calls = []
    RecordingProject.roots = []
    RecordingProject.fail_at = nil
  end

  let(:combo_name) { 'none-erb-rspec' }

  def run_quietly(**options)
    out, = capture_io { Smoke::Runner.run(combo_name, project_class: RecordingProject, **options) }
    out
  end

  it 'runs every step in order' do
    run_quietly
    assert_equal Smoke::Runner::STEPS, RecordingProject.calls
  end

  it 'calls every step even for a project without an orm' do
    run_quietly
    assert_includes RecordingProject.calls, :migrate_empty!
  end

  it 'stops at the failing step and re-raises' do
    RecordingProject.fail_at = Smoke::Runner::STEPS[2]
    assert_raises(Smoke::StepFailed) { run_quietly }
    assert_equal Smoke::Runner::STEPS.first(3), RecordingProject.calls
  end

  it 'removes the project after a failure' do
    RecordingProject.fail_at = Smoke::Runner::STEPS[2]
    assert_raises(Smoke::StepFailed) { run_quietly }
    refute File.exist?(RecordingProject.roots.first)
  end

  it 'keeps the project when asked' do
    out = run_quietly(keep: true)
    root = RecordingProject.roots.first
    assert File.directory?(root)
    assert_includes out, root
  ensure
    FileUtils.rm_rf(root) if root
  end

  it 'prints each step' do
    assert_includes run_quietly, "== #{Smoke::Runner::STEPS.last}"
  end

  describe 'a combination with allowed_failure' do
    let(:combos) { [Smoke::Combination.new('name' => combo_name, 'allowed_failure' => 'https://github.com/padrino/padrino-framework/issues/1')] }

    it 'warns instead of raising when it fails' do
      RecordingProject.fail_at = Smoke::Runner::STEPS[1]
      out, = capture_io { refute Smoke::Runner.run(combo_name, project_class: RecordingProject, combinations: combos) }
      assert_includes out, '::warning::'
      assert_includes out, 'issues/1'
    end

    it 'warns that the failure is fixed when it passes' do
      out, = capture_io { assert Smoke::Runner.run(combo_name, project_class: RecordingProject, combinations: combos) }
      assert_match(/::warning::.*passes/, out)
    end
  end
end
