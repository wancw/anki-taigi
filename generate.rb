#!/usr/bin/env ruby
# frozen_string_literal: true

# Shortcut to run the full pipeline: equivalent to `rake build`

require_relative "lib/version"
require_relative "lib/moe_fetcher"
require_relative "lib/ods_parser"
require_relative "lib/taigi_dict"
require_relative "lib/anki_exporter"
require_relative "lib/apkg_exporter"
require_relative "lib/audio_extractor"

DATA_DIR = "data"
CSV_DIR = "data/csv"
AUDIO_DIR = "output/audio"
OUTPUT_TXT = "output/taigi_deck.txt"
OUTPUT_APKG = "output/taigi.apkg"

puts "anki-taigi v#{VERSION}"
puts

# Step 1: Download
puts "=== Step 1: Fetch MOE open data ==="
ods_path = MoeFetcher.fetch(:dictionary, dest_dir: DATA_DIR)
entries_zip = MoeFetcher.fetch(:audio_entries_mp3, dest_dir: DATA_DIR)
examples_zip = MoeFetcher.fetch(:audio_examples_mp3, dest_dir: DATA_DIR)

# Step 2: Parse ODS
puts "\n=== Step 2: Parse dictionary ==="
dict = TaigiDict::Dictionary.from_ods(ods_path)
puts "  Entries:     #{dict.entries.size}"
puts "  Definitions: #{dict.definitions.size}"
puts "  Examples:    #{dict.examples.size}"

# Step 3: Cache as CSV
puts "\n=== Step 3: Export CSV cache ==="
dict.export_csv(CSV_DIR)
puts "  Saved to #{CSV_DIR}/"

# Step 4: Extract audio
puts "\n=== Step 4: Extract audio files ==="
n1 = AudioExtractor.extract(entries_zip, dest_dir: AUDIO_DIR, prefix: "sutiau-")
puts "  Entry audio:   #{n1} files"
n2 = AudioExtractor.extract(examples_zip, dest_dir: AUDIO_DIR, prefix: "leku-")
puts "  Example audio: #{n2} files"

# Step 5: Build cards and export
puts "\n=== Step 5: Build Anki deck ==="
cards = dict.build_cards
total_notes = cards.sum { |c| c.definitions.size }
puts "  Cards: #{cards.size} (#{total_notes} notes)"

AnkiExporter.export(cards, output_path: OUTPUT_TXT)
puts "  Exported TSV:  #{OUTPUT_TXT}"

ApkgExporter.export(cards, output_path: OUTPUT_APKG, audio_dir: AUDIO_DIR)
puts "  Exported APKG: #{OUTPUT_APKG}"

puts "\n=== Done! ==="
puts "Import #{OUTPUT_APKG} into Anki (File → Import)"
