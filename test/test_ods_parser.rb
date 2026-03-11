# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/ods_parser"

class TestOdsParser < Minitest::Test
  ODS_PATH = File.join(FIXTURES_DIR, "test.ods")

  def test_sheet_names
    names = OdsParser.sheet_names(ODS_PATH)
    assert_equal ["TestSheet"], names
  end

  def test_parse_returns_hash_of_sheets
    result = OdsParser.parse(ODS_PATH)
    assert_instance_of Hash, result
    assert_includes result, "TestSheet"
  end

  def test_parse_reads_header_and_data_rows
    rows = OdsParser.parse(ODS_PATH)["TestSheet"]
    assert_equal %w[id name], rows[0]
    assert_equal %w[1 hello], rows[1]
    assert_equal %w[2 world], rows[2]
  end

  def test_parse_prefers_office_value_for_numeric_cells
    rows = OdsParser.parse(ODS_PATH)["TestSheet"]
    # office:value="1" should be used instead of text content
    assert_equal "1", rows[1][0]
  end

  def test_parse_skips_bulk_empty_rows
    rows = OdsParser.parse(ODS_PATH)["TestSheet"]
    # The fixture has 1000 repeated empty rows that should be skipped
    assert_equal 3, rows.size
  end

  def test_parse_filters_by_sheet_names
    result = OdsParser.parse(ODS_PATH, sheets: ["NonExistent"])
    refute_includes result, "TestSheet"
  end
end
