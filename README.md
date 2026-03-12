# anki-taigi: 台灣台語的 Anki（暗記）字卡

Generate [Anki](https://apps.ankiweb.net/) flashcard decks for **Taiwanese Taigi (台灣台語)** from the [教育部臺灣台語常用詞辭典](https://sutian.moe.edu.tw/) open data.

對[教育部臺灣台語常用詞辭典](https://sutian.moe.edu.tw/)的公開資料，來產生**台灣台語**的 [Anki](https://apps.ankiweb.net/) 字卡。

## Features: 特色

- Downloads dictionary data and audio files directly from MOE (教育部)
  - 直接對教育部下載辭典資料佮音檔
- Parses the ODS spreadsheet natively in Ruby (no LibreOffice needed)
  - 佇 Ruby 直接解析 ODS 試算表（毋免用 LibreOffice）
- Generates a self-contained `.apkg` file with **23,106 notes** and **34,286 embedded MP3 audio files**
  - 產生一个包含 **23,106 條詞目**佮 **34,286 個內嵌 MP3 音檔**的 `.apkg` 檔
- Each card includes:
  - **Front**: 漢字 (Han characters) + 羅馬字 (Tâi-lô romanization) + pronunciation audio
  - **Back**: 詞性 (part of speech) + 解說 (explanation) + 例句 (example sentences with audio)
  - 每張字卡包含：
    - **面頂**：漢字 + 羅馬字 (台羅) + 讀音音檔
    - **尻脊**：詞性 + 解說 + 例句（有音檔）
- Cards are tagged by category (e.g. 交際應酬, 數詞、量詞)
  - 字卡會照類別（譬如：交際應酬, 數詞、量詞）來拍標籤

## Requirements: 軟體要求

- Ruby 4.0.0+
- Bundler

## Usage: 使用方法

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

這个流程會：

1. **下載**：對教育部下載辭典 ODS 佮 MP3 壓縮檔（攏總約 780 MB，若是已經下載過就會跳過）
2. **解析**：解析 ODS 並提煉出詞目、義項佮例句
3. **快取**：將解析後的資料草稿存做 CSV 檔，予下擺執行較緊
4. **解壓縮**：對 zip 檔解開 MP3 音檔
5. **匯出**：產生 `.apkg` 佮 `.txt` 格式的 Anki 字卡包

Output files are written to `output/`:
產出的檔案會囥佇 `output/` 目錄：

| File | Description |
|------|-------------|
| `output/taigi.apkg` | Anki package with embedded audio (~694 MB) |
| `output/taigi_deck.txt` | Tab-separated text (importable without audio) |

| 檔案 | 說明 |
|------|-------------|
| `output/taigi.apkg` | 包含內嵌音檔的 Anki 字卡包 (~694 MB) |
| `output/taigi_deck.txt` | Tab 分隔的文字檔（若是無欲愛音檔會使直接匯入） |

### Import into Anki: 匯入 Anki

Open Anki → File → Import → select `output/taigi.apkg`.

拍開 Anki → 檔案 → 匯入 → 選擇 `output/taigi.apkg`。

## Data Source: 資料來源

All dictionary data and audio are from the **教育部臺灣台語常用詞辭典** open data:

所有辭典資料佮音檔攏是來自**教育部臺灣台語常用詞辭典**的公開資料：

https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/

## License: 授權

The dictionary data and audio are provided by the Ministry of Education (教育部) of Taiwan under their open data terms. Please refer to the [original source](https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/) for licensing details.

辭典資料佮音檔是教育部照公開資料條款來提供。授權細節請參考[原網站](https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/)。
