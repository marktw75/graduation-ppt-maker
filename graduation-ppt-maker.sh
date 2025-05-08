#!/bin/bash

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 檢查必要的命令
for cmd in ffmpeg ffprobe convert; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}錯誤：找不到 $cmd 命令${NC}"
        echo -e "${YELLOW}請安裝必要的套件：${NC}"
        echo -e "${YELLOW}  sudo apt-get update${NC}"
        echo -e "${YELLOW}  sudo apt-get install -y ffmpeg imagemagick${NC}"
        exit 1
    fi
done

# 檢查Python環境
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}錯誤：找不到 python3 命令${NC}"
    exit 1
fi

# 顯示幫助訊息
show_help() {
    echo -e "${GREEN}畢業紀念冊幻燈片製作工具${NC}"
    echo "用法: $0 [命令]"
    echo
    echo "可用命令:"
    echo "  init          - 建立輸入資料夾結構和範本檔案"
    echo "  process-photos - 處理照片"
    echo "  generate-video - 產生影片"
    echo "  help          - 顯示此幫助訊息"
}

# 建立輸入資料夾結構
create_input_folder() {
    echo -e "${GREEN}正在建立輸入資料夾結構...${NC}"
    
    # 建立必要的目錄
    mkdir -p input/photos
    mkdir -p input/music
    
    # 建立文字範本
    cat > input/init.txt << 'EOF'
# ============================================
# 畢業紀念冊幻燈片文字設定
# ============================================
# 使用說明：
# 1. 每張照片後面可以輸入對應的文字
# 2. 如果不需要文字，請保留空白
# 3. 文字會以白色字體顯示在照片底部
# 4. 建議每行文字不要超過 30 個字
# ============================================

EOF
    
    # 檢查是否有照片檔案
    if [ -d "input/photos" ] && [ -n "$(ls -A input/photos/*.jpg 2>/dev/null)" ]; then
        # 初始化變數
        local photo_count=0
        local photos=()
        declare -A timing_map
        local fixed_time=0
        local count_fixed=0
        
        # 讀取 timing.txt（如果存在）
        if [ -f "input/timing.txt" ]; then
            while IFS='=' read -r filename duration; do
                filename=$(echo "$filename" | xargs)
                duration=$(echo "$duration" | xargs)
                if [[ -n "$filename" && -n "$duration" ]]; then
                    timing_map["$filename"]=$duration
                fi
            done < "input/timing.txt"
        fi
        
        # 收集照片資訊
        for photo in input/photos/*.jpg; do
            photos+=("$photo")
            photo_name=$(basename "$photo")
            if [ -n "${timing_map[$photo_name]}" ]; then
                fixed_time=$(echo "$fixed_time + ${timing_map[$photo_name]}" | bc)
                ((count_fixed++))
            fi
            printf "%-40s = \n" "$photo_name" >> input/init.txt
            ((photo_count++))
        done
        
        # 檢查音樂檔案
        local music_files=(input/music/*.mp3)
        local music_duration=0
        if [ ${#music_files[@]} -gt 0 ]; then
            music_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${music_files[0]}")
            music_duration=${music_duration%.*}
        fi
        
        # 計算時間分配
        local remaining_photos=$((photo_count - count_fixed - 2))
        local START_FIRST_SLIDE=10
        local END_LAST_SLIDE=15
        local remaining_time=$((music_duration - START_FIRST_SLIDE - END_LAST_SLIDE - ${fixed_time%.*}))
        
        local avg_time=1.5
        if [ "$remaining_photos" -gt 0 ]; then
            avg_time=$(echo "scale=2; $remaining_time / $remaining_photos" | bc)
        fi
        
        # 輸出統計資訊（只輸出一次）
        echo "📋 總相片數：$photo_count"
        echo "🕒 背景音樂長度：${music_duration}s"
        echo "📄 有設定時間的相片：$count_fixed 張，共 ${fixed_time}s"
        echo "⏳ 剩餘平均分配每張：${avg_time}s"
        
        # 加入照片統計資訊
        echo "" >> input/init.txt
        echo "# 照片統計" >> input/init.txt
        echo "# 總照片數：$photo_count" >> input/init.txt
        echo "# 第一張照片顯示時間：5 秒" >> input/init.txt
        echo "# 最後一張照片顯示時間：10 秒" >> input/init.txt
        echo "# 中間照片平均顯示時間：根據音樂長度自動計算" >> input/init.txt
        
        echo -e "${GREEN}已建立文字範本，包含 ${YELLOW}$photo_count${GREEN} 張照片${NC}"
    else
        echo -e "${YELLOW}提示：請將照片放入 input/photos 目錄中${NC}"
    fi
    
    echo -e "${GREEN}已建立輸入資料夾結構和範本檔案${NC}"
    echo -e "${YELLOW}請將照片放入 input/photos 目錄中${NC}"
    echo -e "${YELLOW}請將背景音樂放入 input/music 目錄中（支援 .mp3 格式）${NC}"
    echo -e "${YELLOW}請編輯 input/init.txt 檔案以設定幻燈片文字${NC}"
    echo -e "${YELLOW}完成編輯後，請複製 init.txt 並改名，例如：${NC}"
    echo -e "${YELLOW}  cp input/init.txt input/class_2024.txt${NC}"
    echo -e "${YELLOW}檔名會成為輸出影片名稱的一部分，例如：${NC}"
    echo -e "${YELLOW}  class_2024_music.mp4${NC}"
}

# 處理照片
process_photos_command() {
    echo -e "${GREEN}正在處理照片...${NC}"
    
    # 檢查Python環境
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}錯誤：找不到 python3 命令${NC}"
        exit 1
    fi
    
    # 執行Python腳本
    python3 process_photos.py
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}照片處理完成${NC}"
    else
        echo -e "${RED}照片處理失敗${NC}"
        exit 1
    fi
}

# 檢查必要檔案
check_required_files() {
    local has_error=0
    
    # 檢查處理後的照片目錄
    if [ ! -d "output/processed_photos" ] || [ -z "$(ls -A output/processed_photos)" ]; then
        echo -e "${RED}錯誤：找不到處理後的照片，請先執行 process-photos 命令${NC}"
        has_error=1
    fi
    
    # 檢查文字檔案（排除 init.txt 和 timing.txt）
    local text_files=()
    for file in input/*.txt; do
        local filename=$(basename "$file")
        if [[ "$filename" != "init.txt" && "$filename" != "timing.txt" ]]; then
            text_files+=("$file")
        fi
    done
    
    if [ ${#text_files[@]} -eq 0 ]; then
        echo -e "${RED}錯誤：找不到文字檔案，請複製並編輯 input/init.txt${NC}"
        has_error=1
    elif [ ${#text_files[@]} -gt 1 ]; then
        echo -e "${YELLOW}警告：找到多個文字檔案，將使用 ${text_files[0]}${NC}"
    fi
    
    # 檢查音樂檔案
    local music_files=(input/music/*.mp3)
    if [ ${#music_files[@]} -eq 0 ]; then
        echo -e "${RED}錯誤：找不到音樂檔案，請在 input/music 目錄中放入 .mp3 檔案${NC}"
        has_error=1
    elif [ ${#music_files[@]} -gt 1 ]; then
        echo -e "${YELLOW}警告：找到多個音樂檔案，將使用 ${music_files[0]}${NC}"
    fi
    
    return $has_error
}

# 產生影片
generate_video() {
    echo -e "${GREEN}正在準備產生影片...${NC}"
    
    # 檢查必要檔案
    check_required_files
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # 取得文字檔案
    local text_file
    for file in input/*.txt; do
        local filename=$(basename "$file")
        if [[ "$filename" != "init.txt" && "$filename" != "timing.txt" ]]; then
            text_file="$file"
            break
        fi
    done
    
    if [ -z "$text_file" ]; then
        echo -e "${RED}錯誤：找不到文字檔案，請複製並編輯 input/init.txt${NC}"
        exit 1
    fi
    
    local text_filename=$(basename "$text_file" .txt)
    echo -e "${GREEN}使用文字檔案：${text_file}${NC}"
    
    # 取得音樂檔案
    local music_file=$(ls input/music/*.mp3 | head -n 1)
    local music_filename=$(basename "$music_file" .mp3)
    echo -e "${GREEN}使用音樂檔案：${music_file}${NC}"
    
    # 組合輸出檔名
    local output_video="${text_filename}_${music_filename}.mp4"
    echo -e "${GREEN}輸出檔名：${output_video}${NC}"
    
    # 建立臨時目錄
    local temp_dir="output/temp"
    mkdir -p "$temp_dir"
    
    # 建立照片列表檔案
    local concat_file="$temp_dir/concat.txt"
    > "$concat_file"
    
    # 計算照片數量
    local photo_count=$(ls -1 output/processed_photos/*.jpg | wc -l)
    echo -e "${GREEN}照片數量：${photo_count} 張${NC}"
    
    # 讀取文字內容
    local texts=()
    while IFS= read -r line; do
        # 跳過註解行
        if [[ "$line" =~ ^# ]]; then
            continue
        fi
        # 處理照片列表行（包含等號的行）
        if [[ "$line" =~ = ]]; then
            # 提取等號後面的文字
            text=$(echo "$line" | sed -E 's/^[^=]*=[[:space:]]*(.*)$/\1/')
            texts+=("$text")
        fi
    done < "$text_file"
    
    echo -e "${GREEN}讀取到的文字數量：${#texts[@]}${NC}"
    
    # 讀取 timing.txt 的設定
    declare -A timing_map
    if [ -f "input/timing.txt" ]; then
        while IFS='=' read -r filename duration; do
            filename=$(echo "$filename" | xargs)
            duration=$(echo "$duration" | xargs)
            if [[ -n "$filename" && -n "$duration" ]]; then
                timing_map["$filename"]=$duration
            fi
        done < "input/timing.txt"
    fi
    
    # 計算每張照片的顯示時間
    local music_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$music_file")
    local default_first_duration=5  # 第一張照片預設顯示 5 秒
    local default_last_duration=10   # 最後一張照片預設顯示 10 秒
    
    # 計算已設定時間的照片總時間
    local fixed_time=0
    local count_fixed=0
    for duration in "${timing_map[@]}"; do
        fixed_time=$(echo "$fixed_time + $duration" | bc)
        ((count_fixed++))
    done
    
    # 計算剩餘照片的平均時間
    local remaining_photos=$((photo_count - count_fixed))  # 不再減去第一張和最後一張
    local remaining_time=$(echo "scale=2; $music_duration - $fixed_time" | bc)
    local middle_duration=$(echo "scale=2; $remaining_time / $remaining_photos" | bc)
    
    echo -e "${GREEN}音樂長度：${music_duration} 秒${NC}"
    echo -e "${GREEN}第一張照片預設時間：${default_first_duration} 秒${NC}"
    echo -e "${GREEN}最後一張照片預設時間：${default_last_duration} 秒${NC}"
    echo -e "${GREEN}中間照片平均顯示時間：${middle_duration} 秒${NC}"
    echo -e "${GREEN}已設定時間的照片：${count_fixed} 張，共 ${fixed_time} 秒${NC}"
    
    # 收集照片處理資訊
    local photo_info=()
    
    # 為每張照片建立過渡效果
    local i=0
    for photo in output/processed_photos/*.jpg; do
        local output="$temp_dir/photo_$i.mp4"
        local photo_name=$(basename "$photo")
        
        # 決定顯示時間
        local duration
        if [ -n "${timing_map[$photo_name]}" ]; then
            # 如果有在 timing.txt 中設定時間，優先使用設定的時間
            duration=${timing_map[$photo_name]}
        elif [ $i -eq 0 ]; then
            # 第一張照片，使用預設值
            duration=$default_first_duration
        elif [ $i -eq $((photo_count-1)) ]; then
            # 最後一張照片，使用預設值
            duration=$default_last_duration
        else
            # 其他照片使用計算出的平均時間
            duration=$middle_duration
        fi
        
        # 決定要顯示的文字
        local text=""
        if [ $i -eq 0 ] && [ ${#texts[@]} -gt 0 ]; then
            # 第一張照片顯示第一行文字
            text="${texts[0]}"
        elif [ $i -eq $((photo_count-1)) ] && [ ${#texts[@]} -gt 0 ]; then
            # 最後一張照片顯示最後一行文字
            text="${texts[${#texts[@]}-1]}"
        elif [ $i -lt ${#texts[@]} ]; then
            # 中間的照片如果有對應的文字就顯示
            text="${texts[$i]}"
        fi
        
        # 收集照片資訊
        if [ -n "$text" ]; then
            photo_info+=("$((i+1))/$photo_count ${photo_name} ${duration}s ${text}")
        else
            photo_info+=("$((i+1))/$photo_count ${photo_name} ${duration}s")
        fi
        
        # 使用 ffmpeg 建立帶有過渡效果和文字的影片片段
        if [ -n "$text" ]; then
            # 有文字的情況
            # 取得照片寬度
            width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$photo")
            # 根據寬度計算字體大小（1920寬度用48，其他按比例縮放）
            fontsize=$((width * 60 / 1920))
            # 確保字體大小在合理範圍內
            if [ $fontsize -lt 48 ]; then
                fontsize=48
            elif [ $fontsize -gt 96 ]; then
                fontsize=96
            fi
            
            ffmpeg -loop 1 -i "$photo" \
                -vf "drawtext=text='$text':fontcolor=white:fontsize=$fontsize:box=1:boxcolor=black@0.7:boxborderw=10:x=(w-text_w)/2:y=h-th-50" \
                -c:v libx264 -t "$duration" -pix_fmt yuv420p "$output"
        else
            # 沒有文字的情況
            ffmpeg -loop 1 -i "$photo" -c:v libx264 -t "$duration" -pix_fmt yuv420p "$output"
        fi
        
        # 將影片片段加入列表（使用相對路徑）
        echo "file 'photo_$i.mp4'" >> "$concat_file"
        
        i=$((i+1))
    done
    
    # 輸出所有照片處理資訊
    echo -e "${GREEN}照片處理資訊：${NC}"
    for info in "${photo_info[@]}"; do
        echo -e "${GREEN}$info${NC}"
    done
    
    # 複製音樂檔案到臨時目錄
    cp "$music_file" "$temp_dir/music.mp3"
    
    # 確保輸出目錄存在
    mkdir -p output
    
    # 合併所有影片片段
    cd "$temp_dir" && ffmpeg -f concat -safe 0 -i concat.txt -i music.mp3 -c:v copy -c:a aac -shortest "$output_video"
    mv "$output_video" "../$output_video"
    cd - > /dev/null
    
    # 清理臨時檔案
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}影片產生完成：output/$output_video${NC}"
}

# 主程式
case "$1" in
    init)
        create_input_folder
        ;;
    process-photos)
        process_photos_command
        ;;
    generate-video)
        generate_video
        ;;
    help|"")
        show_help
        ;;
    *)
        echo -e "${RED}錯誤：未知的命令 '$1'${NC}"
        show_help
        exit 1
        ;;
esac 