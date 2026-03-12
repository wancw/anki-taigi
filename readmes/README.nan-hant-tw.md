# anki-taigi

對[教育部臺灣台語常用詞辭典](https://sutian.moe.edu.tw/)開放資料產生 [Anki](https://apps.ankiweb.net/) 用--ê **台灣台語（Taiwanese Taigi）** 字卡組

## 功能

- 對教育部下載辭典資料佮音檔
- 直接用 Ruby 解析 ODS 試算表 （無需要 LibreOffice）
- 產生完整包含 **23,106 筆筆記** 佮 **34,286 MP3 音檔** 的 `.apkg` 檔案
- 每一張卡片內底有:
  - **頭前面**: 漢字、羅馬字、發音（錄音）
  - **後壁面**: 詞性、解說、例句
- 卡片按分類（比如：交際應酬、數詞、量詞）下標籤（tag）

## 需求

- Ruby 4.0.0+
- Bundler

## 使用方法

```bash
bundle install
ruby generate.rb
```

規个過程會：

1. **下載** 教育部 ê 辭典 ODS 佮 MP3 檔案 （攏總差不多 780 MB，掠過就袂閣掠）
2. **解析** ODS 抽出「詞目」、「義項」（定義）、「例句」
3. **保存** 解析完 ê 資料做 CSV 檔案，予後回走較緊
4. **抽出** zip 檔案內底 ê MP3 音檔
5. **產生** `.apkg` 佮 `.txt` 兩種 Anki 字卡組檔案

產生 ê 檔案會囥佇咧 `output/`：

| 檔案 | 說明 |
|------|-------------|
| `output/taigi.apkg` | 包含音檔--ê Anki 字卡組檔案 （大約 694 MB） |
| `output/taigi_deck.txt` | 用 tab 分隔 ê 文字 （會當匯入無音檔 ê 內容）|

### 匯入 Anki

拍開 Anki → File → Import → 選擇 `output/taigi.apkg`。

## 資料來源

所有辭典資料佮聲音檔案攏來自**教育部臺灣台語常用詞辭典**開放資料：

https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/

## 授權

辭典資料佮音檔由台灣教育部根據𪜶 ê 開放資料條款提供，詳細請參考[原始來源](https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/)。
