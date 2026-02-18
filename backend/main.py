import os
import cv2
import base64
import threading
import time
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

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

# เริ่มต้นฐานข้อมูล (สร้างตารางถ้ายังไม่มี)
@app.on_event("startup")
def startup_event():
    init_db()

# --- Models สำหรับรับข้อมูล ---
class CameraRegister(BaseModel):
    camera_name: str
    ip: str
    username: str
    password: str

class CameraRequest(BaseModel):
    ip: str
    username: str
    password: str

# --- ตัวจัดการกล้อง (Camera Manager) ---
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
    """บันทึกข้อมูลกล้องใหม่ลง PostgreSQL"""
    success = add_camera_to_db(data.camera_name, data.ip, data.username, data.password)
    if success:
        return {"status": "success", "message": "Camera added to database"}
    raise HTTPException(status_code=500, detail="Failed to add camera to database")

@app.get("/get_cameras")
async def get_cameras():
    """ดึงรายชื่อกล้องทั้งหมดจาก PostgreSQL ไปแสดงที่ Flutter"""
    cameras = get_all_cameras()
    return cameras

@app.post("/get_frame")
async def get_frame(data: CameraRequest):
    """ดึงภาพสดจากกล้องที่เลือก"""
    target_url = f"rtsp://{data.username}:{data.password}@{data.ip}:554/stream2"
    cam_manager.change_camera(target_url)

    if cam_manager.status and cam_manager.frame is not None:
        with cam_manager.lock:
            resized_frame = cv2.resize(cam_manager.frame, (640, 360))
            _, buffer = cv2.imencode('.jpg', resized_frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
            
        jpg_as_text = base64.b64encode(buffer).decode('utf-8')
        return {"status": "success", "image": jpg_as_text}
    
    return {"status": "error", "message": "Connecting..."}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)