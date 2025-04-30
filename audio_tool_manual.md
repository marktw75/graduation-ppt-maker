# 🎵 audio_tool.sh 使用手冊

## 可用指令

| 指令 | 說明 | 範例 |
|:-----|:-----|:-----|
| `repeat-chorus-smooth` | 重複歌曲副歌，讓音樂更長又自然平滑 | `./audio_tool.sh repeat-chorus-smooth input.mp3 45 75` |
| `crop-range` | 裁切從 start 秒到 end 秒的區段（或只給 start，裁到結束） | `./audio_tool.sh crop-range input.mp3 45 75`<br>`./audio_tool.sh crop-range input.mp3 45` |
| `cut` | 剪掉 start 秒以後的部分，只保留前段 | `./audio_tool.sh cut input.mp3 45` |
| `concat` | 串接兩個 mp3 成一首完整音樂 | `./audio_tool.sh concat intro.mp3 outro.mp3` |
| `silent_start` | 在 MP3 開始前添加靜音 | `./audio_tool.sh silent_start input.mp3 1` |
| `silent_end` | 在 MP3 結束後添加靜音 | `./audio_tool.sh silent_end input.mp3 1` |

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

4. 在開始前添加靜音（預設 1 秒）  
   `./audio_tool.sh silent_start input.mp3`

5. 在結束後添加靜音（預設 1 秒）  
   `./audio_tool.sh silent_end input.mp3`

---

## 🎯 小技巧速查表

| 想做什麼？ | 用哪個指令？ |
|------------|--------------|
| 延長副歌讓音樂變長 | `repeat-chorus-smooth` |
| 裁出一段高潮區段 | `crop-range` |
| 留下音樂前半段，剪掉後面 | `cut` |
| 合併 intro+main song | `concat` |
| 在開始前添加靜音 | `silent_start` |
| 在結束後添加靜音 | `silent_end` |

---

# 在開始前添加靜音的函數
add_silence_start() {
    local input_file="$1"
    local duration="${2:-1}"  # 預設持續時間為 1 秒
    local output_file="output/silent_start_$(basename "$input_file")"

    echo "生成靜音音頻，持續時間: $duration 秒"
    ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t "$duration" -acodec libmp3lame -ar 44100 -ac 2 silence.mp3
    if [ $? -ne 0 ]; then
        echo "❗ 無法生成靜音音頻"
        exit 1
    fi

    # 合併靜音和原始音頻
    ffmpeg -i silence.mp3 -i "$input_file" -filter_complex "[0:a][1:a]concat=n=2:v=0:a=1" "$output_file"
    rm silence.mp3
    echo "已生成包含靜音的音頻: $output_file"
}

# 在結束後添加靜音的函數
add_silence_end() {
    local input_file="$1"
    local duration="${2:-1}"  # 預設持續時間為 1 秒
    local output_file="output/silent_end_$(basename "$input_file")"

    echo "生成靜音音頻，持續時間: $duration 秒"
    ffmpeg -f lavfi -i anullsrc=r=44100:cl=stereo -t "$duration" -acodec libmp3lame -ar 44100 -ac 2 silence.mp3
    if [ $? -ne 0 ]; then
        echo "❗ 無法生成靜音音頻"
        exit 1
    fi

    # 合併原始音頻和靜音
    ffmpeg -i "$input_file" -i silence.mp3 -filter_complex "[0:a][1:a]concat=n=2:v=0:a=1" "$output_file"
    if [ $? -ne 0 ]; then
        echo "❗ 合併音頻失敗"
        rm silence.mp3
        exit 1
    fi

    rm silence.mp3
    echo "已生成包含靜音的音頻: $output_file"
}

---
