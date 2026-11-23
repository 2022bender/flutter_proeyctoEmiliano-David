
from sqlalchemy import text
from database import engine

try:
    with engine.connect() as conexion:
        resultado = conexion.execute(text("SELECT DATABASE()"))
        print("CONEXIÓN EXITOSA")
        print("Base de datos:", resultado.scalar())

except Exception as error:
    print("ERROR DE CONEXIÓN:")
    print(error)
