
import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import DeclarativeBase, sessionmaker

# Cargar las variables del archivo .env
load_dotenv(Path(__file__).with_name(".env"))

# Crear la URL de conexión
url = URL.create(
    drivername="mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD", ""),
    host=os.getenv("DB_HOST", "127.0.0.1"),
    port=int(os.getenv("DB_PORT", "3306")),
    database=os.getenv("DB_NAME", "blog_web"),
    query={"charset": "utf8mb4"},
)

# Crear el motor de conexión
engine = create_engine(url, pool_pre_ping=True)

SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)

# Clase base de los modelos
class Base(DeclarativeBase):
    pass

# Obtener una sesión para cada petición
def obtener_sesion():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
