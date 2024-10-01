# frozen_string_literal: true

require 'optparse'
require_relative '../lib/openapi_slicer'

# Command-line interface (CLI) for the OpenAPI Slicer.
# This class provides a way to interact with the OpenAPI Slicer via the command line,
# allowing users to filter and export portions of an OpenAPI specification based on a regular expression.
class OpenapiSlicerCLI
  # @return [Hash] the options passed from the command line, including input file path, regex, and output file path.
  attr_reader :options

  # Initializes the CLI with arguments passed from the command line.
  #
  # @param argv [Array<String>] the array of arguments passed from the command line.
  def initialize(argv)
    @argv = argv
    @options = {}
  end

  # Parses the command-line options using OptionParser.
  # It expects the following options:
  # - `-i`, `--input FILE`: The input OpenAPI file path (required).
  # - `-r`, `--regex REGEX`: The regular expression used for filtering paths in the OpenAPI spec (required).
  # - `-o`, `--output FILE`: The output file path to save the filtered result (optional).
  # - `-h`, `--help`: Displays usage help.
  def parse_options
    OptionParser.new do |opts|
      opts.banner = "Usage: openapi_slicer [options]"

      opts.on("-i", "--input FILE", "Input OpenAPI file path") do |file|
        options[:input_file] = file
      end

      opts.on("-r", "--regex REGEX", "Regex pattern for filtering") do |regex|
        options[:regex] = regex
      end

      opts.on("-o", "--output FILE", "Output file path") do |file|
        options[:output_file] = file
      end

      opts.on("-h", "--help", "Displays Help") do
        puts opts
        exit
      end
    end.parse!(@argv)
  end

  # Validates that the required options (`input_file` and `regex`) are provided.
  # If any required option is missing, an error message is displayed, and the script exits with a non-zero status.
  def validate_options
    %i[input_file regex].each do |opt|
      unless options[opt]
        puts "Missing option: --#{opt.to_s.gsub('_', '-')}"
        exit(1)
      end
    end
  end

  # Runs the CLI by parsing options, validating them, and invoking the OpenAPI Slicer.
  # Depending on whether an output file is specified, it either prints the filtered result to the console
  # or writes it to the output file.
  def run
    parse_options
    validate_options

    slicer = OpenapiSlicer.new(file_path: options[:input_file])
    if options[:output_file]
      slicer.export(options[:regex], options[:output_file])
      puts "File created: #{options[:output_file]}"
    else
      pp slicer.filter(options[:regex])
    end
  end
end

# If this script is run directly, execute the CLI.
if __FILE__ == $0
  cli = OpenapiSlicerCLI.new(ARGV)
  cli.run
end
