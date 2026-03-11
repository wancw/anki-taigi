# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/anki_exporter"

class TestAnkiExporter < Minitest::Test
  def setup
    @dict = TaigiDict::Dictionary.from_csv(FIXTURES_DIR)
    @cards = @dict.build_cards
  end

  def test_export_creates_file
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "deck.txt")
      AnkiExporter.export(@cards, output_path: path)
      assert File.exist?(path)
    end
  end

  def test_export_includes_header
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "deck.txt")
      AnkiExporter.export(@cards, output_path: path)
      lines = File.readlines(path, chomp: true)
      assert_match(/^#separator:tab/, lines[0])
      assert_match(/^#html:true/, lines[1])
    end
  end

  def test_export_line_count_matches_definitions
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "deck.txt")
      AnkiExporter.export(@cards, output_path: path)
      lines = File.readlines(path, chomp: true)
      header_lines = lines.count { |l| l.start_with?("#") }
      data_lines = lines.size - header_lines
      total_defs = @cards.sum { |c| c.definitions.size }
      assert_equal total_defs, data_lines
    end
  end

  def test_clean_hanji_removes_marker
    assert_equal "一", AnkiExporter.clean_hanji("一【替】")
  end

  def test_clean_hanji_preserves_normal_text
    assert_equal "食飯", AnkiExporter.clean_hanji("食飯")
  end

  def test_sound_tag
    assert_equal "[sound:sutiau-1(1).mp3]", AnkiExporter.sound_tag("1(1)", prefix: "sutiau-", ext: ".mp3")
  end

  def test_sound_tag_empty_filename
    assert_equal "", AnkiExporter.sound_tag("", prefix: "sutiau-", ext: ".mp3")
    assert_equal "", AnkiExporter.sound_tag(nil, prefix: "sutiau-", ext: ".mp3")
  end

  def test_build_tags
    assert_equal "性質、程度 數詞、量詞", AnkiExporter.build_tags("性質、程度,數詞、量詞")
  end

  def test_build_tags_empty
    assert_equal "", AnkiExporter.build_tags("")
    assert_equal "", AnkiExporter.build_tags(nil)
  end

  def test_escape_field
    assert_equal "a b", AnkiExporter.escape_field("a\nb")
    assert_equal "a b", AnkiExporter.escape_field("a\tb")
  end
end
