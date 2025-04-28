#!/bin/bash

# imgtool.sh - 多功能圖片工具
# 支援 info / resize / merge / blend（新：blend 兩張圖片並做 50px 淡化融合）

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 檢查必要的命令
for cmd in convert; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}錯誤：找不到 $cmd 命令${NC}"
        echo -e "${YELLOW}請安裝必要的套件：${NC}"
        echo -e "${YELLOW}  sudo apt-get update${NC}"
        echo -e "${YELLOW}  sudo apt-get install -y imagemagick${NC}"
        exit 1
    fi
done

usage() {
  echo ""
  echo "🖼️ imgtool.sh - 多功能圖片處理工具"
  echo ""
  echo "用法："
  echo "  ./imgtool.sh info <image>"
  echo "  ./imgtool.sh resize <image> <maxdim> [output]"
  echo "  ./imgtool.sh merge <img1> <img2> [...] [--output merged.jpg]"
  echo "  ./imgtool.sh blend <img1> <img2> [--output blended.jpg]"
  echo "  ./imgtool.sh addBottom <image> <height> - 在圖片底部添加指定高度的黑色區域"
  echo "  ./imgtool.sh crop <image> <center_x> <center_y> <radius> - 依指定中心點與半徑裁出正方形圖片"
  echo "  ./imgtool.sh help - 顯示此幫助訊息"
  echo ""
  exit 1
}

if [ $# -lt 2 ]; then
  usage
fi

cmd="$1"
shift

mkdir -p output

if [ "$cmd" = "info" ]; then
  img="$1"
  if [ ! -f "$img" ]; then echo "❌ 找不到檔案：$img"; exit 1; fi
  res=$(identify -format "%wx%h" "$img")
  echo "📐 $img 尺寸：$res"

elif [ "$cmd" = "resize" ]; then
  img="$1"
  height="$2"
  if [ -z "$img" ] || [ -z "$height" ]; then
    echo -e "${RED}錯誤：請提供圖片路徑和目標高度${NC}"
    usage
    exit 1
  fi
  if [ ! -f "$img" ]; then
    echo -e "${RED}錯誤：找不到圖片檔案 '$img'${NC}"
    exit 1
  fi
  if ! [[ "$height" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}錯誤：高度必須是正整數${NC}"
    exit 1
  fi
  output="output/$(basename "${img%.*}")_resized.${img##*.}"
  mkdir -p "$(dirname "$output")"
  convert "$img" -auto-orient -resize "x$height" "$output"
  width=$(identify -format "%w" "$output" 2>/dev/null)
  real_height=$(identify -format "%h" "$output" 2>/dev/null)
  echo -e "✅ 已縮放為 ${width}x${real_height}，輸出：$output"

elif [ "$cmd" = "merge" ]; then
  imgs=()
  out="output/merged.jpg"
  while [[ "$1" ]]; do
    if [[ "$1" == "--output" ]]; then
      shift
      out="output/$1"
    else
      imgs+=("$1")
    fi
    shift
  done

  if [ ${#imgs[@]} -lt 2 ]; then
    echo "❗ 至少需要兩張圖片才能合併"
    exit 1
  fi

  echo "📥 尋找最小高度以統一調整圖片尺寸..."
  min_height=99999
  for img in "${imgs[@]}"; do
    h=$(identify -format "%h" "$img")
    if [ "$h" -lt "$min_height" ]; then
      min_height=$h
    fi
  done

  tmp_dir=$(mktemp -d output/tmp_XXXXXX)
  tmp_imgs=()
  echo "📏 調整所有圖片高度為 $min_height px（已套用 auto-orient）"
  for img in "${imgs[@]}"; do
    tmp_img="$tmp_dir/$(basename "$img")"
    convert "$img" -auto-orient -resize x${min_height} "$tmp_img"
    tmp_imgs+=("$tmp_img")
  done

  echo "🔗 水平合併圖片中..."
  convert "${tmp_imgs[@]}" +append -quality 90 "$out"
  echo "✅ 已合併 ${#imgs[@]} 張圖片 ➜ $out"

  rm -rf "$tmp_dir"
  echo "🧹 已清除暫存資料夾"

elif [ "$cmd" = "blend" ]; then
  img1="$1"
  img2="$2"
  out="output/blended.jpg"
  shift 2

  while [[ "$1" ]]; do
    if [[ "$1" == "--output" ]]; then
      shift
      out="output/$1"
    fi
    shift
  done

  if [ ! -f "$img1" ] || [ ! -f "$img2" ]; then
    echo "❌ 找不到輸入圖片"
    exit 1
  fi

  echo "📥 調整兩張圖片高度一致..."
  h1=$(identify -format "%h" "$img1")
  h2=$(identify -format "%h" "$img2")
  min_h=$((h1<h2 ? h1 : h2))

  tmp_dir=$(mktemp -d output/tmp_blend_XXXXXX)
  left="$tmp_dir/left.jpg"
  right="$tmp_dir/right.jpg"
  mask="$tmp_dir/mask.png"

  convert "$img1" -auto-orient -resize x${min_h} "$left"
  convert "$img2" -auto-orient -resize x${min_h} "$right"

  w1=$(identify -format "%w" "$left")
  w2=$(identify -format "%w" "$right")

  blend_width=50

  echo "🖌️ 製作融合區域（$blend_width px）..."
  convert -size ${blend_width}x${min_h} gradient:white-black "$mask"

  echo "🧩 裁剪與融合..."
  left_main="$tmp_dir/left_main.jpg"
  left_blend="$tmp_dir/left_blend.jpg"
  right_blend="$tmp_dir/right_blend.jpg"
  right_main="$tmp_dir/right_main.jpg"

  convert "$left" -crop "$((w1-blend_width))x${min_h}+0+0" +repage "$left_main"
  convert "$left" -crop "${blend_width}x${min_h}+$((w1-blend_width))+0" +repage "$left_blend"
  convert "$right" -crop "${blend_width}x${min_h}+0+0" +repage "$right_blend"
  convert "$right" -crop "$((w2-blend_width))x${min_h}+$blend_width+0" +repage "$right_main"

  blended_middle="$tmp_dir/blended_middle.jpg"
  convert "$left_blend" "$mask" -compose CopyOpacity -composite "$tmp_dir/left_fade.png"
  convert "$right_blend" "$mask" -compose CopyOpacity -composite -flop "$tmp_dir/right_fade.png"
  convert "$tmp_dir/left_fade.png" "$tmp_dir/right_fade.png" -background none -flatten "$blended_middle"

  echo "🔗 合併左右 + 中間融合..."
  convert "$left_main" "$blended_middle" "$right_main" +append -quality 90 "$out"

  rm -rf "$tmp_dir"
  echo "✅ 已完成融合並輸出到 $out"

elif [ "$cmd" = "addBottom" ]; then
  img="$1"
  height="$2"
  if [ -z "$img" ] || [ -z "$height" ]; then
    echo -e "${RED}錯誤：請提供圖片路徑和要添加的高度${NC}"
    usage
    exit 1
  fi
  if [ ! -f "$img" ]; then
    echo -e "${RED}錯誤：找不到圖片檔案 '$img'${NC}"
    exit 1
  fi
  if ! [[ "$height" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}錯誤：高度必須是正整數${NC}"
    exit 1
  fi

  # 先自動校正方向
  oriented_img=$(mktemp /tmp/oriented_XXXXXX.png)
  convert "$img" -auto-orient "$oriented_img"

  width=$(identify -format "%w" "$oriented_img")
  original_height=$(identify -format "%h" "$oriented_img")
  new_height=$((original_height + height))
  output="${img%.*}_extended.${img##*.}"

  # 產生一張全黑的底部圖
  black_img=$(mktemp /tmp/black_bottom_XXXXXX.png)
  convert -size "${width}x${height}" xc:black "$black_img"

  # 上下疊加
  convert "$oriented_img" "$black_img" -append "$output"
  rm "$black_img" "$oriented_img"

  echo -e "${GREEN}處理完成：${NC}"
  echo -e "${GREEN}原始尺寸：${width}x${original_height}${NC}"
  echo -e "${GREEN}新尺寸：${width}x${new_height}${NC}"
  echo -e "${GREEN}輸出檔案：${output}${NC}"

elif [ "$cmd" = "crop" ]; then
  img="$1"
  center_x="$2"
  center_y="$3"
  radius="$4"
  if [ -z "$img" ] || [ -z "$center_x" ] || [ -z "$center_y" ] || [ -z "$radius" ]; then
    echo -e "${RED}錯誤：請提供圖片路徑、中心點 x、y 及半徑${NC}"
    usage
    exit 1
  fi
  if [ ! -f "$img" ]; then
    echo -e "${RED}錯誤：找不到圖片檔案 '$img'${NC}"
    exit 1
  fi
  if ! [[ "$center_x" =~ ^[0-9]+$ ]] || ! [[ "$center_y" =~ ^[0-9]+$ ]] || ! [[ "$radius" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}錯誤：中心點與半徑必須是正整數${NC}"
    exit 1
  fi

  # 先自動校正方向
  oriented_img=$(mktemp /tmp/oriented_XXXXXX.png)
  convert "$img" -auto-orient "$oriented_img"

  size=$((2 * radius))
  x0=$((center_x - radius))
  y0=$((center_y - radius))

  # 防呆：不能超出邊界
  img_width=$(identify -format "%w" "$oriented_img")
  img_height=$(identify -format "%h" "$oriented_img")
  if [ $x0 -lt 0 ]; then x0=0; fi
  if [ $y0 -lt 0 ]; then y0=0; fi
  if [ $((x0 + size)) -gt $img_width ]; then size=$((img_width - x0)); fi
  if [ $((y0 + size)) -gt $img_height ]; then size=$((img_height - y0)); fi

  output="output/$(basename "${img%.*}")_cropped.${img##*.}"
  mkdir -p "$(dirname "$output")"
  convert "$oriented_img" -crop "${size}x${size}+${x0}+${y0}" +repage "$output"
  rm "$oriented_img"

  echo -e "${GREEN}已裁切為 ${size}x${size}，輸出：$output${NC}"

elif [ "$cmd" = "help" ]; then
  usage
else
  usage
fi
