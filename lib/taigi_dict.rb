# frozen_string_literal: true

require "csv"
require_relative "ods_parser"

# Loads and joins MOE Taigi dictionary data.
module TaigiDict
  Entry = Data.define(:id, :type, :hanji, :lomaji, :categories, :audio_file)
  Definition = Data.define(:entry_id, :id, :part_of_speech, :explanation)
  Example = Data.define(:entry_id, :definition_id, :order, :hanji, :lomaji, :chinese, :audio_file)

  Card = Data.define(:entry, :definitions)
  DefinitionWithExamples = Data.define(:definition, :examples)

  SHEET_NAMES = {
    entries: "詞目",
    definitions: "義項",
    examples: "例句"
  }.freeze

  class Dictionary
    attr_reader :entries, :definitions, :examples

    def initialize(entries:, definitions:, examples:)
      @entries = entries
      @definitions = definitions
      @examples = examples
    end

    # Load from the ODS file directly.
    def self.from_ods(ods_path)
      puts "  Parsing ODS: #{ods_path}..."
      sheets = OdsParser.parse(ods_path, sheets: SHEET_NAMES.values)

      new(
        entries: parse_entries(sheets[SHEET_NAMES[:entries]]),
        definitions: parse_definitions(sheets[SHEET_NAMES[:definitions]]),
        examples: parse_examples(sheets[SHEET_NAMES[:examples]])
      )
    end

    # Load from pre-exported CSV files.
    def self.from_csv(data_dir)
      new(
        entries: load_csv_entries(File.join(data_dir, "sutiau.csv")),
        definitions: load_csv_definitions(File.join(data_dir, "gixiang.csv")),
        examples: load_csv_examples(File.join(data_dir, "lexku.csv"))
      )
    end

    # Build cards by joining entries, definitions, and examples.
    def build_cards
      defs_by_entry = @definitions.group_by(&:entry_id)
      examples_by_key = @examples.group_by { |ex| [ex.entry_id, ex.definition_id] }

      @entries.filter_map do |entry|
        entry_defs = defs_by_entry[entry.id]
        next unless entry_defs

        defs_with_examples = entry_defs.map do |defn|
          exs = examples_by_key[[entry.id, defn.id]] || []
          DefinitionWithExamples.new(definition: defn, examples: exs)
        end

        Card.new(entry: entry, definitions: defs_with_examples)
      end
    end

    # Export to CSV files for caching.
    def export_csv(dest_dir)
      require "fileutils"
      FileUtils.mkdir_p(dest_dir)

      CSV.open(File.join(dest_dir, "sutiau.csv"), "w:utf-8") do |csv|
        csv << %w[詞目id 詞目類型 漢字 羅馬字 分類 羅馬字音檔檔名]
        @entries.each { |e| csv << [e.id, e.type, e.hanji, e.lomaji, e.categories, e.audio_file] }
      end

      CSV.open(File.join(dest_dir, "gixiang.csv"), "w:utf-8") do |csv|
        csv << %w[詞目id 義項id 詞性 解說]
        @definitions.each { |d| csv << [d.entry_id, d.id, d.part_of_speech, d.explanation] }
      end

      CSV.open(File.join(dest_dir, "lexku.csv"), "w:utf-8") do |csv|
        csv << %w[詞目id 義項id 例句順序 漢字 羅馬字 華語 音檔檔名]
        @examples.each { |e| csv << [e.entry_id, e.definition_id, e.order, e.hanji, e.lomaji, e.chinese, e.audio_file] }
      end
    end

    class << self
      private

      # --- ODS row parsers (row[0] is header, data starts at row[1]) ---

      def parse_entries(rows)
        rows[1..].map do |row|
          Entry.new(
            id: row[0], type: row[1], hanji: row[2],
            lomaji: row[3], categories: row[4], audio_file: row[5]
          )
        end
      end

      def parse_definitions(rows)
        rows[1..].map do |row|
          Definition.new(
            entry_id: row[0], id: row[1],
            part_of_speech: row[2], explanation: row[3]
          )
        end
      end

      def parse_examples(rows)
        rows[1..].map do |row|
          Example.new(
            entry_id: row[0], definition_id: row[1], order: row[2],
            hanji: row[3], lomaji: row[4], chinese: row[5], audio_file: row[6]
          )
        end
      end

      # --- CSV loaders ---

      def load_csv_entries(path)
        CSV.foreach(path, headers: true).map do |row|
          Entry.new(
            id: row["詞目id"], type: row["詞目類型"], hanji: row["漢字"],
            lomaji: row["羅馬字"], categories: row["分類"], audio_file: row["羅馬字音檔檔名"]
          )
        end
      end

      def load_csv_definitions(path)
        CSV.foreach(path, headers: true).map do |row|
          Definition.new(
            entry_id: row["詞目id"], id: row["義項id"],
            part_of_speech: row["詞性"], explanation: row["解說"]
          )
        end
      end

      def load_csv_examples(path)
        CSV.foreach(path, headers: true).map do |row|
          Example.new(
            entry_id: row["詞目id"], definition_id: row["義項id"], order: row["例句順序"],
            hanji: row["漢字"], lomaji: row["羅馬字"], chinese: row["華語"], audio_file: row["音檔檔名"]
          )
        end
      end
    end
  end
end
