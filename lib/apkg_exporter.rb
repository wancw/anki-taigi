# frozen_string_literal: true

require "sqlite3"
require "zip"
require "json"
require "digest/sha1"
require "securerandom"
require "fileutils"
require "tmpdir"
require_relative "taigi_dict"

# Exports TaigiDict cards to Anki .apkg (Anki Package) format.
#
# APKG is a ZIP containing:
#   - collection.anki2: SQLite database with notes/cards
#   - media: JSON mapping of numbered files to original names
#   - 0, 1, 2, ...: media files (audio)
module ApkgExporter
  FIELD_SEPARATOR = "\x1f"
  DECK_ID = 1_700_000_000_000
  MODEL_ID = 1_700_000_000_001

  BASE91_TABLE = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" \
                 "0123456789!#$%&()*+,-./:;<=>?@[]^_`{|}~"

  module_function

  # Export cards to an .apkg file.
  # audio_dir: directory containing extracted MP3 files (or nil to skip audio)
  def export(cards, output_path: "output/taigi.apkg", audio_dir: nil)
    dir = File.dirname(output_path)
    FileUtils.mkdir_p(dir)

    Dir.mktmpdir("anki-taigi") do |tmpdir|
      db_path = File.join(tmpdir, "collection.anki2")
      media_map = {}

      build_database(db_path, cards, audio_dir, media_map)
      package_apkg(output_path, db_path, audio_dir, media_map)
    end
  end

  def build_database(db_path, cards, audio_dir, media_map)
    db = SQLite3::Database.new(db_path)
    create_schema(db)

    now_sec = Time.now.to_i
    now_ms = now_sec * 1000

    insert_collection(db, now_sec, now_ms)

    note_id = now_ms
    card_id = now_ms
    due_pos = 0
    media_index = 0

    db.transaction do
      cards.each do |card|
        card.definitions.each do |dwe|
          note_id += 1
          card_id += 1
          due_pos += 1

          entry = card.entry
          defn = dwe.definition
          examples = dwe.examples

          # Collect audio files and build [sound:] references
          entry_audio_ref, media_index = register_audio(
            entry.audio_file, "sutiau-", audio_dir, media_map, media_index
          )
          example_audio_refs = examples.map { |ex|
            ref, media_index = register_audio(
              ex.audio_file, "leku-", audio_dir, media_map, media_index
            )
            ref
          }

          fields = build_fields(entry, defn, examples, entry_audio_ref, example_audio_refs)
          tags = build_tags(entry.categories)
          guid = guid64
          sfld = clean_hanji(entry.hanji)
          csum = checksum(sfld)

          db.execute(
            "INSERT INTO notes VALUES (?,?,?,?,?,?,?,?,?,?,?)",
            [note_id, guid, MODEL_ID, now_sec, -1, tags, fields, sfld, csum, 0, ""]
          )

          db.execute(
            "INSERT INTO cards VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            [card_id, note_id, DECK_ID, 0, now_sec, -1, 0, 0, due_pos, 0, 0, 0, 0, 0, 0, 0, 0, ""]
          )
        end
      end
    end

    db.close
  end

  def create_schema(db)
    db.execute_batch(<<~SQL)
      CREATE TABLE col (
        id integer PRIMARY KEY, crt integer NOT NULL, mod integer NOT NULL,
        scm integer NOT NULL, ver integer NOT NULL, dty integer NOT NULL,
        usn integer NOT NULL, ls integer NOT NULL, conf text NOT NULL,
        models text NOT NULL, decks text NOT NULL, dconf text NOT NULL, tags text NOT NULL
      );
      CREATE TABLE notes (
        id integer PRIMARY KEY, guid text NOT NULL, mid integer NOT NULL,
        mod integer NOT NULL, usn integer NOT NULL, tags text NOT NULL,
        flds text NOT NULL, sfld integer NOT NULL, csum integer NOT NULL,
        flags integer NOT NULL, data text NOT NULL
      );
      CREATE TABLE cards (
        id integer PRIMARY KEY, nid integer NOT NULL, did integer NOT NULL,
        ord integer NOT NULL, mod integer NOT NULL, usn integer NOT NULL,
        type integer NOT NULL, queue integer NOT NULL, due integer NOT NULL,
        ivl integer NOT NULL, factor integer NOT NULL, reps integer NOT NULL,
        lapses integer NOT NULL, left integer NOT NULL, odue integer NOT NULL,
        odid integer NOT NULL, flags integer NOT NULL, data text NOT NULL
      );
      CREATE TABLE revlog (
        id integer PRIMARY KEY, cid integer NOT NULL, usn integer NOT NULL,
        ease integer NOT NULL, ivl integer NOT NULL, lastIvl integer NOT NULL,
        factor integer NOT NULL, time integer NOT NULL, type integer NOT NULL
      );
      CREATE TABLE graves (usn integer NOT NULL, oid integer NOT NULL, type integer NOT NULL);
      CREATE INDEX ix_cards_nid ON cards (nid);
      CREATE INDEX ix_cards_sched ON cards (did, queue, due);
      CREATE INDEX ix_cards_usn ON cards (usn);
      CREATE INDEX ix_notes_csum ON notes (csum);
      CREATE INDEX ix_notes_usn ON notes (usn);
      CREATE INDEX ix_revlog_cid ON revlog (cid);
      CREATE INDEX ix_revlog_usn ON revlog (usn);
    SQL
  end

  def insert_collection(db, now_sec, now_ms)
    model = build_model
    deck = build_deck
    dconf = build_deck_config
    conf = {
      activeDecks: [DECK_ID], curDeck: DECK_ID, newSpread: 0,
      collapseTime: 1200, timeLim: 0, estTimes: true, dueCounts: true,
      curModel: MODEL_ID.to_s, nextPos: 1, sortType: "noteFld",
      sortBackwards: false, addToCur: true
    }

    db.execute(
      "INSERT INTO col VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
      [1, now_sec, now_ms, now_ms, 11, 0, -1, 0,
       JSON.generate(conf),
       JSON.generate({ MODEL_ID.to_s => model }),
       JSON.generate({ DECK_ID.to_s => deck }),
       JSON.generate({ "1" => dconf }),
       "{}"]
    )
  end

  def build_model
    fields = %w[漢字 羅馬字 詞性 解說 例句漢字 例句羅馬字 例句華語 分類 詞目音檔 例句音檔].map.with_index do |name, i|
      { name: name, ord: i, font: "Arial", size: 20, rtl: false, sticky: false, media: [] }
    end

    {
      id: MODEL_ID, name: "台語辭典", type: 0, mod: Time.now.to_i, usn: -1,
      sortf: 0, did: DECK_ID,
      css: model_css,
      latexPre: "", latexPost: "",
      flds: fields,
      tmpls: [card_template],
      req: [[0, "any", [0]]],
      tags: [], vers: []
    }
  end

  def model_css
    <<~CSS
      .card {
        font-family: "Noto Sans TC", "Microsoft JhengHei", sans-serif;
        font-size: 20px;
        text-align: center;
        color: #333;
        background-color: #fafafa;
      }
      .hanji { font-size: 40px; font-weight: bold; color: #1a1a1a; }
      .lomaji { font-size: 24px; color: #2e7d32; margin: 8px 0; }
      .pos { font-size: 14px; color: #888; font-style: italic; }
      .explanation { font-size: 20px; margin: 12px 0; }
      .examples { text-align: left; margin: 12px auto; max-width: 500px; font-size: 16px; }
      .examples .hanji-ex { color: #1a1a1a; }
      .examples .lomaji-ex { color: #2e7d32; font-size: 14px; }
      .examples .chinese-ex { color: #666; font-size: 14px; }
      .category { font-size: 12px; color: #999; margin-top: 16px; }
      hr#answer { border: 1px solid #ddd; }
    CSS
  end

  def card_template
    {
      name: "台語卡片", ord: 0,
      qfmt: <<~HTML.strip,
        <div class="hanji">{{漢字}}</div>
        <div class="lomaji">{{羅馬字}}</div>
        {{詞目音檔}}
      HTML
      afmt: <<~HTML.strip,
        {{FrontSide}}
        <hr id=answer>
        <div class="pos">{{詞性}}</div>
        <div class="explanation">{{解說}}</div>
        {{#例句漢字}}
        <div class="examples">
          <div class="hanji-ex">{{例句漢字}}</div>
          <div class="lomaji-ex">{{例句羅馬字}}</div>
          <div class="chinese-ex">{{例句華語}}</div>
        </div>
        {{/例句漢字}}
        {{例句音檔}}
        <div class="category">{{分類}}</div>
      HTML
      bqfmt: "", bafmt: "", did: nil
    }
  end

  def build_deck
    {
      id: DECK_ID, name: "教育部台語辭典", desc: "教育部臺灣台語常用詞辭典",
      mod: Time.now.to_i, usn: -1, conf: 1,
      collapsed: false, browserCollapsed: false, dyn: 0,
      extendNew: 10, extendRev: 50,
      newToday: [0, 0], revToday: [0, 0], lrnToday: [0, 0], timeToday: [0, 0]
    }
  end

  def build_deck_config
    {
      id: 1, name: "Default", mod: 0, usn: -1,
      autoplay: true, replayq: true, timer: 0, maxTaken: 60,
      new: { delays: [1, 10], initialFactor: 2500, ints: [1, 4, 0], order: 1, perDay: 20, bury: false, separate: true },
      rev: { perDay: 200, ease4: 1.3, fuzz: 0.05, ivlFct: 1, maxIvl: 36500, bury: false, minSpace: 1 },
      lapse: { delays: [10], leechAction: 0, leechFails: 8, minInt: 1, mult: 0 }
    }
  end

  def build_fields(entry, defn, examples, entry_audio_ref, example_audio_refs)
    hanji = clean_hanji(entry.hanji)
    example_hanji = examples.map(&:hanji).join("<br>")
    example_lomaji = examples.map(&:lomaji).join("<br>")
    example_chinese = examples.map(&:chinese).join("<br>")
    example_audio = example_audio_refs.compact.join(" ")

    [
      hanji,
      entry.lomaji,
      defn.part_of_speech,
      defn.explanation,
      example_hanji,
      example_lomaji,
      example_chinese,
      entry.categories,
      entry_audio_ref || "",
      example_audio
    ].join(FIELD_SEPARATOR)
  end

  # Register an audio file in the media map (deduplicated). Returns [sound_ref, next_index].
  def register_audio(filename, prefix, audio_dir, media_map, media_index)
    return [nil, media_index] if filename.nil? || filename.empty?

    full_name = "#{prefix}#{filename}.mp3"
    return [nil, media_index] if audio_dir && !File.exist?(File.join(audio_dir, full_name))

    # Deduplicate: only assign a new index if this file hasn't been registered yet
    unless media_map.value?(full_name)
      media_map[media_index.to_s] = full_name
      media_index += 1
    end

    ref = "[sound:#{full_name}]"
    [ref, media_index]
  end

  def package_apkg(output_path, db_path, audio_dir, media_map)
    File.delete(output_path) if File.exist?(output_path)

    Zip::OutputStream.open(output_path) do |zos|
      # collection.anki2
      zos.put_next_entry("collection.anki2", nil, nil, Zip::Entry::DEFLATED)
      zos.write(File.binread(db_path))

      # media mapping
      zos.put_next_entry("media", nil, nil, Zip::Entry::STORED)
      zos.write(JSON.generate(media_map))

      # media files
      if audio_dir
        media_map.each do |index, filename|
          file_path = File.join(audio_dir, filename)
          next unless File.exist?(file_path)

          zos.put_next_entry(index, nil, nil, Zip::Entry::STORED)
          zos.write(File.binread(file_path))
        end
      end
    end
  end

  # Generate a 10-character base91 GUID (Anki format).
  def guid64
    num = SecureRandom.random_number(2**64)
    s = +""
    while num > 0
      s << BASE91_TABLE[num % 91]
      num /= 91
    end
    s.ljust(10, BASE91_TABLE[0])
  end

  # SHA1 checksum of stripped first field (first 8 hex digits as integer).
  def checksum(text)
    stripped = text.gsub(/<[^>]+>/, "").strip
    Digest::SHA1.hexdigest(stripped)[0, 8].to_i(16)
  end

  def clean_hanji(hanji)
    hanji&.gsub(/【替】/, "") || ""
  end

  def build_tags(categories)
    tags = (categories || "").split(",").map { |c| c.strip.gsub(" ", "_") }
    return "" if tags.empty?

    " #{tags.join(" ")} "
  end
end
