Gem::Specification.new do |spec|
  spec.name          = "openapi-slicer"
  spec.version       = "0.1.0"
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]
  spec.summary       = "A tool to slice OpenAPI specs based on regular expressions"
  spec.description   = "OpenApiSlicer allows you to slice OpenAPI specs, selecting paths and their dependencies based on regular expressions."
  spec.homepage      = "https://example.com/openapi-slicer"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "test/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
end
