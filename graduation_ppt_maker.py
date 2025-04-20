from moviepy.editor import AudioFileClip, ImageClip, concatenate_videoclips, CompositeVideoClip, TextClip, ColorClip
import os
import glob
import shutil

class GraduationPptMaker:
    def __init__(self, input_dir, output_dir):
        self.input_dir = input_dir
        self.output_dir = output_dir
        self.images = self._get_processed_images()
        self.audio_file = os.path.join(input_dir, "bgm.mp3")
        self.text_lines = self._get_text_lines()
        self.audio_duration = self._get_audio_duration()
        self.total_slides = len(self.images)
        
    def _get_processed_images(self):
        """取得處理後的照片檔案"""
        processed_dir = os.path.join(self.output_dir, "processed_photos")
        image_files = sorted(glob.glob(os.path.join(processed_dir, "*.jpg")))
        if not image_files:
            raise Exception("找不到處理後的照片，請先執行 process_photos.py")
        return image_files
    
    def _get_text_lines(self):
        """讀取文字檔案"""
        text_file = os.path.join(self.input_dir, "text.txt")
        if os.path.exists(text_file):
            with open(text_file, "r", encoding="utf-8") as f:
                return [line.strip() for line in f if line.strip()]
        return []
    
    def _get_audio_duration(self):
        """取得音訊檔案的總長度（秒）"""
        if os.path.exists(self.audio_file):
            audio = AudioFileClip(self.audio_file)
            duration = audio.duration
            audio.close()
            return duration
        return 180  # 預設3分鐘
    
    def _calculate_slide_durations(self):
        """計算每張投影片的顯示時間"""
        # 第一張10秒，最後一張15秒
        remaining_time = self.audio_duration - 25
        middle_slides = self.total_slides - 2
        
        if middle_slides > 0:
            middle_duration = remaining_time / middle_slides
        else:
            middle_duration = 0
            
        return [10] + [middle_duration] * middle_slides + [15]
    
    def _distribute_text(self):
        """分配文字到投影片"""
        text_distribution = []
        
        if not self.text_lines:
            # 如果沒有文字，所有投影片都為空
            return [[] for _ in range(self.total_slides)]
            
        if len(self.text_lines) <= self.total_slides:
            # 如果文字行數小於等於投影片數量
            # 將所有文字平均分配到投影片中
            for i in range(self.total_slides - 1):
                if i < len(self.text_lines) - 1:
                    text_distribution.append([self.text_lines[i]])
                else:
                    text_distribution.append([])
            # 最後一行放在最後一張投影片
            text_distribution.append([self.text_lines[-1]])
        else:
            # 如果文字行數大於投影片數量
            # 將文字平均分配到前 n-1 張投影片
            lines_per_slide = len(self.text_lines) // (self.total_slides - 1)
            for i in range(self.total_slides - 1):
                start = i * lines_per_slide
                end = start + lines_per_slide
                text_distribution.append(self.text_lines[start:end])
            # 剩餘的文字都放在最後一張投影片
            text_distribution.append(self.text_lines[(self.total_slides - 1) * lines_per_slide:])
        
        return text_distribution
    
    def create_video(self, output_filename="scout_graduation.mp4"):
        """建立影片檔案"""
        # 計算每張投影片的顯示時間
        slide_durations = self._calculate_slide_durations()
        text_distribution = self._distribute_text()
        
        # 建立影片片段列表
        video_clips = []
        
        for i, (image_path, duration, texts) in enumerate(zip(self.images, slide_durations, text_distribution)):
            # 建立圖片片段
            img_clip = ImageClip(image_path).set_duration(duration)
            
            # 如果有文字，建立文字片段
            if texts:
                # 將所有文字合併成一個段落
                text_content = "\n".join(texts)
                
                # 建立一個黑色半透明的背景
                bg_clip = ColorClip(size=(img_clip.w, 100), color=(0, 0, 0))
                bg_clip = bg_clip.set_opacity(0.7)
                bg_clip = bg_clip.set_position(('center', 'bottom'))
                bg_clip = bg_clip.set_duration(duration)
                
                # 建立文字片段（使用更簡單的設定）
                try:
                    txt_clip = TextClip(
                        text_content,
                        fontsize=24,
                        color='white',
                        size=(img_clip.w - 200, None),
                        method='caption'
                    )
                    txt_clip = txt_clip.set_position(('center', 'bottom')).set_duration(duration)
                    
                    # 將圖片、背景和文字合成
                    video_clip = CompositeVideoClip([img_clip, bg_clip, txt_clip])
                except Exception as e:
                    print(f"警告：無法建立文字片段，將只使用圖片：{e}")
                    video_clip = img_clip
            else:
                video_clip = img_clip
                
            video_clips.append(video_clip)
        
        # 合併所有片段
        final_video = concatenate_videoclips(video_clips)
        
        # 加入背景音樂
        if os.path.exists(self.audio_file):
            audio = AudioFileClip(self.audio_file)
            # 如果音樂長度小於影片長度，循環播放
            if audio.duration < final_video.duration:
                audio = audio.loop(duration=final_video.duration)
            final_video = final_video.set_audio(audio)
        
        # 確保輸出目錄存在
        os.makedirs(self.output_dir, exist_ok=True)
        output_path = os.path.join(self.output_dir, output_filename)
        
        # 輸出影片（使用較低的品質設定）
        final_video.write_videofile(
            output_path,
            fps=10,                    # 進一步降低幀率
            codec='libx264',
            audio_codec='aac',
            temp_audiofile='temp-audio.m4a',
            remove_temp=True,
            threads=4,                 # 使用多執行緒
            preset='ultrafast',        # 使用最快的編碼設定
            bitrate='800k'            # 進一步降低位元率
        )
        
        return output_path

def main():
    # 設定輸入和輸出目錄
    input_dir = "input"
    output_dir = "output"
    
    # 建立影片
    maker = GraduationPptMaker(input_dir, output_dir)
    output_file = maker.create_video()
    
    print(f"\n影片已建立：{output_file}")
    print("\n影片規格：")
    print("- 格式：MP4")
    print("- 解析度：1280x720")
    print("- 幀率：10fps")
    print("- 背景音樂：自動循環播放")
    print("\n您可以直接在網頁上播放此影片，或上傳到任何影片平台。")

if __name__ == "__main__":
    main() 