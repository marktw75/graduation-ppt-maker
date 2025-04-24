# 畢業紀念冊幻燈片製作工具

這是一個用於製作畢業紀念冊幻燈片的工具，可以將照片、文字和音樂組合成一個精美的影片。

## 功能特點

- 自動處理照片，調整大小和格式，預設是1920x1080
- 支援為每張照片添加文字說明
- 自動計算照片顯示時間，配合音樂長度
- 第一張照片顯示 5 秒，最後一張顯示 3 秒，中間照片平均分配剩餘時間
- 支援自定義文字檔案和音樂檔案
- 輸出影片名稱由文字檔案和音樂檔案名稱組合而成

## 系統需求

- Linux 作業系統
- Python 3
- ffmpeg
- ImageMagick

## 安裝依賴

```bash
sudo apt-get update
sudo apt-get install -y ffmpeg imagemagick python3-pip
pip3 install Pillow
```

## 使用說明

1. 初始化專案：
```bash
./graduation-ppt-maker.sh init
```
這會建立必要的目錄結構和範本檔案。

2. 準備檔案：
- 將照片放入 `input/photos` 目錄
- 將背景音樂（music.mp3）放入 `input` 目錄，檔名會是輸出影片檔的一部份
- `input/init.txt` 檔案會自動産生，列出photos下的所有照片檔名
- 複製 `init.txt` 並改名，例如：`cp input/init.txt input/class_2024.txt`。
- 你最後輸出的影片檔就會是 class_2024_music.mp4

- 請將文字說明加入剛才複製的檔案中，例如：class_2024.txt，程式不會動到這個檔案中的文字。
- 編輯你的文字檔，例如：class_2024.txt，每一行的順序及名稱這對應到你的相片，例如
```txt
2022-10-01 10.09.28.jpg                   = 
2022-10-29 09.26.43.jpg                   = 
```
- 在後方加上你的文字說明，例如：
```
2022-10-01 10.09.28.jpg                   = 第二次團集會
2022-10-29 09.26.43.jpg                   = 第三次團集會，開始融入團隊
```

3. 處理照片：
```bash
./graduation-ppt-maker.sh process-photos
```
這會將你所有放在 `input/photos` 目錄下的jpg檔轉成1920x1080，並存到 `output/processed_photos`下。
- 你可以到 `output/processed_photos` 查看相片，這就是最後影片輸出的結果。
- 新增或刪除`input/photos` 目錄下的檔案後，記得先刪除 `output/processed_photos` 再重新執行  process-photos，以便重新處理産生正確的中繼檔給影片用。


4. 產生影片：
```bash
./graduation-ppt-maker.sh generate-video
```

5. 更新影片小技巧
- 直接新增相片到 `input/photos`中，或刪除不想放到影片中的相片。
- 重跑init會更新相片順序及檔名到init.txt中
- 利用 `merge_text.sh` 工具把你寫好的說明文字複製到init.txt中。
- 再利用更新後的init.txt來更新你的說明文件。

## 授權

MIT License
