import hashlib
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
import os
from urllib.parse import urlparse

# 1. ตั้งค่าการเชื่อมต่อ
DATABASE_URL = os.getenv('DATABASE_URL')

if DATABASE_URL:
    # Parse DATABASE_URL สำหรับ Docker/Production
    parsed = urlparse(DATABASE_URL)
    DB_CONFIG = {
        "host": parsed.hostname,
        "database": parsed.path.lstrip('/'),
        "user": parsed.username,
        "password": parsed.password,
        "port": parsed.port or 5432
    }
else:
    # Local development config
    DB_CONFIG = {
        "host": "localhost",
        "database": "parking_db",
        "user": "postgres",
        "password": "1234",
        "port": 5432
    }

DB_POOL = None

def init_db_pool():
    global DB_POOL
    if DB_POOL is None:
        try:
            DB_POOL = pool.SimpleConnectionPool(
                1,
                10,
                connect_timeout=5,
                **DB_CONFIG,
            )
            print("✅ Database pool initialized")
        except Exception as e:
            print(f"❌ Error creating connection pool: {e}")
            DB_POOL = None
    return DB_POOL


def get_connection():
    """ดึง connection จาก pool"""
    db_pool = init_db_pool()
    if not db_pool:
        return None
    try:
        conn = db_pool.getconn()
        return conn
    except Exception as e:
        print(f"❌ Error getting connection from pool: {e}")
        return None


def release_connection(conn):
    if conn and DB_POOL:
        try:
            DB_POOL.putconn(conn)
        except Exception as e:
            print(f"❌ Error releasing connection to pool: {e}")


def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode('utf-8')).hexdigest()


def init_db():
    """สร้างตารางเริ่มต้น (รันแค่ครั้งเดียวหรือรันตอนเริ่มระบบ)"""
    camera_query = """
    CREATE TABLE IF NOT EXISTS cameras (
        id SERIAL PRIMARY KEY,
        camera_name VARCHAR(100) NOT NULL,
        ip_address VARCHAR(50) NOT NULL,
        username VARCHAR(100) NOT NULL,
        password VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """

    user_query = """
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(256) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """

    conn = get_connection()
    if conn:
        cur = conn.cursor()
        cur.execute(camera_query)
        cur.execute(user_query)
        conn.commit()
        cur.close()
        conn.close()
        print("✅ Database initialized successfully")


# ฟังก์ชันช่วยเหลือสำหรับ API
def add_camera_to_db(name, ip, user, pw):
    conn = get_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO cameras (camera_name, ip_address, username, password) VALUES (%s, %s, %s, %s)",
                (name, ip, user, pw)
            )
            conn.commit()
            return True
        except Exception as e:
            print(f"Error adding camera: {e}")
            if conn:
                conn.rollback()
            return False
        finally:
            if cur:
                cur.close()
            release_connection(conn)
    return False


def get_all_cameras():
    conn = get_connection()
    if conn:
        try:
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("SELECT * FROM cameras ORDER BY created_at DESC")
            rows = cur.fetchall()
            # แปลงเป็น list of dicts เพื่อให้ JSON serializable
            return [dict(row) for row in rows]
        except Exception as e:
            print(f"Error fetching cameras: {e}")
            return []
        finally:
            if cur:
                cur.close()
            release_connection(conn)
    return []


def create_user(username: str, password: str) -> bool:
    conn = get_connection()
    if not conn:
        return False
    try:
        password_hash = hash_password(password)
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO users (username, password_hash) VALUES (%s, %s)",
            (username, password_hash),
        )
        conn.commit()
        return True
    except psycopg2.IntegrityError:
        if conn:
            conn.rollback()
        return False
    except Exception as e:
        print(f"Error creating user: {e}")
        if conn:
            conn.rollback()
        return False
    finally:
        if cur:
            cur.close()
        release_connection(conn)

        cur.close()
        conn.close()
        return False


def authenticate_user(username: str, password: str) -> bool:
    conn = get_connection()
    if not conn:
        return False
    try:
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT password_hash FROM users WHERE username=%s", (username,))
        user = cur.fetchone()
        if not user:
            return False
        return user['password_hash'] == hash_password(password)
    except Exception as e:
        print(f"Error authenticating user: {e}")
        return False
    finally:
        if cur:
            cur.close()
        release_connection(conn)

