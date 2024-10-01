require 'stringio'
require 'test_helper'
require_relative "../../scripts/openapi_slicer_cli"

class OpenapiSlicerCLITest < Minitest::Test
  def setup
    # Redirect stdout and stderr to capture outputs for assertions
    @original_stdout = $stdout
    $stdout = StringIO.new
    @original_stderr = $stderr
    $stderr = StringIO.new
  end

  def teardown
    # Restore stdout and stderr
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  def test_missing_required_options
    argv = []
    cli = ::OpenapiSlicerCLI.new(argv)
    # Expect the script to exit due to missing options
    assert_raises(SystemExit) { cli.run }
    output = $stdout.string
    assert_match(/Missing option: --input-file/, output)
  end

  def test_help_option
    argv = ['-h']
    cli = ::OpenapiSlicerCLI.new(argv)
    # Expect the script to exit after displaying help
    assert_raises(SystemExit) { cli.run }
    output = $stdout.string
    assert_match(/Usage: openapi_slicer/, output)
  end

  def test_run_with_output_file
    # Mock the OpenapiSlicer instance
    slicer_mock = Minitest::Mock.new
    slicer_mock.expect(:export, nil, ['users.*', 'output.yaml'])
    OpenapiSlicer.stub(:new, slicer_mock) do
      argv = ['-i', 'input.yaml', '-r', 'users.*', '-o', 'output.yaml']
      cli = ::OpenapiSlicerCLI.new(argv)
      cli.run
      output = $stdout.string
      assert_match(/File created: output.yaml/, output)
    end
    slicer_mock.verify
  end

  def test_run_without_output_file
    # Mock the OpenapiSlicer instance
    slicer_mock = Minitest::Mock.new
    slicer_mock.expect(:filter, { data: 'filtered_data' }, ['users.*'])
    OpenapiSlicer.stub(:new, slicer_mock) do
      argv = ['-i', 'input.yaml', '-r', 'users.*']
      cli = ::OpenapiSlicerCLI.new(argv)
      cli.run
      output = $stdout.string
      assert_match(/:data=>"filtered_data"/, output)
    end
    slicer_mock.verify
  end
end
