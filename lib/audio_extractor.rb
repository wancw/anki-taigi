# frozen_string_literal: true

require "zip"
require "fileutils"

# Extracts MP3 audio files from MOE zip archives into Anki media-friendly layout.
module AudioExtractor
  module_function

  # Extract MP3 files from a zip archive into dest_dir.
  # Returns the number of files extracted.
  def extract(zip_path, dest_dir:, prefix: nil)
    FileUtils.mkdir_p(dest_dir)

    count = 0
    Zip::File.open(zip_path) do |zip|
      zip.each do |entry|
        next if entry.directory?
        next unless entry.name.end_with?(".mp3")

        basename = File.basename(entry.name)
        basename = "#{prefix}#{basename}" if prefix
        out_path = File.join(dest_dir, basename)

        unless File.exist?(out_path)
          entry.extract(out_path)
        end
        count += 1
      end
    end
    count
  end
end
