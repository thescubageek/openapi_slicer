# test_open_api_slicer.rb

# frozen_string_literal: true

require "test_helper"
require "json"
require "yaml"
require_relative "../lib/openapi_slicer"

class OpenapiSlicerTest < Minitest::Test
  def setup
    # Create mock OpenAPI spec in both JSON and YAML format for testing
    @mock_spec = {
      "openapi" => "3.0.0",
      "info" => { "title" => "Test API", "version" => "1.0.0" },
      "paths" => {
        "/pets" => {
          "get" => {
            "tags" => ["Pets"],
            "responses" => {
              "200" => {
                "description" => "A list of pets",
                "content" => {
                  "application/json" => {
                    "schema" => { "$ref" => "#/components/schemas/Pet" }
                  }
                }
              }
            }
          }
        },
        "/pets/{petId}" => {
          "get" => {
            "tags" => ["Pets"],
            "parameters" => [
              { "$ref" => "#/components/parameters/PetId" }
            ],
            "responses" => {
              "200" => {
                "description" => "A pet",
                "content" => {
                  "application/json" => {
                    "schema" => { "$ref" => "#/components/schemas/Pet" }
                  }
                }
              }
            }
          }
        },
        "/pets/{petId}/health" => {
          "get" => {
            "tags" => ["Pets"],
            "parameters" => [
              { "$ref" => "#/components/parameters/PetId" }
            ],
            "responses" => {
              "200" => {
                "description" => "Pet health status",
                "content" => {
                  "application/json" => {
                    "schema" => { "type" => "string" }
                  }
                }
              }
            }
          }
        }
      },
      "components" => {
        "schemas" => {
          "Pet" => {
            "type" => "object",
            "properties" => {
              "id" => { "type" => "integer" },
              "name" => { "type" => "string" }
            }
          }
        },
        "parameters" => {
          "PetId" => {
            "name" => "petId",
            "in" => "path",
            "required" => true,
            "schema" => { "type" => "integer" }
          }
        }
      },
      "tags" => [{ "name" => "Pets", "description" => "Operations about pets" }]
    }

    # Save the mock spec to files
    File.write("test_spec.json", @mock_spec.to_json)
    File.write("test_spec.yaml", @mock_spec.to_yaml)
  end

  def teardown
    # Clean up the created files
    File.delete("test_spec.json")
    File.delete("test_spec.yaml")
    File.delete("sliced_spec.json") if File.exist?("sliced_spec.json")
    File.delete("sliced_spec.yaml") if File.exist?("sliced_spec.yaml")
  end

  def test_initialize_raises_error_on_invalid_file_type
    assert_raises(RuntimeError) do
      ::OpenapiSlicer.new(file_path: "invalid.txt")
    end
  end

  def test_initialize_loads_valid_json_file
    slicer = ::OpenapiSlicer.new(file_path: "test_spec.json")
    assert_equal "3.0.0", slicer.spec["openapi"]
    assert_equal "Test API", slicer.spec["info"]["title"]
  end

  def test_initialize_loads_valid_yaml_file
    slicer = ::OpenapiSlicer.new(file_path: "test_spec.yaml")
    assert_equal "3.0.0", slicer.spec["openapi"]
    assert_equal "Test API", slicer.spec["info"]["title"]
  end

  def test_filter_slices_paths_and_dependencies_matching_regex
    slicer = ::OpenapiSlicer.new(file_path: "test_spec.json")
    result = slicer.filter(%r{^/pets})

    assert_includes result["paths"], "/pets"
    assert_includes result["paths"], "/pets/{petId}"
    assert_includes result["paths"], "/pets/{petId}/health"
    assert_includes result["components"]["schemas"], "Pet"
    assert_includes result["components"]["parameters"], "PetId"
    assert_includes result["tags"].map { |tag| tag["name"] }, "Pets"
  end

  def test_filter_returns_only_nested_paths_under_pets_petid
    slicer = ::OpenapiSlicer.new(file_path: "test_spec.json")
    result = slicer.filter(%r{^/pets/\{petId\}})

    assert_includes result["paths"], "/pets/{petId}"
    assert_includes result["paths"], "/pets/{petId}/health"
    assert_equal 2, result["paths"].size
    assert_includes result["components"]["schemas"], "Pet"
    assert_includes result["components"]["parameters"], "PetId"
  end

  def test_filter_returns_empty_result_for_non_matching_paths
    slicer = ::OpenapiSlicer.new(file_path: "test_spec.json")
    result = slicer.filter(%r{^/nonexistent})

    assert_empty result["paths"]
    assert_empty result["components"]["schemas"]
    assert_empty result["components"]["parameters"]
    assert_empty result["tags"]
  end

  def test_export_correctly_exports_filtered_spec_to_json
    slicer = ::OpenapiSlicer.new(file_path: "test_spec.json")
    slicer.export(%r{^/pets}, "sliced_spec.json")

    sliced_spec = JSON.parse(File.read("sliced_spec.json"))
    assert_includes sliced_spec["paths"], "/pets"
    assert_includes sliced_spec["paths"], "/pets/{petId}"
    assert_includes sliced_spec["paths"], "/pets/{petId}/health"
    assert_includes sliced_spec["components"]["schemas"], "Pet"
    assert_includes sliced_spec["components"]["parameters"], "PetId"
    assert_includes sliced_spec["tags"].map { |tag| tag["name"] }, "Pets"
  end

  def test_export_correctly_exports_filtered_spec_to_yaml
    slicer = ::OpenapiSlicer.new(file_path: "test_spec.yaml")
    slicer.export(%r{^/pets}, "sliced_spec.yaml")

    sliced_spec = YAML.load_file("sliced_spec.yaml")
    assert_includes sliced_spec["paths"], "/pets"
    assert_includes sliced_spec["paths"], "/pets/{petId}"
    assert_includes sliced_spec["paths"], "/pets/{petId}/health"
    assert_includes sliced_spec["components"]["schemas"], "Pet"
    assert_includes sliced_spec["components"]["parameters"], "PetId"
    assert_includes sliced_spec["tags"].map { |tag| tag["name"] }, "Pets"
  end
end
