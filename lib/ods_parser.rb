# frozen_string_literal: true

require "zip"
require "rexml/document"

# Parses ODS (OpenDocument Spreadsheet) files.
# ODS is a ZIP archive containing content.xml with table data.
module OdsParser
  TABLE_NS = "urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  OFFICE_NS = "urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  TEXT_NS = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"

  module_function

  # Parse an ODS file. Returns a hash of { sheet_name => [rows] }.
  # Each row is an array of string values.
  def parse(ods_path, sheets: nil)
    xml = read_content_xml(ods_path)
    doc = REXML::Document.new(xml)

    result = {}
    doc.each_element("//table:table") do |table|
      name = table.attributes["table:name"]
      next if sheets && !sheets.include?(name)

      result[name] = parse_table(table)
    end
    result
  end

  # Parse and return sheet names only.
  def sheet_names(ods_path)
    xml = read_content_xml(ods_path)
    doc = REXML::Document.new(xml)
    names = []
    doc.each_element("//table:table") do |table|
      names << table.attributes["table:name"]
    end
    names
  end

  def read_content_xml(ods_path)
    Zip::File.open(ods_path) do |zip|
      entry = zip.find_entry("content.xml")
      raise "No content.xml found in #{ods_path}" unless entry

      entry.get_input_stream.read
    end
  end

  def parse_table(table)
    rows = []
    table.each_element("table:table-row") do |row_el|
      row_repeat = (row_el.attributes["table:number-rows-repeated"] || "1").to_i
      row = parse_row(row_el)

      # Skip bulk empty rows (ODS often ends with thousands of repeated empty rows)
      if row_repeat > 100 && row.all?(&:empty?)
        next
      end

      row_repeat.times { rows << row.dup }
    end
    rows
  end

  def parse_row(row_el)
    cells = []
    row_el.each_element("table:table-cell") do |cell_el|
      repeat = (cell_el.attributes["table:number-columns-repeated"] || "1").to_i

      # Prefer office:value for numeric cells (contains IDs), fall back to text
      value = cell_el.attributes["office:value"]
      unless value
        value = extract_text(cell_el)
      end

      # Skip bulk trailing empty cells
      if repeat > 100 && (value.nil? || value.empty?)
        next
      end

      repeat.times { cells << (value || "") }
    end
    cells
  end

  def extract_text(cell_el)
    texts = []
    cell_el.each_element("text:p") do |p|
      texts << collect_text(p)
    end
    texts.join("\n")
  end

  # Recursively collect all text content from an element.
  def collect_text(element)
    result = +""
    element.each do |node|
      case node
      when REXML::Text
        result << node.value
      when REXML::Element
        result << collect_text(node)
      end
    end
    result
  end
end
