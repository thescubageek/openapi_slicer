# frozen_string_literal: true

require "yaml"
require "json"
require "set"

class OpenapiSlicer
  VERSION = "0.1.0"

  attr_accessor :spec

  def initialize(file_path:)
    raise "Invalid file type. Only JSON and YAML are supported." unless file_path.match?(/\.(json|ya?ml)$/)

    @file_path = file_path
    @spec = load_spec(file_path)
    @components = {}
    @tags = Set.new
  end

  def filter(regex)
    paths = @spec["paths"].select { |path, _| path.match?(regex) }
    dependencies = extract_dependencies(paths)
    slice_spec(paths, dependencies)
  end

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

  # Load the OpenAPI spec from the file
  def load_spec(file_path)
    if file_path.end_with?(".json")
      JSON.parse(File.read(file_path))
    else
      YAML.load_file(file_path)
    end
  end

  # Extracts all component and tag dependencies from the filtered paths
  def extract_dependencies(paths)
    dependencies = Set.new
    paths.each_value do |operations|
      operations.each_value do |operation|
        extract_from_operation(operation, dependencies)
      end
    end
    dependencies
  end

  # Extracts $ref dependencies from a given operation
  def extract_from_operation(operation, dependencies)
    operation["parameters"]&.each { |param| resolve_ref(param["$ref"], dependencies) if param["$ref"] }
    operation["responses"]&.each_value do |response|
      resolve_response_refs(response, dependencies)
    end
    @tags.merge(operation["tags"]) if operation["tags"]
  end

  # Recursively resolves component references and adds to the dependency set
  def resolve_ref(ref, dependencies)
    return unless ref

    component = ref.split("/").last
    return if dependencies.include?(component)

    dependencies.add(component)
    component_data = @spec.dig("components", "schemas", component) ||
                     @spec.dig("components", "responses", component) ||
                     @spec.dig("components", "parameters", component) ||
                     @spec.dig("components", "requestBodies", component)

    return unless component_data

    if component_data["properties"]
      component_data["properties"].each_value do |property|
        resolve_ref(property["$ref"], dependencies) if property["$ref"]
      end
    end

    if component_data["allOf"]
      component_data["allOf"].each { |sub| resolve_ref(sub["$ref"], dependencies) if sub["$ref"] }
    end
  end

  # Recursively resolve response references
  def resolve_response_refs(response, dependencies)
    resolve_ref(response["$ref"], dependencies) if response["$ref"]
    response["content"]&.each_value do |media_type|
      resolve_ref(media_type.dig("schema", "$ref"), dependencies) if media_type.dig("schema", "$ref")
    end
  end

  # Slice the spec and keep only the filtered paths, dependencies, and tags
  def slice_spec(paths, dependencies)
    result = {
      "openapi" => @spec["openapi"],
      "info" => @spec["info"],
      "paths" => paths,
      "components" => slice_components(dependencies),
      "tags" => slice_tags
    }
    result["servers"] = @spec["servers"] if @spec["servers"]
    result
  end

  # Keep only the necessary components
  def slice_components(dependencies)
    sliced = {}
    %w[schemas responses parameters requestBodies].each do |type|
      next unless @spec["components"] && @spec["components"][type]

      sliced[type] = @spec["components"][type].select { |name, _| dependencies.include?(name) }
    end
    sliced
  end

  # Keep only the necessary tags
  def slice_tags
    @spec["tags"]&.select { |tag| @tags.include?(tag["name"]) }
  end
end
