#!/bin/bash

# audio_tool.sh - 多功能音樂處理工具

mkdir -p output
timestamp=$(date +"%Y%m%d%H%M")
output_file="output/audio_${timestamp}.mp3"

usage() {
  echo ""
  echo "🎵 audio_tool.sh - 多功能音樂處理"
  echo ""
  echo "用法："
  echo "  ./audio_tool.sh repeat-chorus-smooth input.mp3 start_sec end_sec"
  echo "  ./audio_tool.sh crop-range input.mp3 start_sec [end_sec]"
  echo "  ./audio_tool.sh cut input.mp3 start_sec"
  echo "  ./audio_tool.sh concat input1.mp3 input2.mp3"
  echo ""
  exit 1
}

if [ $# -lt 2 ]; then
  usage
fi

cmd="$1"
shift

if [ "$cmd" = "repeat-chorus-smooth" ]; then
  input="$1"
  start="$2"
  end="$3"
  tmp_chorus="output/tmp_chorus_${timestamp}.mp3"

  ffmpeg -y -i "$input" -ss "$start" -to "$end" -c copy "$tmp_chorus"
  ffmpeg -y -i "$input" -i "$tmp_chorus" -i "$input" -filter_complex "[0:0][1:0][2:0]concat=n=3:v=0:a=1[out]" -map "[out]" "$output_file"
  rm -f "$tmp_chorus"
  echo "✅ 完成副歌重複平滑版本 ➜ $output_file"

elif [ "$cmd" = "crop-range" ]; then
  input="$1"
  start="$2"
  end="$3"

  if [ -z "$end" ]; then
    ffmpeg -y -ss "$start" -i "$input" -c copy "$output_file"
    echo "✅ 裁切 $start 秒到結尾 ➜ $output_file"
  else
    ffmpeg -y -ss "$start" -to "$end" -i "$input" -c copy "$output_file"
    echo "✅ 裁切 $start 秒到 $end 秒 ➜ $output_file"
  fi

elif [ "$cmd" = "cut" ]; then
  input="$1"
  start="$2"

  ffmpeg -y -t "$start" -i "$input" -c copy "$output_file"
  echo "✅ 保留前 $start 秒內容 ➜ $output_file"

elif [ "$cmd" = "concat" ]; then
  input1="$1"
  input2="$2"
  ffmpeg -y -i "$input1" -i "$input2" -filter_complex "[0:0][1:0]concat=n=2:v=0:a=1[out]" -map "[out]" "$output_file"
  echo "✅ 兩個音樂已串接完成 ➜ $output_file"

else
  echo "❌ 不支援的指令：$cmd"
  usage
fi
