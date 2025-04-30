#!/bin/bash

# audio_tool.sh - 多功能音樂處理工具

mkdir -p output
timestamp=$(date +"%Y%m%d%H%M")

# 顯示幫助訊息
show_help() {
    echo "用法: ./audio_tool.sh cut <input.mp3> <duration>"
    echo "用法: ./audio_tool.sh silent_start <input.mp3> [<duration>]"
    echo "用法: ./audio_tool.sh silent_end <input.mp3> [<duration>]"
    echo "用法: ./audio_tool.sh enhance <input.mp3> <start> <end> [<volume>]"
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

# 增大聲音的函數
enhance_audio() {
    local input_file="$1"
    local start="$2"
    local end="$3"
    local volume="${4:-2}"  # 預設增大音量為 2 倍
    local output_file="output/enhanced_$(basename "$input_file")"

    echo "增大聲音，範圍: $start 秒到 $end 秒，增大倍數: $volume"

    # 使用 ffmpeg 增大指定段落的音量，並保持音頻長度不變
    ffmpeg -i "$input_file" -filter_complex "[0:a]atrim=start=0:end=$start[a0];[0:a]atrim=start=$start:end=$end,volume=${volume}dB[a1];[0:a]atrim=start=$end[a2];[a0][a1][a2]concat=n=3:v=0:a=1" -y "$output_file"
    
    if [ $? -ne 0 ]; then
        echo "❗ 增大聲音失敗"
        exit 1
    fi

    echo "已增大聲音: $output_file"
}

# 合併音頻的函數
concat_audio() {
    local input_file1="$1"
    local input_file2="$2"
    local output_file="output/concat_$(basename "$input_file1" .mp3)_$(basename "$input_file2" .mp3).mp3"

    # 使用 ffmpeg 合併音頻
    ffmpeg -i "concat:$input_file1|$input_file2" -acodec copy "$output_file"
    if [ $? -ne 0 ]; then
        echo "❗ 合併音頻失敗"
        exit 1
    fi

    echo "已合併音頻: $output_file"
}

# 重複合唱的函數
repeat_chorus_smooth() {
    local input_file="$1"
    local start="$2"
    local end="$3"
    local output_file="output/repeat_chorus_$(basename "$input_file")"

    # 使用 ffmpeg 重複合唱部分
    ffmpeg -i "$input_file" -ss "$start" -to "$end" -c copy "$output_file"
    if [ $? -ne 0 ]; then
        echo "❗ 重複合唱失敗"
        exit 1
    fi

    echo "已重複合唱: $output_file"
}

# 剪裁範圍的函數
crop_range() {
    local input_file="$1"
    local start="$2"
    local end="$3"
    local output_file="output/crop_$(basename "$input_file")"

    if [ -z "$end" ]; then
        ffmpeg -i "$input_file" -ss "$start" -c copy "$output_file"
    else
        ffmpeg -i "$input_file" -ss "$start" -to "$end" -c copy "$output_file"
    fi

    if [ $? -ne 0 ]; then
        echo "❗ 剪裁範圍失敗"
        exit 1
    fi

    echo "已剪裁範圍: $output_file"
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
    enhance)
        shift
        enhance_audio "$@"
        ;;
    concat)
        shift
        concat_audio "$@"
        ;;
    repeat-chorus-smooth)
        shift
        repeat_chorus_smooth "$@"
        ;;
    crop-range)
        shift
        crop_range "$@"
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