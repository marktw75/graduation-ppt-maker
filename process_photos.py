from PIL import Image
import os
import glob
import shutil

def process_photos(input_dir, output_dir):
    """處理所有照片的方向並壓縮"""
    # 建立處理後的照片目錄
    processed_dir = os.path.join(output_dir, "processed_photos")
    os.makedirs(processed_dir, exist_ok=True)
    
    # 取得所有照片
    photos_dir = os.path.join(input_dir, "photos")
    image_files = sorted(glob.glob(os.path.join(photos_dir, "*.jpg")))
    
    print(f"\n開始處理照片...")
    print(f"原始照片數量：{len(image_files)}")
    
    processed_images = []
    
    for image_path in image_files:
        try:
            print(f"\n處理照片: {image_path}")
            
            # 檢查原始檔案是否存在
            if not os.path.exists(image_path):
                print(f"警告：找不到原始照片 {image_path}")
                continue
            
            with Image.open(image_path) as img:
                print(f"原始尺寸：{img.size}")
                
                # 檢查照片方向
                if hasattr(img, '_getexif'):
                    exif = img._getexif()
                    if exif is not None:
                        orientation = exif.get(274)  # 274 是 EXIF 中的方向標籤
                        if orientation == 6:  # 旋轉90度
                            img = img.rotate(270, expand=True)
                            print("已旋轉照片 270 度")
                        elif orientation == 8:  # 旋轉270度
                            img = img.rotate(90, expand=True)
                            print("已旋轉照片 90 度")
                
                # 計算縮放比例（以較長邊為基準）
                max_size = 1080  # 設定最大邊長
                ratio = max_size / max(img.width, img.height)
                new_width = int(img.width * ratio)
                new_height = int(img.height * ratio)
                
                # 調整大小（保持原始長寬比）
                img = img.resize((new_width, new_height), Image.LANCZOS)
                
                # 建立一個新的 1920x1080 的黑色背景
                background = Image.new('RGB', (1920, 1080), (0, 0, 0))
                
                # 計算置中位置
                paste_x = (1920 - new_width) // 2
                paste_y = (1080 - new_height) // 2
                
                # 將調整後的照片貼到背景上
                background.paste(img, (paste_x, paste_y))
                img = background
                
                print(f"調整後尺寸：{img.size}")
                
                # 取得原始檔名
                original_filename = os.path.basename(image_path)
                
                # 儲存處理後的照片（使用較低的品質）
                output_path = os.path.join(processed_dir, original_filename)
                img.save(output_path, quality=60, optimize=True)
                print(f"已儲存處理後的照片：{output_path}")
                
                # 檢查檔案是否成功建立
                if os.path.exists(output_path):
                    processed_images.append(output_path)
                    print(f"成功加入處理後的照片到列表")
                else:
                    print(f"警告：處理後的照片檔案未成功建立")
        except Exception as e:
            print(f"錯誤：處理照片 {image_path} 時發生錯誤：{e}")
            # 如果處理失敗，使用原始照片
            processed_images.append(image_path)
            print(f"使用原始照片作為備用")
    
    print(f"\n照片處理完成")
    print(f"成功處理的照片數量：{len(processed_images)}")
    
    if len(processed_images) == 0:
        raise Exception("沒有成功處理任何照片，請檢查輸入照片是否正確")
    
    return processed_images

def main():
    # 設定輸入和輸出目錄
    input_dir = "input"
    output_dir = "output"
    
    # 處理照片
    processed_images = process_photos(input_dir, output_dir)
    
    print(f"\n照片處理完成，共處理 {len(processed_images)} 張照片")
    print(f"處理後的照片已儲存在：{os.path.join(output_dir, 'processed_photos')}")

if __name__ == "__main__":
    main() 