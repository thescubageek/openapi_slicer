Gem::Specification.new do |spec|
  spec.name          = "openapi_slicer"
  spec.version       = "0.1.0"
  spec.authors       = ["TheScubaGeek"]
  spec.summary       = "A tool to slice OpenAPI specs based on regular expressions"
  spec.description   = "OpenapiSlicer allows you to slice OpenAPI specs, selecting paths and their dependencies based on regular expressions."
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "scripts/**/*","test/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
end
