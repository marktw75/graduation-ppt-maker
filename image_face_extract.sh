#!/bin/bash

# image_face_extract.sh - 從大圖中找出人臉並裁切成小圖
# 用法：./image_face_extract.sh <輸入圖片> [邊框比例]

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 檢查必要的命令
for cmd in convert python3; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}錯誤：找不到 $cmd 命令${NC}"
        if [ "$cmd" = "convert" ]; then
            echo -e "${YELLOW}請安裝 ImageMagick：${NC}"
            echo -e "${YELLOW}  sudo apt-get update${NC}"
            echo -e "${YELLOW}  sudo apt-get install -y imagemagick${NC}"
        fi
        exit 1
    fi
done

# 檢查是否已安裝 OpenCV
if ! python3 -c "import cv2" &> /dev/null; then
    echo -e "${RED}錯誤：找不到 OpenCV 模組${NC}"
    echo -e "${YELLOW}請安裝 OpenCV：${NC}"
    echo -e "${YELLOW}  pip install opencv-python${NC}"
    exit 1
fi

# 檢查人臉分類器檔案
CASCADE_FILE="/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml"
if [ ! -f "$CASCADE_FILE" ]; then
    echo -e "${RED}錯誤：找不到人臉分類器檔案${NC}"
    echo -e "${YELLOW}請安裝 OpenCV 資料檔：${NC}"
    echo -e "${YELLOW}  sudo apt-get install -y opencv-data${NC}"
    exit 1
fi

# 檢查參數
if [ $# -lt 1 ]; then
    echo -e "${YELLOW}用法：${NC}"
    echo -e "${YELLOW}  ./image_face_extract.sh <輸入圖片> [邊框比例]${NC}"
    echo -e "${YELLOW}範例：${NC}"
    echo -e "${YELLOW}  ./image_face_extract.sh photo.jpg 0.3${NC}"
    echo -e "${YELLOW}  邊框比例預設為 0.3（臉部區域的 30%）${NC}"
    exit 1
fi

INPUT_IMAGE="$1"
PADDING_RATIO=${2:-0.3}  # 預設邊框比例為 0.3

# 檢查輸入檔案是否存在
if [ ! -f "$INPUT_IMAGE" ]; then
    echo -e "${RED}錯誤：找不到輸入圖片 '$INPUT_IMAGE'${NC}"
    exit 1
fi

# 檢查比例是否為有效數字
if ! [[ "$PADDING_RATIO" =~ ^[0-9]*\.?[0-9]+$ ]] || (( $(echo "$PADDING_RATIO <= 0" | bc -l) )); then
    echo -e "${RED}錯誤：邊框比例必須是大於 0 的數字${NC}"
    exit 1
fi

# 建立臨時目錄
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# 建立 Python 腳本來偵測人臉
cat > "$TEMP_DIR/detect_face.py" << EOF
import cv2
import sys
import json

def detect_face(image_path):
    # 讀取圖片
    image = cv2.imread(image_path)
    if image is None:
        return None
    
    # 轉換為灰階圖片
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # 載入人臉分類器
    face_cascade = cv2.CascadeClassifier('$CASCADE_FILE')
    if face_cascade.empty():
        return None
    
    # 偵測人臉
    faces = face_cascade.detectMultiScale(gray, 1.1, 4)
    
    if len(faces) == 0:
        return None
    
    # 取得最大的人臉區域
    max_face = max(faces, key=lambda f: f[2] * f[3])
    x, y, w, h = max_face
    
    # 回傳人臉位置
    return {
        'x': int(x),
        'y': int(y),
        'width': int(w),
        'height': int(h),
        'image_width': image.shape[1],
        'image_height': image.shape[0]
    }

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(json.dumps({'error': '需要圖片路徑參數'}))
        sys.exit(1)
    
    result = detect_face(sys.argv[1])
    if result is None:
        print(json.dumps({'error': '找不到人臉'}))
        sys.exit(1)
    
    print(json.dumps(result))
EOF

echo -e "${YELLOW}正在偵測人臉...${NC}"
face_info=$(python3 "$TEMP_DIR/detect_face.py" "$INPUT_IMAGE")

if [ $? -ne 0 ] || [[ "$face_info" == *"error"* ]]; then
    echo -e "${RED}錯誤：無法偵測到人臉${NC}"
    exit 1
fi

# 解析 JSON 輸出
x=$(echo "$face_info" | python3 -c "import sys, json; print(json.load(sys.stdin)['x'])")
y=$(echo "$face_info" | python3 -c "import sys, json; print(json.load(sys.stdin)['y'])")
width=$(echo "$face_info" | python3 -c "import sys, json; print(json.load(sys.stdin)['width'])")
height=$(echo "$face_info" | python3 -c "import sys, json; print(json.load(sys.stdin)['height'])")
image_width=$(echo "$face_info" | python3 -c "import sys, json; print(json.load(sys.stdin)['image_width'])")
image_height=$(echo "$face_info" | python3 -c "import sys, json; print(json.load(sys.stdin)['image_height'])")

# 計算擴展後的區域
padding=$(echo "$width * $PADDING_RATIO" | bc | cut -d. -f1)
new_x=$((x - padding))
new_y=$((y - padding))
new_width=$((width + 2*padding))
new_height=$((height + 2*padding))

# 確保裁切區域不超出圖片範圍
if [ $new_x -lt 0 ]; then new_x=0; fi
if [ $new_y -lt 0 ]; then new_y=0; fi
if [ $((new_x + new_width)) -gt $image_width ]; then new_width=$((image_width - new_x)); fi
if [ $((new_y + new_height)) -gt $image_height ]; then new_height=$((image_height - new_y)); fi

# 建立輸出檔名
filename=$(basename "$INPUT_IMAGE")
extension="${filename##*.}"
basename="${filename%.*}"
output="${basename}_face.${extension}"

# 裁切圖片
echo -e "${YELLOW}正在裁切人臉區域...${NC}"
echo -e "${YELLOW}裁切區域：${new_width}x${new_height}+${new_x}+${new_y}${NC}"

convert "$INPUT_IMAGE" -crop "${new_width}x${new_height}+${new_x}+${new_y}" "$output"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}處理完成！${NC}"
    echo -e "${YELLOW}輸出檔案：$output${NC}"
else
    echo -e "${RED}裁切失敗${NC}"
    exit 1
fi