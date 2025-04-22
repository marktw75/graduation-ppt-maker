#!/bin/bash

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 顯示幫助訊息
show_help() {
    echo -e "${YELLOW}文字檔案合併工具${NC}"
    echo "用法: $0 [範本檔案] [文字檔案]"
    echo
    echo "範例:"
    echo "  $0 input/init.txt input/蔡孟哲童軍活動.txt"
    echo
    echo "說明:"
    echo "  1. 範本檔案包含所有照片檔名"
    echo "  2. 文字檔案包含照片對應的文字"
    echo "  3. 合併後會保留範本檔案的順序和格式"
}

# 檢查參數
if [ $# -ne 2 ]; then
    echo -e "${RED}錯誤：需要兩個參數${NC}"
    show_help
    exit 1
fi

template_file="$1"
text_file="$2"

# 檢查檔案是否存在
if [ ! -f "$template_file" ]; then
    echo -e "${RED}錯誤：找不到範本檔案 $template_file${NC}"
    exit 1
fi

if [ ! -f "$text_file" ]; then
    echo -e "${RED}錯誤：找不到文字檔案 $text_file${NC}"
    exit 1
fi

# 建立臨時檔案
temp_file=$(mktemp)

# 讀取文字檔案的內容到關聯陣列
declare -A text_map
while IFS= read -r line; do
    # 跳過註解行
    if [[ "$line" =~ ^# ]]; then
        continue
    fi
    # 處理包含等號的行
    if [[ "$line" =~ = ]]; then
        # 提取照片檔名和文字
        photo=$(echo "$line" | sed -E 's/^([^=]*)=.*$/\1/' | xargs)
        text=$(echo "$line" | sed -E 's/^[^=]*=[[:space:]]*(.*)$/\1/')
        if [ -n "$photo" ]; then
            text_map["$photo"]="$text"
        fi
    fi
done < "$text_file"

# 處理範本檔案
while IFS= read -r line; do
    # 如果是註解行，直接輸出
    if [[ "$line" =~ ^# ]]; then
        echo "$line" >> "$temp_file"
        continue
    fi
    
    # 處理包含等號的行
    if [[ "$line" =~ = ]]; then
        # 提取照片檔名和原始格式
        photo=$(echo "$line" | sed -E 's/^([^=]*)=.*$/\1/' | xargs)
        original_format=$(echo "$line" | sed -E 's/^([^=]*)=.*$/\1/')
        if [ -n "$photo" ]; then
            # 如果有對應的文字，就合併
            if [ -n "${text_map[$photo]}" ]; then
                # 保持原始格式的長度
                printf "%-40s = %s\n" "$original_format" "${text_map[$photo]}" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi
    else
        echo "$line" >> "$temp_file"
    fi
done < "$template_file"

# 覆蓋原始範本檔案
mv "$temp_file" "$template_file"

echo -e "${GREEN}檔案合併完成：$template_file${NC}"
echo -e "${GREEN}已將文字合併到範本檔案中${NC}" 