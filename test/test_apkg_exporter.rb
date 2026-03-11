# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/apkg_exporter"

class TestApkgExporter < Minitest::Test
  def setup
    @dict = TaigiDict::Dictionary.from_csv(FIXTURES_DIR)
    @cards = @dict.build_cards
  end

  def test_export_creates_valid_zip
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "test.apkg")
      ApkgExporter.export(@cards, output_path: path)

      assert File.exist?(path)
      Zip::File.open(path) do |zip|
        assert zip.find_entry("collection.anki2")
        assert zip.find_entry("media")
      end
    end
  end

  def test_export_contains_correct_note_count
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "test.apkg")
      ApkgExporter.export(@cards, output_path: path)

      db_content = Zip::File.open(path) { |z| z.read("collection.anki2") }
      db_path = File.join(tmpdir, "collection.anki2")
      File.binwrite(db_path, db_content)

      db = SQLite3::Database.new(db_path)
      note_count = db.get_first_value("SELECT count(*) FROM notes")
      card_count = db.get_first_value("SELECT count(*) FROM cards")
      db.close

      total_defs = @cards.sum { |c| c.definitions.size }
      assert_equal total_defs, note_count
      assert_equal total_defs, card_count
    end
  end

  def test_export_media_map_is_valid_json
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "test.apkg")
      ApkgExporter.export(@cards, output_path: path)

      media_json = Zip::File.open(path) { |z| z.read("media") }
      media = JSON.parse(media_json)
      assert_instance_of Hash, media
    end
  end

  def test_guid64_returns_string
    guid = ApkgExporter.guid64
    assert_instance_of String, guid
    assert guid.length >= 1
  end

  def test_guid64_is_unique
    guids = 100.times.map { ApkgExporter.guid64 }
    assert_equal 100, guids.uniq.size
  end

  def test_checksum_returns_integer
    csum = ApkgExporter.checksum("食飯")
    assert_instance_of Integer, csum
  end

  def test_checksum_strips_html
    plain = ApkgExporter.checksum("hello")
    html = ApkgExporter.checksum("<b>hello</b>")
    assert_equal plain, html
  end

  def test_register_audio_deduplicates
    media_map = {}
    _, idx = ApkgExporter.register_audio("1(1)", "sutiau-", nil, media_map, 0)
    _, idx = ApkgExporter.register_audio("1(1)", "sutiau-", nil, media_map, idx)
    _, idx = ApkgExporter.register_audio("2(1)", "sutiau-", nil, media_map, idx)

    assert_equal 2, media_map.size
    assert_equal "sutiau-1(1).mp3", media_map["0"]
    assert_equal "sutiau-2(1).mp3", media_map["1"]
  end

  def test_register_audio_nil_filename
    media_map = {}
    ref, idx = ApkgExporter.register_audio(nil, "sutiau-", nil, media_map, 0)
    assert_nil ref
    assert_equal 0, idx
  end

  def test_build_tags_with_leading_trailing_spaces
    tags = ApkgExporter.build_tags("生活起居")
    assert_match(/^ .+ $/, tags)
  end
end
