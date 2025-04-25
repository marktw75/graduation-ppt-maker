#!/bin/bash

# imgtool.sh - 多功能圖片工具
# 支援 info / resize / merge / blend（新：blend 兩張圖片並做 50px 淡化融合）

usage() {
  echo ""
  echo "🖼️ imgtool.sh - 多功能圖片處理工具"
  echo ""
  echo "用法："
  echo "  ./imgtool.sh info <image>"
  echo "  ./imgtool.sh resize <image> <maxdim> [output]"
  echo "  ./imgtool.sh merge <img1> <img2> [...] [--output merged.jpg]"
  echo "  ./imgtool.sh blend <img1> <img2> [--output blended.jpg]"
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
  maxdim="$2"
  output="$3"
  if [ ! -f "$img" ]; then echo "❌ 找不到檔案：$img"; exit 1; fi
  if [ -z "$output" ]; then
    ext="${img##*.}"
    base="${img%.*}"
    output="output/${base}_resized.${ext}"
  fi
  convert "$img" -resize "${maxdim}x${maxdim}" -quality 90 "$output"
  res=$(identify -format "%wx%h" "$output")
  echo "✅ 已縮放為 $res，輸出：$output"

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
else
  usage
fi
