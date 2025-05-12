#!/bin/bash

# image_text_center.sh - 在原始圖片上生成中間有文字的圖片

# 檢查參數數量
if [ "$#" -ne 5 ]; then
    echo "用法: $0 '文字' <字體大小> <原始圖片路徑> <x坐標> <y坐標>"
    exit 1
fi

# 參數
text="$1"
fontsize="$2"
input_image="$3"
x="$4"
y="$5"

# 設置預設輸出路徑
output_dir="/home/mark/dev/graduation-ppt-maker/output"
output="$output_dir/000_front_page.png"  # 可以根據需要修改文件名

# 確保輸出目錄存在
mkdir -p "$output_dir"

# 使用 ffmpeg 在原始圖片上添加文字，將字體顏色設置為黑色
ffmpeg -i "$input_image" -vf "drawtext=text='$text':fontcolor=black:fontsize=$fontsize:x=$x:y=$y" -y "$output"

if [ $? -eq 0 ]; then
    echo "已生成圖片: $output"
else
    echo "❗ 生成圖片失敗"
    exit 1
fi