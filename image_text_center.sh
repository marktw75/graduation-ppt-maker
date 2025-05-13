#!/bin/bash

# image_text_center.sh - 在原始圖片上生成中間有文字的圖片

# 預設參數
fontsize=60
fontcolor="black"
shadowcolor="black"  # 陰影顏色
shadowx=2            # 陰影的 x 偏移量
shadowy=2            # 陰影的 y 偏移量
x=0
y=0
input_image=""
text=""

# 解析命令行參數
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --text) text="$2"; shift ;;
        --fontsize) fontsize="$2"; shift ;;
        --location) x="$2"; y="$3"; shift 2 ;;
        --color) fontcolor="$2"; shift ;;
        *) input_image="$1" ;;  # 最後一個參數是原始圖片路徑
    esac
    shift
done

# 檢查必需的參數
if [ -z "$text" ] || [ -z "$input_image" ]; then
    echo "用法: $0 --text '文字' [--fontsize <字體大小>] [--location <x> <y>] [--color <顏色>] <原始圖片路徑>"
    exit 1
fi

# 設置預設輸出路徑
output_dir="/home/mark/dev/graduation-ppt-maker/output"

# 使用當前時間戳生成檔名
timestamp=$(date +"%Y%m%d_%H%M%S")
output="$output_dir/${timestamp}.jpg"

# 確保輸出目錄存在
mkdir -p "$output_dir"

# 如果未指定座標，則計算中心位置
if [ "$x" -eq 0 ] && [ "$y" -eq 0 ]; then
    # 使用 ffprobe 獲取圖片寬度和高度
    width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$input_image")
    height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$input_image")
    
    # 計算文字的總寬度
    text_width=$(echo "$text" | awk -v fontsize="$fontsize" '{print length($0) * fontsize * 0.6}')  # 簡單估算
    x=$(( (width - text_width) / 2 ))
    y=$(( (height - fontsize) / 2 ))

    # 輸出計算結果
    echo "計算的文字總長度: $text_width 像素"
    echo "使用的中心點: ($x, $y)"
fi

# 使用 ffmpeg 在原始圖片上添加文字，並增加陰影效果
ffmpeg -i "$input_image" -vf "drawtext=text='$text':fontcolor=$fontcolor:fontsize=$fontsize:x=$x:y=$y:shadowcolor=$shadowcolor:shadowx=$shadowx:shadowy=$shadowy" -y "$output"

if [ $? -eq 0 ]; then
    echo "已生成圖片: $output"
else
    echo "❗ 生成圖片失敗"
    exit 1
fi