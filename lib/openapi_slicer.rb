# frozen_string_literal: true

require "yaml"
require "json"
require "set"

# OpenapiSlicer is a tool that slices an OpenAPI spec based on a regular expression,
# and filters out necessary paths and components, ensuring that all dependent components
# (schemas, parameters, etc.) are included.
class OpenapiSlicer
  # The current version of the OpenapiSlicer
  VERSION = "0.1.1"

  # @return [Hash] the OpenAPI specification loaded from the file
  attr_accessor :spec

  # Initializes the OpenapiSlicer.
  #
  # @param file_path [String] the path to the OpenAPI spec file (JSON or YAML)
  # @raise [RuntimeError] if the file is not a JSON or YAML file
  def initialize(file_path:)
    raise "Invalid file type. Only JSON and YAML are supported." unless file_path.match?(/\.(json|ya?ml)$/)

    @file_path = file_path
    @spec = load_spec(file_path)
    @components = {}
    @tags = Set.new
  end

  # Filters the OpenAPI spec paths based on a regular expression and extracts the
  # necessary components and tags.
  #
  # @param regex [Regexp] the regular expression to match against the paths
  # @return [Hash] the filtered OpenAPI spec with paths and dependencies
  def filter(regex)
    paths = @spec["paths"].select { |path, _| path.match?(regex) }
    dependencies = extract_dependencies(paths)
    slice_spec(paths, dependencies)
  end

  # Exports the filtered OpenAPI spec to a file.
  #
  # @param regex [Regexp] the regular expression to match against the paths
  # @param target_file [String] the file path to write the filtered spec to
  def export(regex, target_file)
    result = filter(regex)
    File.open(target_file, "w") do |f|
      if target_file.match?(/\.json$/)
        f.write(result.to_json)
      else
        f.write(result.to_yaml)
      end
    end
  end

  private

  # Loads the OpenAPI spec from the file.
  #
  # @param file_path [String] the path to the OpenAPI spec file
  # @return [Hash] the loaded OpenAPI spec
  def load_spec(file_path)
    if file_path.end_with?(".json")
      JSON.parse(File.read(file_path))
    else
      YAML.load_file(file_path)
    end
  end

  # Extracts all component and tag dependencies from the filtered paths.
  #
  # @param paths [Hash] the filtered OpenAPI paths
  # @return [Set] a set of dependencies found in the paths
  def extract_dependencies(paths)
    dependencies = Set.new
    paths.each_value do |operations|
      operations.each_value do |operation|
        extract_from_operation(operation, dependencies)
      end
    end
    dependencies
  end

  # Extracts $ref dependencies from a given operation.
  #
  # @param operation [Hash] the operation to extract dependencies from
  # @param dependencies [Set] the set to store discovered dependencies
  def extract_from_operation(operation, dependencies)
    operation["parameters"]&.each { |param| resolve_ref(param["$ref"], dependencies) if param["$ref"] }
    operation["responses"]&.each_value do |response|
      resolve_response_refs(response, dependencies)
    end
    @tags.merge(operation["tags"]) if operation["tags"]
  end

  # Resolves component references recursively and adds them to the dependency set.
  #
  # @param ref [String] the $ref string pointing to a component
  # @param dependencies [Set] the set to store discovered dependencies
  def resolve_ref(ref, dependencies)
    return unless ref

    component = ref.split("/").last
    return if dependencies.include?(component)

    dependencies.add(component)

    component_data = slice_component_data(component)
    return unless component_data

    resolve_component_property_refs(component_data, dependencies)
    resolve_nested_refs(component_data, dependencies)
  end

  # Resolves response references recursively.
  #
  # @param response [Hash] the response object to resolve references from
  # @param dependencies [Set] the set to store discovered dependencies
  def resolve_response_refs(response, dependencies)
    resolve_ref(response["$ref"], dependencies) if response["$ref"]
    response["content"]&.each_value do |media_type|
      resolve_ref(media_type.dig("schema", "$ref"), dependencies) if media_type.dig("schema", "$ref")
    end
  end

  # Resolves references based on component properties
  #
  # @param component_data [Hash] component spec data
  # @param dependencies []
  def resolve_component_property_refs(component_data, dependencies)
    return unless component_data&.[]("properties")

    component_data["properties"].each_value do |property|
      resolve_ref(property["$ref"], dependencies) if property["$ref"]
    end
  end


  # Resolves references based on component properties
  #
  # @param component_data [Hash] component spec data
  # @param dependencies []
  def resolve_nested_refs(component_data, dependencies)
    return unless component_data&.[]("allOf")

    component_data["allOf"].each { |sub| resolve_ref(sub["$ref"], dependencies) if sub["$ref"] }
  end

  # Slices the component data from the specs
  #
  # @param component [String] component name
  # @return [Hash|nil] component data from the specs
  def slice_component_data(component)
    @spec.dig("components", "schemas", component) ||
      @spec.dig("components", "responses", component) ||
      @spec.dig("components", "parameters", component) ||
      @spec.dig("components", "requestBodies", component)
  end

  # Slices the spec, keeping only the filtered paths, components, and tags.
  #
  # @param paths [Hash] the filtered paths
  # @param dependencies [Set] the set of component dependencies
  # @return [Hash] the sliced OpenAPI spec
  def slice_spec(paths, dependencies)
    result = {
      "openapi"    => @spec["openapi"],
      "info"       => @spec["info"],
      "paths"      => paths,
      "components" => slice_components(dependencies),
      "tags"       => slice_tags
    }
    result["servers"] = @spec["servers"] if @spec["servers"]
    result
  end

  # Slices and retains only the necessary components.
  #
  # @param dependencies [Set] the set of component dependencies
  # @return [Hash] the sliced components
  def slice_components(dependencies)
    sliced = {}
    %w[schemas responses parameters requestBodies].each do |type|
      next unless @spec["components"] && @spec["components"][type]

      sliced[type] = @spec["components"][type].select { |name, _| dependencies.include?(name) }
    end
    sliced
  end

  # Slices and retains only the necessary tags.
  #
  # @return [Array] the sliced tags
  def slice_tags
    @spec["tags"]&.select { |tag| @tags.include?(tag["name"]) }
  end
end
