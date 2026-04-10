from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import mysql.connector
import bcrypt
import secrets
import os
from datetime import datetime, timedelta

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Carpeta para fotos
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Conexión a MySQL
def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="paquexpress"
    )

# Modelos
class LoginData(BaseModel):
    username: str
    password: str

# ── LOGIN ──
@app.post("/api/login")
def login(data: LoginData):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM agents WHERE username = %s AND is_active = TRUE", (data.username,))
    agent = cursor.fetchone()
    if not agent or not bcrypt.checkpw(data.password.encode(), agent["password_hash"].encode()):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    
    # Crear token
    token = secrets.token_hex(32)
    expires_at = datetime.now() + timedelta(hours=24)
    cursor.execute("DELETE FROM sessions WHERE agent_id = %s", (agent["id"],))
    cursor.execute("INSERT INTO sessions (agent_id, token, expires_at) VALUES (%s, %s, %s)",
                   (agent["id"], token, expires_at))
    cursor.execute("UPDATE agents SET last_login = %s WHERE id = %s", (datetime.now(), agent["id"]))
    db.commit()
    db.close()
    return {"token": token, "agent_name": agent["full_name"], "agent_id": agent["id"]}

# ── VERIFICAR TOKEN ──
def verify_token(token: str):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("""
        SELECT s.agent_id, a.full_name FROM sessions s
        JOIN agents a ON s.agent_id = a.id
        WHERE s.token = %s AND s.expires_at > NOW()
    """, (token,))
    session = cursor.fetchone()
    db.close()
    if not session:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")
    return session

# ── PAQUETES ──
@app.get("/api/packages")
def get_packages(token: str):
    session = verify_token(token)
    db = get_db()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM packages WHERE agent_id = %s AND status = 'pending'", (session["agent_id"],))
    packages = cursor.fetchall()
    db.close()
    return packages

# ── REGISTRAR ENTREGA ──
@app.post("/api/deliveries")
async def register_delivery(
    package_id: str = Form(...),
    latitude: str = Form(...),
    longitude: str = Form(...),
    token: str = Form(...),
    file: UploadFile = File(...)
):
    session = verify_token(token)
    
    # Guardar foto
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"delivery_{package_id}_{timestamp}.jpg"
    filepath = f"uploads/{filename}"
    with open(filepath, "wb") as f:
        content = await file.read()
        f.write(content)

    db = get_db()
    cursor = db.cursor()
    cursor.execute("""
        INSERT INTO deliveries (package_id, agent_id, delivery_photo, delivery_latitude, delivery_longitude)
        VALUES (%s, %s, %s, %s, %s)
    """, (package_id, session["agent_id"], filename, latitude, longitude))
    cursor.execute("UPDATE packages SET status = 'delivered' WHERE id = %s", (package_id,))
    db.commit()
    db.close()
    return {"mensaje": "Entrega registrada correctamente", "foto": filename}

# ── LOGOUT ──
@app.post("/api/logout")
def logout(token: str):
    db = get_db()
    cursor = db.cursor()
    cursor.execute("DELETE FROM sessions WHERE token = %s", (token,))
    db.commit()
    db.close()
    return {"mensaje": "Sesión cerrada"}