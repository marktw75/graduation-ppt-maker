#!/bin/bash

# image_past_center.sh - 將小圖以中心點對準大圖的指定座標進行貼圖
# 用法：./image_past_center.sh <大圖> <小圖> <x座標> <y座標> [比例]

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
if [ $# -lt 4 ]; then
    echo -e "${YELLOW}用法：${NC}"
    echo -e "${YELLOW}  ./image_past_center.sh <大圖> <小圖> <x座標> <y座標> [比例]${NC}"
    echo -e "${YELLOW}範例：${NC}"
    echo -e "${YELLOW}  ./image_past_center.sh big.jpg small.jpg 800 400 0.25${NC}"
    echo -e "${YELLOW}  比例預設為 0.25（大圖最長邊的四分之一）${NC}"
    exit 1
fi

BIG_IMAGE="$1"
SMALL_IMAGE="$2"
X="$3"
Y="$4"
SCALE=${5:-0.25}  # 預設比例為 0.25

# 檢查比例是否為有效數字
if ! [[ "$SCALE" =~ ^[0-9]*\.?[0-9]+$ ]] || (( $(echo "$SCALE <= 0" | bc -l) )) || (( $(echo "$SCALE >= 1" | bc -l) )); then
    echo -e "${RED}錯誤：比例必須是 0 到 1 之間的數字${NC}"
    exit 1
fi

# 檢查圖片是否存在
if [ ! -f "$BIG_IMAGE" ]; then
    echo -e "${RED}錯誤：找不到大圖 '$BIG_IMAGE'${NC}"
    exit 1
fi

if [ ! -f "$SMALL_IMAGE" ]; then
    echo -e "${RED}錯誤：找不到小圖 '$SMALL_IMAGE'${NC}"
    exit 1
fi

# 檢查座標是否為數字
if ! [[ "$X" =~ ^[0-9]+$ ]] || ! [[ "$Y" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}錯誤：座標必須是正整數${NC}"
    exit 1
fi

# 取得大圖尺寸
big_dimensions=$(identify -format "%wx%h" "$BIG_IMAGE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo -e "${RED}錯誤：無法讀取大圖尺寸${NC}"
    exit 1
fi

big_width=${big_dimensions%x*}
big_height=${big_dimensions#*x}

# 取得小圖尺寸
small_dimensions=$(identify -format "%wx%h" "$SMALL_IMAGE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo -e "${RED}錯誤：無法讀取小圖尺寸${NC}"
    exit 1
fi

small_width=${small_dimensions%x*}
small_height=${small_dimensions#*x}

# 檢查座標是否在圖片範圍內
if [ "$X" -ge "$big_width" ] || [ "$Y" -ge "$big_height" ]; then
    echo -e "${RED}錯誤：座標超出大圖範圍${NC}"
    echo -e "${YELLOW}大圖尺寸：${big_width}x${big_height}${NC}"
    exit 1
fi

# 建立臨時目錄
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# 計算目標尺寸（以大圖最長邊為基準）
if [ "$big_width" -gt "$big_height" ]; then
    target_size=$(echo "$big_width * $SCALE" | bc | cut -d. -f1)
else
    target_size=$(echo "$big_height * $SCALE" | bc | cut -d. -f1)
fi

# 縮放小圖
echo -e "${YELLOW}縮放小圖...${NC}"
resized_small="$TEMP_DIR/resized_small.png"
convert "$SMALL_IMAGE" -resize "${target_size}x${target_size}>" "$resized_small"
small_dimensions=$(identify -format "%wx%h" "$resized_small")
small_width=${small_dimensions%x*}
small_height=${small_dimensions#*x}

# 計算小圖中心點對齊的位置
offset_x=$((X - small_width/2))
offset_y=$((Y - small_height/2))

# 建立輸出檔名
filename=$(basename "$BIG_IMAGE")
extension="${filename##*.}"
basename="${filename%.*}"
output="${basename}_pasted.${extension}"

# 使用 convert 命令處理圖片
echo -e "${YELLOW}處理圖片中...${NC}"
echo -e "${YELLOW}大圖尺寸：${big_width}x${big_height}${NC}"
echo -e "${YELLOW}縮放比例：${SCALE}${NC}"
echo -e "${YELLOW}目標尺寸：${target_size}${NC}"
echo -e "${YELLOW}小圖尺寸：${small_width}x${small_height}${NC}"
echo -e "${YELLOW}目標位置：($X,$Y)${NC}"
echo -e "${YELLOW}實際偏移：($offset_x,$offset_y)${NC}"

convert "$BIG_IMAGE" "$resized_small" -geometry "+${offset_x}+${offset_y}" -composite "$output"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}處理完成！${NC}"
    echo -e "${YELLOW}輸出檔案：$output${NC}"
else
    echo -e "${RED}處理失敗${NC}"
    exit 1
fi 