import psycopg2
from psycopg2.extras import RealDictCursor

# 1. ตั้งค่าการเชื่อมต่อ (เปลี่ยนค่าให้ตรงกับเครื่องของคุณ)
DB_CONFIG = {
    "host": "localhost",
    "database": "parking_db", # ชื่อ Database ที่คุณสร้างใน pgAdmin
    "user": "postgres",       # ปกติคือ postgres
    "password": "1234", # รหัสผ่านที่คุณตั้งตอนลง PostgreSQL
    "port": "5432"
}

def get_connection():
    """สร้างการเชื่อมต่อกับ PostgreSQL"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        print(f"❌ Error connecting to database: {e}")
        return None

def init_db():
    """สร้างตารางเริ่มต้น (รันแค่ครั้งเดียวหรือรันตอนเริ่มระบบ)"""
    query = """
    CREATE TABLE IF NOT EXISTS cameras (
        id SERIAL PRIMARY KEY,
        camera_name VARCHAR(100) NOT NULL,
        ip_address VARCHAR(50) NOT NULL,
        username VARCHAR(100) NOT NULL,
        password VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """
    conn = get_connection()
    if conn:
        cur = conn.cursor()
        cur.execute(query)
        conn.commit()
        cur.close()
        conn.close()
        print("✅ Database initialized successfully")

# ฟังก์ชันช่วยเหลือสำหรับ API
def add_camera_to_db(name, ip, user, pw):
    conn = get_connection()
    if conn:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO cameras (camera_name, ip_address, username, password) VALUES (%s, %s, %s, %s)",
            (name, ip, user, pw)
        )
        conn.commit()
        cur.close()
        conn.close()
        return True
    return False

def get_all_cameras():
    conn = get_connection()
    if conn:
        # ใช้ RealDictCursor เพื่อให้ผลลัพธ์ออกมาเป็น Dictionary (คล้าย JSON)
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM cameras ORDER BY created_at DESC")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return rows
    return []