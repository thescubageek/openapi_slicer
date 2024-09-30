# frozen_string_literal

require 'optparse'
require_relative '../lib/openapi_slicer'

class OpenapiSlicerCLI
  attr_reader :options

  def initialize(argv)
    @argv = argv
    @options = {}
  end

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

  def validate_options
    %i[input_file regex].each do |opt|
      unless options[opt]
        puts "Missing option: --#{opt.to_s.gsub('_', '-')}"
        exit(1)
      end
    end
  end

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

# Run the CLI if this file is executed directly
if __FILE__ == $0
  cli = OpenapiSlicerCLI.new(ARGV)
  cli.run
end
