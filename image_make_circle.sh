#!/bin/bash

# image_make_circle.sh - 將圖片轉換成圓形
# 用法：./image_make_circle.sh <圖片檔案>

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
if [ $# -lt 1 ]; then
    echo -e "${YELLOW}用法：${NC}"
    echo -e "${YELLOW}  ./image_make_circle.sh <圖片檔案>${NC}"
    echo -e "${YELLOW}範例：${NC}"
    echo -e "${YELLOW}  ./image_make_circle.sh photo.jpg${NC}"
    exit 1
fi

IMAGE="$1"

# 檢查圖片是否存在
if [ ! -f "$IMAGE" ]; then
    echo -e "${RED}錯誤：找不到圖片 '$IMAGE'${NC}"
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

# 找出最短邊作為圓形直徑
if [ "$width" -lt "$height" ]; then
    diameter=$width
else
    diameter=$height
fi

# 建立輸出檔名
filename=$(basename "$IMAGE")
extension="${filename##*.}"
basename="${filename%.*}"
output="${basename}_circle.png"  # 改用 PNG 格式以支援透明度

# 使用 convert 命令處理圖片
echo -e "${YELLOW}處理圖片中...${NC}"
echo -e "${YELLOW}原始尺寸：${width}x${height}${NC}"
echo -e "${YELLOW}圓形直徑：$diameter${NC}"

# 建立一個臨時目錄
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# 步驟：
# 1. 建立圓形遮罩
convert -size "${diameter}x${diameter}" xc:none -fill white \
    -draw "circle $((diameter/2)),$((diameter/2)) $((diameter/2)),0" \
    "$TEMP_DIR/mask.png"

# 2. 將原圖縮放到正方形並置中
convert "$IMAGE" -resize "${diameter}x${diameter}^" -gravity center -extent "${diameter}x${diameter}" \
    "$TEMP_DIR/resized.png"

# 3. 套用遮罩
convert "$TEMP_DIR/resized.png" "$TEMP_DIR/mask.png" \
    -alpha off -compose CopyOpacity -composite \
    "$output"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}處理完成！${NC}"
    echo -e "${YELLOW}輸出檔案：$output${NC}"
else
    echo -e "${RED}處理失敗${NC}"
    exit 1
fi 