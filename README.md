
# OpenAPI Slicer

`openapi_slicer` is a Ruby gem designed to extract specific parts of an OpenAPI specification (either in JSON or YAML format) based on a regular expression. It slices paths from the spec that match the given regex and ensures that all necessary tag and component dependencies are included in the result. You can export the filtered OpenAPI spec to a file in JSON or YAML format.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openapi_slicer'
```

Then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install openapi_slicer
```

## Usage

### Initializing the Slicer

First, initialize an `OpenapiSlicer` instance by providing the path to a JSON or YAML OpenAPI spec file.

```ruby
require 'openapi_slicer'

slicer = OpenapiSlicer.new(file_path: 'path/to/openapi_spec.yaml')
```

### Filtering by Paths

To filter the OpenAPI spec based on a regular expression, use the `filter` method:

```ruby
# Filter the spec for all paths under '/pets'
filtered_spec = slicer.filter(%r{^/pets})
```

This will return a new spec that contains only the paths that match `/pets`, along with all the necessary components, tags, and other dependencies.

### Exporting the Filtered Spec

You can also directly export the filtered spec to a file using the `export` method:

```ruby
# Export the filtered spec to a new JSON file
slicer.export(%r{^/pets}, 'filtered_spec.json')

# Or export to a YAML file
slicer.export(%r{^/pets}, 'filtered_spec.yaml')
```

### Example

Suppose you have the following paths in your OpenAPI spec:

- `/pets`
- `/pets/{petId}`
- `/pets/{petId}/health`
- `/owners/{ownerId}`

Using the `filter` method, you can slice out only the paths under `/pets`:

```ruby
filtered_spec = slicer.filter(%r{^/pets})
```

This will return a spec containing:
- `/pets`
- `/pets/{petId}`
- `/pets/{petId}/health`

Any necessary `$ref` components or tag dependencies will also be included in the filtered spec.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run the tests using:

```bash
rake test
```

To install this gem onto your local machine, run:

```bash
bundle exec rake install
```


## Command-Line Interface (CLI)

To use the CLI, run the `ruby scripts/openapi_slicer` command with the following options:

- `-i`, `--input FILE`: **Required.** The path to the input OpenAPI specification file (in JSON or YAML format).
- `-r`, `--regex REGEX`: **Required.** A regular expression used to filter the paths from the OpenAPI file.
- `-o`, `--output FILE`: (Optional) The path where the filtered output will be saved. If not provided, the filtered result will be printed to the console.
- `-h`, `--help`: Displays help information for the available options.

### Example

Filter an OpenAPI spec file and print the result to the console:
```bash
ruby scripts/openapi_slicer -i openapi.json -r '/api/v1/users'
```

Filter an OpenAPI spec file and save the result to an output file:
```bash
ruby scripts/openapi_slicer -i openapi.json -r '/api/v1/users' -o filtered_spec.json
```

If required options are missing, the CLI will display an error message and terminate.


## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/thescubageek/openapi_slicer](https://github.com/thescubageek/openapi_slicer).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
