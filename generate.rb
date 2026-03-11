#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/moe_fetcher"
require_relative "lib/ods_parser"
require_relative "lib/taigi_dict"
require_relative "lib/anki_exporter"
require_relative "lib/audio_extractor"

DATA_DIR = "data"
CSV_DIR = "data/csv"
AUDIO_DIR = "output/audio"
OUTPUT_FILE = "output/taigi_deck.txt"

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

# Step 4: Build and export Anki deck
puts "\n=== Step 4: Generate Anki deck ==="
cards = dict.build_cards
puts "  Cards: #{cards.size}"

total_lines = cards.sum { |c| c.definitions.size }
AnkiExporter.export(cards, output_path: OUTPUT_FILE)
puts "  Exported #{total_lines} notes to #{OUTPUT_FILE}"

# Step 5: Extract audio
puts "\n=== Step 5: Extract audio files ==="
n1 = AudioExtractor.extract(entries_zip, dest_dir: AUDIO_DIR, prefix: "sutiau-")
puts "  Entry audio:   #{n1} files"
n2 = AudioExtractor.extract(examples_zip, dest_dir: AUDIO_DIR, prefix: "leku-")
puts "  Example audio: #{n2} files"

puts "\n=== Done! ==="
puts "1. Copy #{AUDIO_DIR}/*.mp3 to your Anki media folder"
puts "   (e.g., ~/.local/share/Anki2/<profile>/collection.media/)"
puts "2. Import #{OUTPUT_FILE} into Anki"
