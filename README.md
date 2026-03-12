<p align="center">
  <span>English</span> |
  <a href="readmes/README.nan-hant-tw.md">台語（漢字）</a>
</p>

# anki-taigi

Generate [Anki](https://apps.ankiweb.net/) flashcard decks for **Taiwanese Taigi (台灣台語)** from the [教育部臺灣台語常用詞辭典](https://sutian.moe.edu.tw/) open data.

## Features

- Downloads dictionary data and audio files directly from MOE (教育部)
- Parses the ODS spreadsheet natively in Ruby (no LibreOffice needed)
- Generates a self-contained `.apkg` file with **23,106 notes** and **34,286 embedded MP3 audio files**
- Each card includes:
  - **Front**: 漢字 (Han characters) + 羅馬字 (Tâi-lô romanization) + pronunciation audio
  - **Back**: 詞性 (part of speech) + 解說 (explanation) + 例句 (example sentences with audio)
- Cards are tagged by category (e.g. 交際應酬, 數詞、量詞)

## Requirements

- Ruby 4.0.0+
- Bundler

## Usage

```bash
bundle install
ruby generate.rb
```

The pipeline will:

1. **Fetch** dictionary ODS + MP3 archives from MOE (~780 MB total, skipped if already downloaded)
2. **Parse** the ODS and extract 詞目 (entries), 義項 (definitions), 例句 (examples)
3. **Cache** parsed data as CSV files for faster subsequent runs
4. **Extract** MP3 audio files from zip archives
5. **Export** Anki deck as both `.apkg` and `.txt`

Output files are written to `output/`:

| File | Description |
|------|-------------|
| `output/taigi.apkg` | Anki package with embedded audio (~694 MB) |
| `output/taigi_deck.txt` | Tab-separated text (importable without audio) |

### Import into Anki

Open Anki → File → Import → select `output/taigi.apkg`.

## Data Source

All dictionary data and audio are from the **教育部臺灣台語常用詞辭典** open data:

https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/

## License

The dictionary data and audio are provided by the Ministry of Education (教育部) of Taiwan under their open data terms. Please refer to the [original source](https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/) for licensing details.
