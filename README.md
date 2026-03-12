# anki-taigi: 台灣台語的 Anki（暗記）字卡

Generate [Anki](https://apps.ankiweb.net/) flashcard decks for **Taiwanese Taigi (台灣台語)** from the [教育部臺灣台語常用詞辭典](https://sutian.moe.edu.tw/) open data.

對[教育部臺灣台語常用詞辭典](https://sutian.moe.edu.tw/)開放資料產生 [Anki](https://apps.ankiweb.net/) 用--ê **台灣台語（Taiwanese Taigi）** 字卡組

## Features: 功能

- Downloads dictionary data and audio files directly from MOE (教育部)
  - 對教育部下載辭典資料佮音檔
- Parses the ODS spreadsheet natively in Ruby (no LibreOffice needed)
  - 直接用 Ruby 解析 ODS 試算表 （無需要 LibreOffice）
- Generates a self-contained `.apkg` file with **23,106 notes** and **34,286 embedded MP3 audio files**
  - 產生完整包含 **23,106 筆筆記** 佮 **34,286 MP3 音檔** 的 `.apkg` 檔案
- Each card includes:
  - **Front**: 漢字 (Han characters) + 羅馬字 (Tâi-lô romanization) + pronunciation audio
  - **Back**: 詞性 (part of speech) + 解說 (explanation) + 例句 (example sentences with audio)
  - 每一張卡片內底有：
    - **頭前面**：漢字、羅馬字、發音（錄音）
    - **後壁面**：詞性、解說、例句
- Cards are tagged by category (e.g. 交際應酬, 數詞、量詞)
  - 卡片按分類（比如：交際應酬、數詞、量詞）下標籤（tag）

## Requirements: 需求

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

規个過程會：

1. **下載** 教育部 ê 辭典 ODS 佮 MP3 檔案 （攏總差不多 780 MB，掠過就袂閣掠）
2. **解析** ODS 抽出「詞目」、「義項」（定義）、「例句」
3. **保存** 解析完 ê 資料做 CSV 檔案，予後回走較緊
4. **抽出** zip 檔案內底 ê MP3 音檔
5. **產生** `.apkg` 佮 `.txt` 兩種 Anki 字卡組檔案

Output files are written to `output/`:
產生 ê 檔案會囥佇咧 `output/`：

| File 檔案 | Description 說明 |
|------|-------------|
| `output/taigi.apkg` | Anki package with embedded audio (~694 MB) |
| | 包含音檔--ê Anki 字卡組檔案 （大約 694 MB） |
| `output/taigi_deck.txt` | Tab-separated text (importable without audio) |
| | 用 tab 分隔 ê 文字 （會當匯入無音檔 ê 內容） |

### Import into Anki: 匯入 Anki

Open Anki → File → Import → select `output/taigi.apkg`.

拍開 Anki → File → Import → 選擇 `output/taigi.apkg`。

## Data Source: 資料來源

All dictionary data and audio are from the **教育部臺灣台語常用詞辭典** open data:

所有辭典資料佮聲音檔案攏來自**教育部臺灣台語常用詞辭典**開放資料：

https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/

## License: 授權

The dictionary data and audio are provided by the Ministry of Education (教育部) of Taiwan under their open data terms. Please refer to the [original source](https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/) for licensing details.

辭典資料佮音檔由台灣教育部根據𪜶 ê 開放資料條款提供，詳細請參考[原始來源](https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/)。

## Acknoledgements: 感謝

感謝網友 [WanCW](https://github.com/wancw/) 鬥相共，提供台語漢字ê說明文。
