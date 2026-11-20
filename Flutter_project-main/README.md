# Flutter_project

Aplicación Flutter conectada a FastAPI y a la base de datos existente de la web
PHP (`blog_web`). La API usa las tablas web `usuarios`, `publicaciones` y
`comentarios`; con autorización se añadió `calificaciones` para las estrellas,
sin alterar los datos de las tablas originales.

## Backend FastAPI

1. Comprueba en `backend_API/.env` los valores de `DB_HOST`, `DB_PORT`,
   `DB_USER`, `DB_PASSWORD` y `DB_NAME`. La base de datos debe ser `blog_web`.
2. No ejecutes `backend_API/bd.sql`: ese archivo es el esquema antiguo de la
   aplicación móvil (`bd_Aplicacion_movil`). `backend_API/calificaciones.sql`
   solo crea la tabla nueva de estrellas y ya se aplicó a `blog_web`.
3. En PowerShell:

   ```powershell
   cd .\backend_API
   py -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   uvicorn main:app --reload
   ```

La API queda disponible en `http://127.0.0.1:8000` y la documentación en
`http://127.0.0.1:8000/docs`. Si Apache usa otra URL, ajusta `WEB_BASE_URL`;
para subir imágenes desde la API, `WEB_UPLOAD_DIR` debe apuntar a
`blog_web_final\uploads\publicaciones`.

El inicio de sesión verifica los hashes PHP bcrypt existentes. Las cuentas
registradas en la web pueden iniciar sesión en móvil. El móvil solo muestra el
blog, comentarios y calificaciones; todos los roles entran a la misma pantalla.
El registro desde móvil crea usuarios `visor`. Para comentar o calificar se
requiere una cuenta, igual que en la web. Cada usuario puede asignar y cambiar
una calificación de 1 a 5 estrellas por publicación. Las sesiones duran 12
horas y se reinician al reiniciar el backend.

La base web no tiene columnas para dirección de perfil ni etiquetas de
publicación. La API las rechaza cuando se intenta guardar un valor, en vez de
afirmar que se guardó algo que MySQL no puede almacenar.

## Flutter

En otra terminal:

```powershell
cd .\flutter_application_3
flutter pub get
flutter run -d chrome
```

La configuración existente usa `localhost:8000` para Flutter Web y
`10.0.2.2:8000` para el emulador Android. Flutter solo se comunica con FastAPI;
no se conecta directamente a MySQL.
