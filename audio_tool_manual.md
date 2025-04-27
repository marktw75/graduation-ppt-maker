# 🎵 audio_tool.sh 使用手冊

## 可用指令

| 指令 | 說明 | 範例 |
|:-----|:-----|:-----|
| `repeat-chorus-smooth` | 重複歌曲副歌，讓音樂更長又自然平滑 | `./audio_tool.sh repeat-chorus-smooth input.mp3 45 75` |
| `crop-range` | 裁切從 start 秒到 end 秒的區段（或只給 start，裁到結束） | `./audio_tool.sh crop-range input.mp3 45 75`<br>`./audio_tool.sh crop-range input.mp3 45` |
| `cut` | 剪掉 start 秒以後的部分，只保留前段 | `./audio_tool.sh cut input.mp3 45` |
| `concat` | 串接兩個 mp3 成一首完整音樂 | `./audio_tool.sh concat intro.mp3 outro.mp3` |

---

## 📦 輸出規則

- 自動建立 `output/` 資料夾
- 每次輸出的檔名自動用當下時間命名，如：`output/audio_202504252215.mp3`

---

## 🛠 使用範例流程

1. 重複副歌讓歌曲延長  
   `./audio_tool.sh repeat-chorus-smooth bgm.mp3 45 75`

2. 裁出高潮段落  
   `./audio_tool.sh crop-range output/audio_XXXX.mp3 0 210`

3. 合併 intro 和 outro  
   `./audio_tool.sh concat intro.mp3 outro.mp3`

---

## 🎯 小技巧速查表

| 想做什麼？ | 用哪個指令？ |
|------------|--------------|
| 延長副歌讓音樂變長 | `repeat-chorus-smooth` |
| 裁出一段高潮區段 | `crop-range` |
| 留下音樂前半段，剪掉後面 | `cut` |
| 合併 intro+main song | `concat` |

---
