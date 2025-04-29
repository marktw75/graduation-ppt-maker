#!/bin/bash

# image_cut_black.sh - 將圖片指定座標到右下角的區域轉換為黑色
# 用法：./image_cut_black.sh <圖片檔案> <x座標> <y座標>

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 檢查必要的命令
if ! command -v convert &> /dev/null; then
    echo -e "${RED}錯誤：找不到 convert 命令${NC}"
    echo -e "${YELLOW}請安裝必要的套件：${NC}"
    echo -e "${YELLOW}  sudo apt-get update${NC}"
    echo -e "${YELLOW}  sudo apt-get install -y imagemagick${NC}"
    exit 1
fi

# 檢查參數
if [ $# -lt 3 ]; then
    echo -e "${YELLOW}用法：${NC}"
    echo -e "${YELLOW}  ./image_cut_black.sh <圖片檔案> <x座標> <y座標>${NC}"
    echo -e "${YELLOW}範例：${NC}"
    echo -e "${YELLOW}  ./image_cut_black.sh image.jpg 1000 0${NC}"
    exit 1
fi

IMAGE="$1"
X="$2"
Y="$3"

# 檢查圖片是否存在
if [ ! -f "$IMAGE" ]; then
    echo -e "${RED}錯誤：找不到圖片 '$IMAGE'${NC}"
    exit 1
fi

# 檢查座標是否為數字
if ! [[ "$X" =~ ^[0-9]+$ ]] || ! [[ "$Y" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}錯誤：座標必須是正整數${NC}"
    exit 1
fi

# 取得圖片尺寸
dimensions=$(identify -format "%wx%h" "$IMAGE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo -e "${RED}錯誤：無法讀取圖片尺寸${NC}"
    exit 1
fi

width=${dimensions%x*}
height=${dimensions#*x}

# 檢查座標是否在圖片範圍內
if [ "$X" -ge "$width" ] || [ "$Y" -ge "$height" ]; then
    echo -e "${RED}錯誤：座標超出圖片範圍${NC}"
    echo -e "${YELLOW}圖片尺寸：${width}x${height}${NC}"
    exit 1
fi

# 計算要轉換為黑色的區域大小
region_width=$((width - X))
region_height=$((height - Y))

# 建立輸出檔名
filename=$(basename "$IMAGE")
extension="${filename##*.}"
basename="${filename%.*}"
output="${basename}_black.${extension}"

# 使用 convert 命令處理圖片
echo -e "${YELLOW}處理圖片中...${NC}"
convert "$IMAGE" -fill black -draw "rectangle $X,$Y $width,$height" "$output"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}處理完成！${NC}"
    echo -e "${YELLOW}輸出檔案：$output${NC}"
    echo -e "${YELLOW}處理區域：從 ($X,$Y) 到 ($width,$height)${NC}"
else
    echo -e "${RED}處理失敗${NC}"
    exit 1
fi 