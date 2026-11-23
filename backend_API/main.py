from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
import secrets
import shutil
import uuid
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request as UrlRequest, urlopen

from fastapi import FastAPI, Depends, File, Form, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.staticfiles import StaticFiles
from pydantic import ValidationError
from sqlalchemy.orm import Session
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from pwdlib import PasswordHash
from pwdlib.hashers.argon2 import Argon2Hasher
from pwdlib.hashers.bcrypt import BcryptHasher
from database import obtener_sesion
from models import Usuario, Publicacion, Comentario, Calificacion
from schemas import (
    UsuarioCrear,
    UsuarioActualizar,
    UsuarioRespuesta,
    LoginRespuesta,
    BlogRespuesta,
    BlogCrear,
    ComentarioCrear,
    ComentarioRespuesta,
    CalificacionActualizar,
    CalificacionResumen,
    LoginRequest,
)

# PHP `password_hash(..., PASSWORD_DEFAULT)` usa bcrypt actualmente.
# BcryptHasher permite verificar también los hashes PHP con prefijo `$2y$`.
# Argon2 se conserva para que los usuarios creados con la versión anterior
# del backend puedan seguir iniciando sesión.
password_hash = PasswordHash((BcryptHasher(), Argon2Hasher()))
bcrypt_hasher = BcryptHasher()
bearer_scheme = HTTPBearer(auto_error=False)
_active_tokens: dict[str, tuple[int, datetime]] = {}
_token_lifetime = timedelta(hours=12)
WEB_BASE_URL = os.getenv("WEB_BASE_URL", "http://localhost/blog_web_final").rstrip("/")
WEB_UPLOAD_DIR = Path(
    os.getenv(
        "WEB_UPLOAD_DIR",
        r"C:\xampp\htdocs\blog_web_final\uploads\publicaciones",
    )
)


def _imagen_para_app(imagen: str | None) -> str | None:
    if not imagen:
        return imagen
    destino = urlparse(imagen)
    if destino.scheme or imagen.startswith("//"):
        return imagen
    return f"{WEB_BASE_URL}/{imagen.lstrip('/')}"


def _usuario_json(usuario: Usuario) -> dict:
    return {
        "id_usr": usuario.id_usuario,
        "nom_usr": usuario.nombre,
        "mail": usuario.correo,
        "dir_usr": None,
        "tip_usu": 1 if usuario.rol == "administrador" else 2,
        "id_usuario": usuario.id_usuario,
        "nombre": usuario.nombre,
        "correo": usuario.correo,
        "rol": usuario.rol,
        "fecha_registro": usuario.fecha_registro,
    }


def _hash_nueva_password(password: str) -> str:
    hashed = bcrypt_hasher.hash(password)
    if hashed.startswith("$2b$"):
        return f"$2y${hashed[4:]}"
    return hashed


def _publicacion_json(publicacion: Publicacion) -> dict:
    return {
        "id_blog": publicacion.id_publicacion,
        "titulo": publicacion.titulo,
        "descripcion": publicacion.contenido,
        "desc": publicacion.contenido,
        "img": _imagen_para_app(publicacion.imagen),
        "tags": "",
        "id_publicacion": publicacion.id_publicacion,
        "contenido": publicacion.contenido,
        "imagen": publicacion.imagen,
        "estado": publicacion.estado,
        "id_autor": publicacion.id_autor,
        "fecha_publicacion": publicacion.fecha_publicacion,
    }


def _comentario_json(comentario: Comentario) -> dict:
    return {
        "id_com": comentario.id_comentario,
        "comentario": comentario.comentario,
        "fecha": comentario.fecha_comentario,
        "estatus": 1,
        "usr_id": comentario.id_usuario,
        "blog_id": comentario.id_publicacion,
        "id_comentario": comentario.id_comentario,
        "id_usuario": comentario.id_usuario,
        "id_publicacion": comentario.id_publicacion,
        "fecha_comentario": comentario.fecha_comentario,
    }


def _resumen_calificacion(
    db: Session,
    publicacion_id: int,
    usuario_id: int | None,
) -> dict:
    promedio, total = db.execute(
        select(
            func.avg(Calificacion.calificacion),
            func.count(Calificacion.id_calificacion),
        ).where(Calificacion.id_publicacion == publicacion_id)
    ).one()
    mi_calificacion = None
    if usuario_id is not None:
        mi_calificacion = db.scalar(
            select(Calificacion.calificacion).where(
                Calificacion.id_publicacion == publicacion_id,
                Calificacion.id_usuario == usuario_id,
            )
        )

    return {
        "id_publicacion": publicacion_id,
        "promedio": round(float(promedio), 2) if promedio is not None else 0.0,
        "total": total,
        "mi_calificacion": mi_calificacion,
    }


def _crear_token(usuario: Usuario) -> str:
    ahora = datetime.now(timezone.utc)
    for token, (_, vence) in list(_active_tokens.items()):
        if ahora >= vence:
            _active_tokens.pop(token, None)
    token = secrets.token_urlsafe(32)
    _active_tokens[token] = (
        usuario.id_usuario,
        ahora + _token_lifetime,
    )
    return token


def _obtener_usuario_token(
    credentials: HTTPAuthorizationCredentials | None,
    db: Session,
    *,
    obligatorio: bool,
) -> Usuario | None:
    if credentials is None:
        if obligatorio:
            raise HTTPException(status_code=401, detail="Autenticación requerida")
        return None

    token = _active_tokens.get(credentials.credentials)
    if token is None:
        raise HTTPException(status_code=401, detail="Sesión inválida o vencida")

    usuario_id, vence = token
    if datetime.now(timezone.utc) >= vence:
        _active_tokens.pop(credentials.credentials, None)
        raise HTTPException(status_code=401, detail="Sesión inválida o vencida")

    usuario = db.get(Usuario, usuario_id)
    if usuario is None or usuario.rol not in {"administrador", "visor"}:
        _active_tokens.pop(credentials.credentials, None)
        raise HTTPException(status_code=401, detail="Sesión inválida o vencida")
    return usuario


def usuario_actual(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(obtener_sesion),
) -> Usuario:
    usuario = _obtener_usuario_token(credentials, db, obligatorio=True)
    if usuario is None:
        raise HTTPException(status_code=401, detail="Autenticación requerida")
    return usuario


def administrador_actual(usuario: Usuario = Depends(usuario_actual)) -> Usuario:
    if usuario.rol != "administrador":
        raise HTTPException(status_code=403, detail="Se requiere el rol administrador")
    return usuario


def usuario_opcional(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(obtener_sesion),
) -> Usuario | None:
    return _obtener_usuario_token(credentials, db, obligatorio=False)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Punto de extensión para tareas de inicio y cierre de la API.
    yield

app = FastAPI(
    title="API de aplicación móvil",
    lifespan=lifespan,
)

UPLOAD_DIR = Path(__file__).resolve().parent / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.get("/")
def inicio():
    # Endpoint de comprobación para verificar que la API está activa.
    return {"mensaje": "API funcionando correctamente"}


@app.get("/image-proxy")
def proxy_imagen(url: str):
    # Descarga imágenes externas para que Flutter Web no tenga problemas de CORS.
    destino = urlparse(url)
    if destino.scheme not in {"http", "https"} or not destino.netloc:
        raise HTTPException(status_code=400, detail="La URL de imagen no es válida")

    try:
        solicitud = UrlRequest(url, headers={"User-Agent": "FlutterProject/1.0"})
        with urlopen(solicitud, timeout=10) as respuesta:
            contenido = respuesta.read(5 * 1024 * 1024 + 1)
            tipo = respuesta.headers.get_content_type()
    except (HTTPError, URLError, TimeoutError) as error:
        raise HTTPException(status_code=502, detail="No se pudo descargar la imagen externa") from error

    if len(contenido) > 5 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="La imagen supera 5 MB")
    if not tipo.startswith("image/"):
        raise HTTPException(status_code=415, detail="El enlace no apunta a una imagen")

    return Response(content=contenido, media_type=tipo, headers={"Cache-Control": "public, max-age=3600"})
# Permitir la comunicación con Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:60450",
        "http://127.0.0.1:60450",
        "http://localhost:62755",
        "http://127.0.0.1:62755",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ],
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/login", response_model=LoginRespuesta)
def iniciar_sesion(
    # Busca al usuario y valida su contraseña.
    datos: LoginRequest,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.mail.strip().lower()

    usuario = db.scalar(
        select(Usuario).where(Usuario.correo == correo)
    )

    # Se utiliza el mismo mensaje para no revelar
    # si el correo está registrado.
    if usuario is None or not password_hash.verify(
        datos.password,
        usuario.password,
    ):
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos",
        )

    # Devuelve únicamente los datos públicos del usuario.
    return {
        **_usuario_json(usuario),
        "access_token": _crear_token(usuario),
    }


# Endpoints existentes:
# @app.get("/usuarios")
# @app.post("/usuarios")
# etc.

# USUARIOS

@app.get("/usuarios", response_model=list[UsuarioRespuesta])
def listar_usuarios(
    db: Session = Depends(obtener_sesion),
    _: Usuario = Depends(administrador_actual),
):
    # Devuelve los usuarios ordenados por identificador.
    usuarios = db.scalars(select(Usuario).order_by(Usuario.id_usuario)).all()
    return [_usuario_json(usuario) for usuario in usuarios]


@app.post("/usuarios", response_model=UsuarioRespuesta, status_code=201)
def crear_usuario(
    # Valida, cifra y registra un usuario nuevo.
    datos: UsuarioCrear,
    db: Session = Depends(obtener_sesion),
    actor: Usuario | None = Depends(usuario_opcional),
):
    if actor is not None and actor.rol != "administrador":
        raise HTTPException(status_code=403, detail="Se requiere el rol administrador")
    if datos.dir_usr and datos.dir_usr.strip():
        raise HTTPException(
            status_code=422,
            detail="blog_web no tiene un campo para guardar la dirección del perfil",
        )

    rol = "visor"
    if actor is not None and datos.tip_usu == 1:
        rol = "administrador"
    usuario = Usuario(
        nombre=datos.nom_usr.strip(),
        correo=datos.mail.strip().lower(),
        password=_hash_nueva_password(datos.password),
        rol=rol,
    )

    db.add(usuario)

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return _usuario_json(usuario)
@app.put(
    "/usuarios/{usuario_id}",
    response_model=UsuarioRespuesta,
)
def actualizar_usuario(
    # Modifica los datos de un usuario existente.
    usuario_id: int,
    datos: UsuarioActualizar,
    db: Session = Depends(obtener_sesion),
    actor: Usuario = Depends(usuario_actual),
):
    usuario = db.get(Usuario, usuario_id)

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    if actor.rol != "administrador" and actor.id_usuario != usuario_id:
        raise HTTPException(status_code=403, detail="No puedes modificar este perfil")
    if datos.dir_usr and datos.dir_usr.strip():
        raise HTTPException(
            status_code=422,
            detail="blog_web no tiene un campo para guardar la dirección del perfil",
        )

    usuario.nombre = datos.nom_usr.strip()
    usuario.correo = datos.mail.strip().lower()
    if actor.rol == "administrador":
        usuario.rol = "administrador" if datos.tip_usu == 1 else "visor"

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return _usuario_json(usuario)


@app.delete("/usuarios/{usuario_id}")
def eliminar_usuario(
    # Elimina un usuario por su identificador.
    usuario_id: int,
    db: Session = Depends(obtener_sesion),
    _: Usuario = Depends(administrador_actual),
):
    usuario = db.get(Usuario, usuario_id)

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    try:
        db.delete(usuario)
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="No se puede eliminar el usuario mientras tenga publicaciones o comentarios",
        ) from error

    return {"mensaje": "Usuario eliminado correctamente"}

# BLOG

@app.get("/blog", response_model=list[BlogRespuesta])
def listar_blog(db: Session = Depends(obtener_sesion)):
    # Solo expone el contenido que la página web también publica.
    publicaciones = db.scalars(
        select(Publicacion)
        .where(Publicacion.estado == "publicada")
        .order_by(Publicacion.fecha_publicacion.desc())
    ).all()
    return [_publicacion_json(publicacion) for publicacion in publicaciones]

@app.post("/blog", response_model=BlogRespuesta, status_code=201)
async def crear_blog(
    # Crea una publicación desde JSON o desde un formulario multipart.
    request: Request,
    titulo: str | None = Form(default=None),
    descripcion: str | None = Form(default=None),
    imagen: UploadFile | None = File(default=None),
    tags: str | None = Form(default=None),
    db: Session = Depends(obtener_sesion),
    actor: Usuario = Depends(administrador_actual),
):
    content_type = (
        request.headers.get("content-type", "")
        .split(";", 1)[0]
        .strip()
        .lower()
    )

    if content_type == "multipart/form-data":
        try:
            if not isinstance(titulo, str) or not titulo.strip():
                raise HTTPException(status_code=422, detail="El título es obligatorio")
            if len(titulo.strip()) < 2:
                raise HTTPException(
                    status_code=422,
                    detail="El título debe tener al menos 2 caracteres",
                )
            if len(titulo.strip()) > 200:
                raise HTTPException(
                    status_code=422,
                    detail="El título no puede superar 200 caracteres",
                )
            if not isinstance(descripcion, str) or not descripcion.strip():
                raise HTTPException(
                    status_code=422,
                    detail="La descripción es obligatoria",
                )
            if imagen is None:
                raise HTTPException(
                    status_code=422,
                    detail="La fotografía es obligatoria",
                )
            if tags is not None and not isinstance(tags, str):
                raise HTTPException(status_code=422, detail="Los tags no son válidos")
            if isinstance(tags, str) and len(tags.strip()) > 255:
                raise HTTPException(
                    status_code=422,
                    detail="Los tags no pueden superar 255 caracteres",
                )

            extension = Path(imagen.filename or "").suffix.lower()
            if extension not in {".jpg", ".jpeg", ".png", ".webp"}:
                raise HTTPException(
                    status_code=400,
                    detail="Formato de imagen no permitido",
                )

            nombre_archivo = f"{uuid.uuid4().hex}{extension}"
            ruta_archivo_api = UPLOAD_DIR / nombre_archivo
            ruta_archivo_web = WEB_UPLOAD_DIR / nombre_archivo
            ruta_publica = f"uploads/publicaciones/{nombre_archivo}"

            try:
                WEB_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
                with ruta_archivo_api.open("wb") as destino:
                    shutil.copyfileobj(imagen.file, destino)
                shutil.copyfile(ruta_archivo_api, ruta_archivo_web)
                return _guardar_blog(
                    db,
                    titulo=titulo,
                    descripcion=descripcion,
                    img=ruta_publica,
                    tags=tags,
                    autor_id=actor.id_usuario,
                )
            except (OSError, SQLAlchemyError, HTTPException):
                ruta_archivo_api.unlink(missing_ok=True)
                ruta_archivo_web.unlink(missing_ok=True)
                raise
        finally:
            if imagen is not None:
                await imagen.close()

    try:
        datos = BlogCrear.model_validate(await request.json())
    except ValidationError as error:
        raise HTTPException(
            status_code=422,
            detail=error.errors(),
        ) from error
    except ValueError as error:
        raise HTTPException(
            status_code=400,
            detail="El cuerpo JSON no es válido",
        ) from error

    return _guardar_blog(
        db,
        titulo=datos.titulo,
        descripcion=datos.descripcion,
        img=datos.img,
        tags=datos.tags,
        autor_id=actor.id_usuario,
    )


def _guardar_blog(
    # Guarda una publicación validada en la base de datos.
    db: Session,
    *,
    titulo: str,
    descripcion: str,
    img: str | None,
    autor_id: int,
    tags: str | None = None,
):
    if tags and tags.strip():
        raise HTTPException(
            status_code=422,
            detail="blog_web no tiene un campo para guardar etiquetas",
        )
    if img and len(img) > 255:
        raise HTTPException(
            status_code=422,
            detail="La ruta de imagen no puede superar 255 caracteres",
        )

    publicacion = Publicacion(
        titulo=titulo.strip(),
        contenido=descripcion.strip(),
        imagen=img.strip() if img and img.strip() else None,
        estado="publicada",
        id_autor=autor_id,
    )
    db.add(publicacion)
    try:
        db.commit()
        db.refresh(publicacion)
    except SQLAlchemyError:
        db.rollback()
        raise
    return _publicacion_json(publicacion)

@app.get("/blog/{blog_id}", response_model=BlogRespuesta)
def obtener_blog(
    # Busca una publicación específica por su ID.
    blog_id: int,
    db: Session = Depends(obtener_sesion),
):
    publicacion = db.get(Publicacion, blog_id)

    if publicacion is None or publicacion.estado != "publicada":
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    return _publicacion_json(publicacion)

# COMENTARIOS

@app.get(
    "/comentarios",
    response_model=list[ComentarioRespuesta],
)
def listar_comentarios(
    # Lista comentarios, opcionalmente filtrados por publicación.
    blog_id: int | None = None,
    db: Session = Depends(obtener_sesion),
):
    consulta = select(Comentario)

    if blog_id is not None:
        consulta = consulta.where(Comentario.id_publicacion == blog_id)

    consulta = consulta.join(
        Publicacion,
        Comentario.id_publicacion == Publicacion.id_publicacion,
    ).where(Publicacion.estado == "publicada")
    comentarios = db.scalars(
        consulta.order_by(Comentario.fecha_comentario.desc())
    ).all()
    return [_comentario_json(comentario) for comentario in comentarios]


@app.post(
    "/comentarios",
    response_model=ComentarioRespuesta,
    status_code=201,
)
def crear_comentario(
    # Valida las relaciones y registra un comentario nuevo.
    datos: ComentarioCrear,
    db: Session = Depends(obtener_sesion),
    actor: Usuario = Depends(usuario_actual),
):
    if not datos.comentario.strip():
        raise HTTPException(
            status_code=422,
            detail="El comentario no puede estar vacío",
        )

    if datos.usr_id is not None and datos.usr_id != actor.id_usuario:
        raise HTTPException(status_code=403, detail="No puedes comentar como otro usuario")

    publicacion = db.get(Publicacion, datos.blog_id)
    if publicacion is None or publicacion.estado != "publicada":
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    nuevo = Comentario(
        comentario=datos.comentario.strip(),
        id_usuario=actor.id_usuario,
        id_publicacion=datos.blog_id,
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return _comentario_json(nuevo)


@app.get(
    "/calificaciones/{blog_id}",
    response_model=CalificacionResumen,
)
def consultar_calificacion(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario | None = Depends(usuario_opcional),
):
    publicacion = db.get(Publicacion, blog_id)
    if publicacion is None or publicacion.estado != "publicada":
        raise HTTPException(status_code=404, detail="Publicación no encontrada")

    return _resumen_calificacion(
        db,
        blog_id,
        usuario.id_usuario if usuario is not None else None,
    )


@app.put(
    "/calificaciones/{blog_id}",
    response_model=CalificacionResumen,
)
def guardar_calificacion(
    blog_id: int,
    datos: CalificacionActualizar,
    db: Session = Depends(obtener_sesion),
    usuario: Usuario = Depends(usuario_actual),
):
    publicacion = db.get(Publicacion, blog_id)
    if publicacion is None or publicacion.estado != "publicada":
        raise HTTPException(status_code=404, detail="Publicación no encontrada")

    calificacion = db.scalar(
        select(Calificacion).where(
            Calificacion.id_publicacion == blog_id,
            Calificacion.id_usuario == usuario.id_usuario,
        )
    )
    if calificacion is None:
        calificacion = Calificacion(
            id_publicacion=blog_id,
            id_usuario=usuario.id_usuario,
            calificacion=datos.calificacion,
        )
        db.add(calificacion)
    else:
        calificacion.calificacion = datos.calificacion

    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        calificacion = db.scalar(
            select(Calificacion).where(
                Calificacion.id_publicacion == blog_id,
                Calificacion.id_usuario == usuario.id_usuario,
            )
        )
        if calificacion is None:
            raise HTTPException(
                status_code=409,
                detail="No se pudo guardar la calificación",
            ) from error
        calificacion.calificacion = datos.calificacion
        db.commit()

    return _resumen_calificacion(db, blog_id, usuario.id_usuario)