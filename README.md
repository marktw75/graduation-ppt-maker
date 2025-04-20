# 畢業典禮影片製作工具

這個工具可以將照片和文字轉換成帶有背景音樂的影片。

## 功能特點

- 自動處理照片方向
- 支援文字說明
- 自動加入背景音樂
- 輸出 MP4 格式影片

## 使用方式

1. 準備檔案：
   - 將照片放在 `input/photos` 目錄
   - 將背景音樂 `bgm.mp3` 放在 `input` 目錄
   - 將文字說明 `text.txt` 放在 `input` 目錄

2. 處理照片：
   ```bash
   python process_photos.py
   ```
   處理後的照片會儲存在 `output/processed_photos` 目錄

3. 製作影片：
   ```bash
   python graduation_ppt_maker.py
   ```
   影片會輸出到 `output` 目錄

## 輸出規格

- 格式：MP4
- 解析度：1280x720
- 幀率：10fps
- 背景音樂：自動循環播放

## 注意事項

- 照片處理和影片製作是分開的兩個步驟
- 如果修改了照片，需要重新執行 `process_photos.py`
- 文字會自動分配到各張照片中
- 第一張照片顯示 10 秒，最後一張顯示 15 秒，中間的照片平均分配剩餘時間

## 授權

MIT License
