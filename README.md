
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

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/yourusername/openapi_slicer](https://github.com/yourusername/openapi_slicer). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/yourusername/openapi_slicer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OpenAPI Slicer project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/yourusername/openapi_slicer/blob/main/CODE_OF_CONDUCT.md).
