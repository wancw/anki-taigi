# frozen_string_literal: true

require "rake/testtask"
require_relative "lib/version"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/test_*.rb"]
end

DATA_DIR = "data"
CSV_DIR = "data/csv"
AUDIO_DIR = "output/audio"
OUTPUT_TXT = "output/taigi_deck.txt"
OUTPUT_APKG = "output/taigi.apkg"

ODS_PATH = File.join(DATA_DIR, "kautian.ods")
ENTRIES_ZIP = File.join(DATA_DIR, "sutiau-mp3.zip")
EXAMPLES_ZIP = File.join(DATA_DIR, "leku-mp3.zip")

desc "Download dictionary and audio from MOE"
task :fetch do
  require_relative "lib/moe_fetcher"

  puts "=== Fetch MOE open data ==="
  MoeFetcher.fetch(:dictionary, dest_dir: DATA_DIR)
  MoeFetcher.fetch(:audio_entries_mp3, dest_dir: DATA_DIR)
  MoeFetcher.fetch(:audio_examples_mp3, dest_dir: DATA_DIR)
end

desc "Parse ODS and cache as CSV"
task parse: :fetch do
  require_relative "lib/taigi_dict"

  puts "\n=== Parse dictionary ==="
  dict = TaigiDict::Dictionary.from_ods(ODS_PATH)
  puts "  Entries:     #{dict.entries.size}"
  puts "  Definitions: #{dict.definitions.size}"
  puts "  Examples:    #{dict.examples.size}"

  puts "\n=== Export CSV cache ==="
  dict.export_csv(CSV_DIR)
  puts "  Saved to #{CSV_DIR}/"
end

desc "Extract MP3 audio files from zip archives"
task audio: :fetch do
  require_relative "lib/audio_extractor"

  puts "\n=== Extract audio files ==="
  n1 = AudioExtractor.extract(ENTRIES_ZIP, dest_dir: AUDIO_DIR, prefix: "sutiau-")
  puts "  Entry audio:   #{n1} files"
  n2 = AudioExtractor.extract(EXAMPLES_ZIP, dest_dir: AUDIO_DIR, prefix: "leku-")
  puts "  Example audio: #{n2} files"
end

desc "Rebuild Anki deck from cached CSV and audio (skip fetch/parse)"
task :export do
  require_relative "lib/taigi_dict"
  require_relative "lib/anki_exporter"
  require_relative "lib/apkg_exporter"

  puts "\n=== Build Anki deck from CSV cache ==="
  dict = TaigiDict::Dictionary.from_csv(CSV_DIR)
  cards = dict.build_cards
  total_notes = cards.sum { |c| c.definitions.size }
  puts "  Cards: #{cards.size} (#{total_notes} notes)"

  AnkiExporter.export(cards, output_path: OUTPUT_TXT)
  puts "  Exported TSV:  #{OUTPUT_TXT}"

  audio_dir = Dir.exist?(AUDIO_DIR) ? AUDIO_DIR : nil
  ApkgExporter.export(cards, output_path: OUTPUT_APKG, audio_dir: audio_dir)
  puts "  Exported APKG: #{OUTPUT_APKG}"
end

desc "Run full pipeline: fetch, parse, extract audio, export"
task build: [:fetch, :parse, :audio, :export]

desc "Remove output files"
task :clean do
  rm_rf "output"
  puts "Cleaned output/"
end

desc "Remove output and downloaded data files"
task :clobber do
  rm_rf "output"
  rm_rf "data"
  puts "Cleaned output/ and data/"
end

task default: :build
