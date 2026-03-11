# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Generates Anki flashcard decks for Taiwanese Taigi (台灣台語) from MOE (教育部) open data at https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/.

## Environment

- **Ruby version**: 4.0.0 (managed via RVM with gemset `anki-taigi`)
- **Dependencies**: `csv`, `rubyzip`, `rexml` (managed via Bundler)

## Run

```bash
bundle install
ruby generate.rb
```

This runs the full pipeline: download → parse ODS → export CSV cache → generate Anki deck → extract audio.

## Architecture

`generate.rb` orchestrates 5 pipeline steps:

1. **`lib/moe_fetcher.rb`** — Downloads `kautian.ods` + MP3 zip files from MOE via `net/http`
2. **`lib/ods_parser.rb`** — Parses ODS (ZIP+XML) using `rubyzip` + `rexml`. Handles `office:value` attributes for numeric IDs, `number-columns-repeated` / `number-rows-repeated` for cell/row spans
3. **`lib/taigi_dict.rb`** — Loads data via `Dictionary.from_ods` or `Dictionary.from_csv`. Joins Entry→Definition(義項)→Example into Card structs. Can also `export_csv` for caching
4. **`lib/anki_exporter.rb`** — Exports Cards to tab-separated text with `[sound:]` tags for Anki audio playback
5. **`lib/audio_extractor.rb`** — Extracts MP3s from zip archives with prefixes (`sutiau-`, `leku-`)

## Data Model

Entry (詞目) → has many Definition (義項) → has many Example (例句). Cross-referenced via `詞目id` and `義項id`. Audio filenames encode the relationship: entry `N(1)`, example `N-M-K`.

## Key Data Files (not committed)

- `data/kautian.ods` — raw MOE dictionary (4MB, 19 sheets)
- `data/sutiau-mp3.zip` / `data/leku-mp3.zip` — audio archives (~285MB / ~490MB)
- `data/csv/` — cached CSV exports from ODS
- `output/taigi_deck.txt` — generated Anki import file (23K notes)
- `output/audio/` — extracted MP3s (39K files) to copy into Anki media folder
