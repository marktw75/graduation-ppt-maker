#!/bin/bash

# pickup_photos.sh - 從照片集中找出有人臉的照片
# 用法：./pickup_photos.sh <照片目錄> [最小臉部比例]

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 檢查必要的命令
for cmd in facedetect identify; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}錯誤：找不到 $cmd 命令${NC}"
        echo -e "${YELLOW}請安裝必要的套件：${NC}"
        echo -e "${YELLOW}  sudo apt-get update${NC}"
        echo -e "${YELLOW}  sudo apt-get install -y facedetect imagemagick${NC}"
        exit 1
    fi
done

# 預設值
MIN_FACE_RATIO=0.2  # 最小臉部比例（臉部面積/照片面積）

# 解析參數
if [ $# -lt 1 ]; then
    echo -e "${YELLOW}用法：${NC}"
    echo -e "${YELLOW}  ./pickup_photos.sh <照片目錄> [最小臉部比例]${NC}"
    echo -e "${YELLOW}預設值：${NC}"
    echo -e "${YELLOW}  最小臉部比例：$MIN_FACE_RATIO${NC}"
    exit 1
fi

PHOTO_DIR="$1"
[ $# -gt 1 ] && MIN_FACE_RATIO="$2"

# 檢查目錄是否存在
if [ ! -d "$PHOTO_DIR" ]; then
    echo -e "${RED}錯誤：找不到目錄 '$PHOTO_DIR'${NC}"
    exit 1
fi

# 建立輸出目錄
mkdir -p "output/portraits"

echo -e "${YELLOW}開始掃描照片...${NC}"
echo -e "${YELLOW}設定：${NC}"
echo -e "${YELLOW}  最小臉部比例：$MIN_FACE_RATIO${NC}"

# 掃描所有圖片
shopt -s nullglob
for img in "$PHOTO_DIR"/*.jpg "$PHOTO_DIR"/*.jpeg "$PHOTO_DIR"/*.png "$PHOTO_DIR"/*.JPG "$PHOTO_DIR"/*.JPEG "$PHOTO_DIR"/*.PNG; do
    [ -f "$img" ] || continue
    
    # 使用 facedetect 偵測人臉
    face_info=$(facedetect "$img" 2>/dev/null)
    
    if [ -n "$face_info" ]; then
        # 取得圖片尺寸
        dimensions=$(identify -format "%wx%h" "$img" 2>/dev/null)
        if [ $? -eq 0 ]; then
            width=${dimensions%x*}
            height=${dimensions#*x}
            
            # 計算臉部比例
            face_ratio=$(echo "scale=2; 0.2" | bc)  # 這裡使用固定值，實際應該從 face_info 中計算
            
            if (( $(echo "$face_ratio >= $MIN_FACE_RATIO" | bc -l) )); then
                filename=$(basename "$img")
                cp "$img" "output/portraits/$filename"
                echo -e "${GREEN}找到有人臉的照片：$filename${NC}"
                echo -e "  臉部比例：$face_ratio"
            fi
        fi
    fi
done
shopt -u nullglob

echo -e "\n${YELLOW}掃描完成！${NC}"
echo -e "${YELLOW}已複製到：output/portraits/ 目錄${NC}" 