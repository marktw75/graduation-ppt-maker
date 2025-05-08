# 圖片處理工具集

這是一系列用於圖片處理的命令列工具，提供多種圖片處理功能。

## 安裝需求

- ImageMagick
- Python 3
- OpenCV (用於人臉偵測)

安裝必要套件：
```bash
sudo apt-get update
sudo apt-get install -y imagemagick opencv-data
pip install opencv-python
```

## 工具說明

### 1. 人臉偵測與裁切 (face-extract)

從大圖中找出人臉並裁切成小圖。

```bash
./imgtool.sh face-extract <輸入圖片> [邊框比例]
```

參數說明：
- `<輸入圖片>`：要處理的圖片檔案
- `[邊框比例]`：可選，預設為 0.3（臉部區域的 30%）

範例：
```bash
./imgtool.sh face-extract photo.jpg
./imgtool.sh face-extract photo.jpg 0.5  # 使用 50% 的邊框
```

### 2. 圓形裁切 (circle)

將圖片裁切成圓形。

```bash
./imgtool.sh circle <輸入圖片>
```

範例：
```bash
./imgtool.sh circle photo.jpg
```

### 3. 區域變黑 (black)

將指定區域變為黑色。

```bash
./imgtool.sh black <輸入圖片> <x> <y> <寬度> <高度>
```

參數說明：
- `<x>`：起始 x 座標
- `<y>`：起始 y 座標
- `<寬度>`：要變黑的區域寬度
- `<高度>`：要變黑的區域高度

範例：
```bash
./imgtool.sh black photo.jpg 100 100 200 200
```

### 4. 中心點貼圖 (paste)

將小圖以中心點對準大圖的指定座標進行貼圖。

```bash
./imgtool.sh paste <大圖> <小圖> <x座標> <y座標> [比例]
```

參數說明：
- `<大圖>`：背景圖片
- `<小圖>`：要貼上的圖片
- `<x座標>`：目標 x 座標
- `<y座標>`：目標 y 座標
- `[比例]`：可選，小圖相對於大圖的比例（預設 0.25）

範例：
```bash
./imgtool.sh paste background.jpg small.jpg 800 400
./imgtool.sh paste background.jpg small.jpg 800 400 0.3  # 使用 30% 的比例
```

## 注意事項

1. 所有工具都會保留原始圖片，並產生新的輸出檔案
2. 輸出檔案會自動加上對應的後綴（例如：`_face`、`_circle` 等）
3. 支援的圖片格式：JPG、PNG、GIF 等常見格式

## 錯誤處理

- 如果找不到必要的命令或套件，工具會提示安裝方法
- 如果處理過程中發生錯誤，會顯示錯誤訊息並退出
- 所有工具都會檢查輸入參數的有效性
