# frozen_string_literal: true

require_relative "taigi_dict"

# Exports TaigiDict cards to Anki-importable tab-separated text file.
module AnkiExporter
  SEPARATOR = "\t"
  FIELD_SEPARATOR = "<br>"

  module_function

  # Export cards to a tab-separated file importable by Anki.
  # Fields: hanji, lomaji, part_of_speech, explanation, examples_hanji,
  #         examples_lomaji, examples_chinese, categories, entry_audio, example_audio, tags
  def export(cards, output_path: "output/taigi_deck.txt")
    dir = File.dirname(output_path)
    Dir.mkdir(dir) unless Dir.exist?(dir)

    File.open(output_path, "w:utf-8") do |f|
      f.puts header_comment
      cards.each do |card|
        card.definitions.each do |dwe|
          f.puts build_line(card.entry, dwe)
        end
      end
    end
  end

  def header_comment
    <<~HEADER.chomp
      #separator:tab
      #html:true
      #columns:漢字\t羅馬字\t詞性\t解說\t例句漢字\t例句羅馬字\t例句華語\t分類\t詞目音檔\t例句音檔\t標籤
      #tags column:11
    HEADER
  end

  def build_line(entry, dwe)
    defn = dwe.definition
    examples = dwe.examples

    hanji = clean_hanji(entry.hanji)
    example_hanji = examples.map(&:hanji).join(FIELD_SEPARATOR)
    example_lomaji = examples.map(&:lomaji).join(FIELD_SEPARATOR)
    example_chinese = examples.map(&:chinese).join(FIELD_SEPARATOR)

    # Anki [sound:] tags for audio
    entry_audio = sound_tag(entry.audio_file, prefix: "sutiau-", ext: ".mp3")
    example_audios = examples.filter_map { |ex|
      sound_tag(ex.audio_file, prefix: "leku-", ext: ".mp3")
    }.join(" ")

    tags = build_tags(entry.categories)

    fields = [
      hanji,
      entry.lomaji,
      defn.part_of_speech,
      defn.explanation,
      example_hanji,
      example_lomaji,
      example_chinese,
      entry.categories,
      entry_audio,
      example_audios,
      tags
    ]

    fields.map { |f| escape_field(f) }.join(SEPARATOR)
  end

  def sound_tag(filename, prefix:, ext:)
    return "" if filename.nil? || filename.empty?

    "[sound:#{prefix}#{filename}#{ext}]"
  end

  def clean_hanji(hanji)
    hanji&.gsub(/【替】/, "") || ""
  end

  def build_tags(categories)
    (categories || "").split(",").map { |c| c.strip.gsub(" ", "_") }.join(" ")
  end

  def escape_field(value)
    (value || "").gsub("\n", " ").gsub("\t", " ")
  end
end
