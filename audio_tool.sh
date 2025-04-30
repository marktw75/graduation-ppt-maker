#!/bin/bash

# audio_tool.sh - 多功能音樂處理工具

mkdir -p output
timestamp=$(date +"%Y%m%d%H%M")
output_file="output/audio_${timestamp}.mp3"

# 顯示幫助訊息
show_help() {
    echo "用法: ./audio_tool.sh cut <input.mp3> <duration>"
    echo "用法: ./audio_tool.sh silent_start <input.mp3> [<duration>]"
    echo "用法: ./audio_tool.sh silent_end <input.mp3> [<duration>]"
    echo "用法: ./audio_tool.sh repeat-chorus-smooth <input.mp3> <start> <end>"
    echo "用法: ./audio_tool.sh crop-range <input.mp3> <start> [<end>]"
    echo "用法: ./audio_tool.sh concat <input1.mp3> <input2.mp3>"
}

# 剪掉 start 秒以後的部分，只保留前段
cut_audio() {
    local input_file="$1"
    local duration="$2"
    local output_file="output/audio_$(date +%Y%m%d%H%M).mp3"

    ffmpeg -i "$input_file" -t "$duration" -c copy "$output_file"
    echo "✅ 保留前 $duration 秒內容 ➜ $output_file"
}

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

# 主程式
case "$1" in
    cut)
        shift
        cut_audio "$@"
        ;;
    silent_start)
        shift
        add_silence_start "$@"
        ;;
    silent_end)
        shift
        add_silence_end "$@"
        ;;
    help)
        show_help
        ;;
    *)
        echo "未知的命令: $1"
        show_help
        exit 1
        ;;
esac