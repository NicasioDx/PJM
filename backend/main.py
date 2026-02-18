import os
# ✅ บรรทัดที่สำคัญที่สุด: ต้องอยู่ก่อน import torch หรือ ultralytics
os.environ["TORCH_FORCE_WEIGHTS_ONLY_LOAD"] = "0"

import cv2
import base64
import threading
import time
import torch
import functools

torch.load = functools.partial(torch.load, weights_only=False)
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
from ultralytics import YOLO 

# นำเข้าฟังก์ชันจาก database.py
from database import init_db, add_camera_to_db, get_all_cameras

app = FastAPI()

# ปลดล็อก CORS เพื่อให้ Flutter Web เข้าถึงได้
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. โหลดโมเดล YOLOv8n (ตอนนี้จะผ่านฉลุยเพราะบรรทัด os.environ ด้านบน)
model = YOLO('yolov8n.pt')

# เริ่มต้นฐานข้อมูล
@app.on_event("startup")
def startup_event():
    init_db()

# --- Models ---
class CameraRegister(BaseModel):
    camera_name: str
    ip: str
    username: str
    password: str

class CameraRequest(BaseModel):
    ip: str
    username: str
    password: str

# --- Camera Manager ---
os.environ["OPENCV_FFMPEG_CAPTURE_OPTIONS"] = "rtsp_transport;tcp"

class CameraStream:
    def __init__(self):
        self.cap = None
        self.frame = None
        self.status = False
        self.current_url = ""
        self.lock = threading.Lock()
        self.thread = threading.Thread(target=self.update, daemon=True)
        self.thread.start()

    def update(self):
        while True:
            if self.cap and self.cap.isOpened():
                success, frame = self.cap.read()
                if success:
                    with self.lock:
                        self.frame = frame.copy()
                        self.status = True
                else:
                    self.status = False
                    time.sleep(1)
            else:
                time.sleep(0.1)

    def change_camera(self, url):
        if self.current_url != url:
            with self.lock:
                print(f"🔄 Switching camera to: {url}")
                if self.cap:
                    self.cap.release()
                self.current_url = url
                self.cap = cv2.VideoCapture(url, cv2.CAP_FFMPEG)
                self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

cam_manager = CameraStream()

# --- API Endpoints ---

@app.post("/add_camera")
async def add_camera(data: CameraRegister):
    success = add_camera_to_db(data.camera_name, data.ip, data.username, data.password)
    if success:
        return {"status": "success", "message": "Camera added"}
    raise HTTPException(status_code=500, detail="Failed to add camera")

@app.get("/get_cameras")
async def get_cameras():
    return get_all_cameras()

@app.post("/get_frame")
async def get_frame(data: CameraRequest):
    target_url = f"rtsp://{data.username}:{data.password}@{data.ip}:554/stream2"
    cam_manager.change_camera(target_url)

    if cam_manager.status and cam_manager.frame is not None:
        with cam_manager.lock:
            input_frame = cam_manager.frame.copy()

        # ประมวลผล AI
        results = model(input_frame, verbose=False, conf=0.4)
        annotated_frame = results[0].plot()

        # ย่อขนาดและเข้ารหัส
        resized_frame = cv2.resize(annotated_frame, (640, 360))
        _, buffer = cv2.imencode('.jpg', resized_frame, [cv2.IMWRITE_JPEG_QUALITY, 70])
        jpg_as_text = base64.b64encode(buffer).decode('utf-8')
        
        return {
            "status": "success", 
            "image": jpg_as_text,
            "count": len(results[0].boxes)
        }
    
    return {"status": "error", "message": "Connecting..."}

@app.post("/preview_camera")
async def preview_camera(data: CameraRequest):
    """ฟังก์ชันสำหรับกด Preview ดูภาพก่อนบันทึก"""
    target_url = f"rtsp://{data.username}:{data.password}@{data.ip}:554/stream2"
    
    # ทดสอบดึงภาพด้วย OpenCV
    cap = cv2.VideoCapture(target_url)
    success, frame = cap.read()
    cap.release() # เปิดแล้วรีบปิดทันทีเพื่อไม่ให้ค้าง

    if success:
        # ย่อขนาดและแปลงเป็น Base64 ส่งกลับไปให้ดู
        resized = cv2.resize(frame, (640, 360))
        _, buffer = cv2.imencode('.jpg', resized, [cv2.IMWRITE_JPEG_QUALITY, 80])
        jpg_as_text = base64.b64encode(buffer).decode('utf-8')
        return {"status": "success", "image": jpg_as_text}
    
    return {"status": "error", "message": "ไม่สามารถเชื่อมต่อกล้องได้ โปรดเช็ค IP หรือ User/Pass"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)