#!/bin/bash

show_help() {
  echo ""
  echo "🎵 mp3-smooth-loop：讓 MP3 某段自然重複播放（加入淡入淡出）"
  echo ""
  echo "用法："
  echo "  ./repeat_chorus_smooth.sh <input.mp3> <chorus_start> <chorus_end> [fade_duration]"
  echo ""
  echo "參數："
  echo "  input.mp3       要處理的 mp3 檔案"
  echo "  chorus_start    要重複段的開始時間（例如 00:40）"
  echo "  chorus_end      要重複段的結束時間（例如 01:10）"
  echo "  fade_duration   （選填）淡入淡出時間（秒），預設為 0.5"
  echo ""
  echo "範例："
  echo "  ./repeat_chorus_smooth.sh music.mp3 00:40 01:10"
  echo "  ./repeat_chorus_smooth.sh music.mp3 00:30 00:50 1.0"
  echo ""
  exit 0
}

# 顯示幫助
if [[ "$1" == "--help" || "$1" == "-h" || "$#" -lt 3 ]]; then
  show_help
fi

input_mp3="$1"
chorus_start="$2"
chorus_end="$3"
fade_len="${4:-0.5}"  # 預設 0.5 秒

basename=$(basename "$input_mp3" .mp3)
tmp="tmp_${basename}_smooth"
output="${basename}_looped_smooth.mp3"

rm -rf "$tmp"
mkdir "$tmp"

echo "🎧 處理檔案：$input_mp3"
echo "🎯 副歌範圍：$chorus_start → $chorus_end"
echo "🌊 淡入淡出時間：${fade_len} 秒"

# Step 1: 轉成 wav
ffmpeg -y -i "$input_mp3" "$tmp/original.wav"

# Step 2: 裁切段落
ffmpeg -y -i "$tmp/original.wav" -ss 00:00 -to "$chorus_start" "$tmp/intro.wav"
ffmpeg -y -i "$tmp/original.wav" -ss "$chorus_start" -to "$chorus_end" "$tmp/chorus_raw.wav"
ffmpeg -y -i "$tmp/original.wav" -ss "$chorus_end" "$tmp/outro.wav"

# Step 3: 加淡入淡出
chorus_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$tmp/chorus_raw.wav")
chorus_len=$(printf "%.3f\n" "$chorus_duration")
fade_out_start=$(echo "$chorus_len - $fade_len" | bc)

ffmpeg -y -i "$tmp/chorus_raw.wav" -af "afade=t=out:st=${fade_out_start}:d=${fade_len}" "$tmp/chorus_fadeout.wav"
ffmpeg -y -i "$tmp/chorus_raw.wav" -af "afade=t=in:st=0:d=${fade_len}" "$tmp/chorus_fadein.wav"

# Step 4: concat list
cat > "$tmp/list.txt" <<EOF
file 'intro.wav'
file 'chorus_fadeout.wav'
file 'chorus_fadein.wav'
file 'outro.wav'
EOF

# Step 5: 合併並轉回 mp3
ffmpeg -y -f concat -safe 0 -i "$tmp/list.txt" -c copy "$tmp/merged.wav"
ffmpeg -y -i "$tmp/merged.wav" -codec:a libmp3lame -qscale:a 2 "$output"

echo "✅ 已完成平滑重複副歌：$output"
