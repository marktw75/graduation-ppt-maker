#!/bin/bash

# imgtool.sh - 多功能圖片處理工具
# 用法：./imgtool.sh <命令> [參數...]

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

# 顯示使用說明
show_usage() {
    echo -e "${YELLOW}用法：${NC}"
    echo -e "${YELLOW}  ./imgtool.sh <命令> [參數...]${NC}"
    echo -e "${YELLOW}可用命令：${NC}"
    echo -e "${YELLOW}  face-extract <輸入圖片> [邊框比例]${NC}"
    echo -e "${YELLOW}  circle <輸入圖片>${NC}"
    echo -e "${YELLOW}  black <輸入圖片> <x> <y> <寬度> <高度>${NC}"
    echo -e "${YELLOW}  paste <大圖> <小圖> <x座標> <y座標> [比例]${NC}"
    echo -e "${YELLOW}使用 './imgtool.sh <命令> --help' 查看特定命令的詳細說明${NC}"
}

# 檢查參數
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

# 建立臨時目錄
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# 人臉偵測與裁切
face_extract() {
    if [ "$1" = "--help" ]; then
        echo -e "${YELLOW}用法：${NC}"
        echo -e "${YELLOW}  ./imgtool.sh face-extract <輸入圖片> [邊框比例]${NC}"
        echo -e "${YELLOW}範例：${NC}"
        echo -e "${YELLOW}  ./imgtool.sh face-extract photo.jpg 0.3${NC}"
        exit 0
    fi

    if [ $# -lt 1 ]; then
        echo -e "${RED}錯誤：需要輸入圖片${NC}"
        exit 1
    fi

    INPUT_IMAGE="$1"
    PADDING_RATIO=${2:-0.3}

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
}

# 圓形裁切
circle() {
    if [ "$1" = "--help" ]; then
        echo -e "${YELLOW}用法：${NC}"
        echo -e "${YELLOW}  ./imgtool.sh circle <輸入圖片>${NC}"
        echo -e "${YELLOW}範例：${NC}"
        echo -e "${YELLOW}  ./imgtool.sh circle photo.jpg${NC}"
        exit 0
    fi

    if [ $# -lt 1 ]; then
        echo -e "${RED}錯誤：需要輸入圖片${NC}"
        exit 1
    fi

    input="$1"
    if [ ! -f "$input" ]; then
        echo -e "${RED}錯誤：找不到輸入圖片 '$input'${NC}"
        exit 1
    fi

    # 建立輸出檔名
    filename=$(basename "$input")
    extension="${filename##*.}"
    basename="${filename%.*}"
    output="${basename}_circle.png"

    # 取得圖片尺寸
    dimensions=$(identify -format "%wx%h" "$input")
    width=${dimensions%x*}
    height=${dimensions#*x}

    # 計算圓形遮罩
    size=$((width < height ? width : height))
    radius=$((size / 2))

    # 建立圓形遮罩
    convert -size "${size}x${size}" xc:none -fill black -draw "circle $radius,$radius $radius,0" "$TEMP_DIR/mask.png"

    # 裁切並套用遮罩
    convert "$input" -resize "${size}x${size}^" -gravity center -extent "${size}x${size}" "$TEMP_DIR/resized.png"
    convert "$TEMP_DIR/resized.png" "$TEMP_DIR/mask.png" -alpha off -compose copy_opacity -composite "$output"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}處理完成！${NC}"
        echo -e "${YELLOW}輸出檔案：$output${NC}"
    else
        echo -e "${RED}處理失敗${NC}"
        exit 1
    fi
}

# 區域變黑
black() {
    if [ "$1" = "--help" ]; then
        echo -e "${YELLOW}用法：${NC}"
        echo -e "${YELLOW}  ./imgtool.sh black <輸入圖片> <x> <y> <寬度> <高度>${NC}"
        echo -e "${YELLOW}範例：${NC}"
        echo -e "${YELLOW}  ./imgtool.sh black photo.jpg 100 100 200 200${NC}"
        exit 0
    fi

    if [ $# -lt 5 ]; then
        echo -e "${RED}錯誤：需要所有必要參數${NC}"
        exit 1
    fi

    input="$1"
    x="$2"
    y="$3"
    width="$4"
    height="$5"

    if [ ! -f "$input" ]; then
        echo -e "${RED}錯誤：找不到輸入圖片 '$input'${NC}"
        exit 1
    fi

    # 檢查座標和尺寸是否為數字
    for param in "$x" "$y" "$width" "$height"; do
        if ! [[ "$param" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}錯誤：座標和尺寸必須是正整數${NC}"
            exit 1
        fi
    done

    # 建立輸出檔名
    filename=$(basename "$input")
    extension="${filename##*.}"
    basename="${filename%.*}"
    output="${basename}_black.${extension}"

    # 處理圖片
    convert "$input" -fill black -draw "rectangle $x,$y $((x+width)),$((y+height))" "$output"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}處理完成！${NC}"
        echo -e "${YELLOW}輸出檔案：$output${NC}"
    else
        echo -e "${RED}處理失敗${NC}"
        exit 1
    fi
}

# 中心點貼圖
paste() {
    if [ "$1" = "--help" ]; then
        echo -e "${YELLOW}用法：${NC}"
        echo -e "${YELLOW}  ./imgtool.sh paste <大圖> <小圖> <x座標> <y座標> [比例]${NC}"
        echo -e "${YELLOW}範例：${NC}"
        echo -e "${YELLOW}  ./imgtool.sh paste background.jpg small.jpg 800 400 0.25${NC}"
        exit 0
    fi

    if [ $# -lt 4 ]; then
        echo -e "${RED}錯誤：需要所有必要參數${NC}"
        exit 1
    fi

    big_image="$1"
    small_image="$2"
    x="$3"
    y="$4"
    scale=${5:-0.25}

    # 檢查檔案是否存在
    if [ ! -f "$big_image" ]; then
        echo -e "${RED}錯誤：找不到大圖 '$big_image'${NC}"
        exit 1
    fi
    if [ ! -f "$small_image" ]; then
        echo -e "${RED}錯誤：找不到小圖 '$small_image'${NC}"
        exit 1
    fi

    # 檢查座標是否為數字
    if ! [[ "$x" =~ ^[0-9]+$ ]] || ! [[ "$y" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}錯誤：座標必須是正整數${NC}"
        exit 1
    fi

    # 檢查比例是否為有效數字
    if ! [[ "$scale" =~ ^[0-9]*\.?[0-9]+$ ]] || (( $(echo "$scale <= 0" | bc -l) )) || (( $(echo "$scale >= 1" | bc -l) )); then
        echo -e "${RED}錯誤：比例必須是 0 到 1 之間的數字${NC}"
        exit 1
    fi

    # 取得大圖尺寸
    big_dimensions=$(identify -format "%wx%h" "$big_image")
    big_width=${big_dimensions%x*}
    big_height=${big_dimensions#*x}

    # 檢查座標是否在圖片範圍內
    if [ "$x" -ge "$big_width" ] || [ "$y" -ge "$big_height" ]; then
        echo -e "${RED}錯誤：座標超出大圖範圍${NC}"
        echo -e "${YELLOW}大圖尺寸：${big_width}x${big_height}${NC}"
        exit 1
    fi

    # 計算目標尺寸（以大圖最長邊為基準）
    if [ "$big_width" -gt "$big_height" ]; then
        target_size=$(echo "$big_width * $scale" | bc | cut -d. -f1)
    else
        target_size=$(echo "$big_height * $scale" | bc | cut -d. -f1)
    fi

    # 縮放小圖
    echo -e "${YELLOW}縮放小圖...${NC}"
    resized_small="$TEMP_DIR/resized_small.png"
    convert "$small_image" -resize "${target_size}x${target_size}>" "$resized_small"
    small_dimensions=$(identify -format "%wx%h" "$resized_small")
    small_width=${small_dimensions%x*}
    small_height=${small_dimensions#*x}

    # 計算小圖中心點對齊的位置
    offset_x=$((x - small_width/2))
    offset_y=$((y - small_height/2))

    # 建立輸出檔名
    filename=$(basename "$big_image")
    extension="${filename##*.}"
    basename="${filename%.*}"
    output="${basename}_pasted.${extension}"

    # 使用 convert 命令處理圖片
    echo -e "${YELLOW}處理圖片中...${NC}"
    echo -e "${YELLOW}大圖尺寸：${big_width}x${big_height}${NC}"
    echo -e "${YELLOW}縮放比例：${scale}${NC}"
    echo -e "${YELLOW}目標尺寸：${target_size}${NC}"
    echo -e "${YELLOW}小圖尺寸：${small_width}x${small_height}${NC}"
    echo -e "${YELLOW}目標位置：($x,$y)${NC}"
    echo -e "${YELLOW}實際偏移：($offset_x,$offset_y)${NC}"

    convert "$big_image" "$resized_small" -geometry "+${offset_x}+${offset_y}" -composite "$output"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}處理完成！${NC}"
        echo -e "${YELLOW}輸出檔案：$output${NC}"
    else
        echo -e "${RED}處理失敗${NC}"
        exit 1
    fi
}

# 根據命令執行對應的函數
case "$1" in
    "face-extract")
        shift
        face_extract "$@"
        ;;
    "circle")
        shift
        circle "$@"
        ;;
    "black")
        shift
        black "$@"
        ;;
    "paste")
        shift
        paste "$@"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
