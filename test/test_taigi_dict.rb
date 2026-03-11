# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/taigi_dict"

class TestTaigiDict < Minitest::Test
  def setup
    @dict = TaigiDict::Dictionary.from_csv(FIXTURES_DIR)
  end

  def test_loads_entries
    assert_equal 3, @dict.entries.size
    assert_equal "1", @dict.entries[0].id
    assert_equal "一【替】", @dict.entries[0].hanji
    assert_equal "tsi̍t", @dict.entries[0].lomaji
  end

  def test_loads_definitions
    assert_equal 4, @dict.definitions.size
    assert_equal "1", @dict.definitions[0].entry_id
    assert_equal "數詞", @dict.definitions[0].part_of_speech
    assert_equal "數目。", @dict.definitions[0].explanation
  end

  def test_loads_examples
    assert_equal 3, @dict.examples.size
    assert_equal "一蕊花", @dict.examples[0].hanji
    assert_equal "一朵花", @dict.examples[0].chinese
  end

  def test_build_cards_joins_entries_definitions_examples
    cards = @dict.build_cards
    assert_equal 3, cards.size

    # Entry 1 has 2 definitions
    card1 = cards[0]
    assert_equal "一【替】", card1.entry.hanji
    assert_equal 2, card1.definitions.size

    # First definition has 1 example
    dwe1 = card1.definitions[0]
    assert_equal "數詞", dwe1.definition.part_of_speech
    assert_equal 1, dwe1.examples.size
    assert_equal "一蕊花", dwe1.examples[0].hanji
  end

  def test_build_cards_entry_without_definitions_is_skipped
    dict = TaigiDict::Dictionary.new(
      entries: [TaigiDict::Entry.new(id: "99", type: "主詞目", hanji: "孤", lomaji: "koo", categories: "", audio_file: "")],
      definitions: [],
      examples: []
    )
    assert_empty dict.build_cards
  end

  def test_export_csv_roundtrip
    Dir.mktmpdir do |tmpdir|
      @dict.export_csv(tmpdir)

      reloaded = TaigiDict::Dictionary.from_csv(tmpdir)
      assert_equal @dict.entries.size, reloaded.entries.size
      assert_equal @dict.definitions.size, reloaded.definitions.size
      assert_equal @dict.examples.size, reloaded.examples.size

      assert_equal @dict.entries[0].hanji, reloaded.entries[0].hanji
      assert_equal @dict.definitions[0].explanation, reloaded.definitions[0].explanation
      assert_equal @dict.examples[0].chinese, reloaded.examples[0].chinese
    end
  end
end
