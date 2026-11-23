from datetime import datetime
from pydantic import BaseModel, Field


# Datos necesarios para registrar un usuario.
class UsuarioCrear(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=6, max_length=128)
    dir_usr: str | None = None
    tip_usu: int = Field(default=2, ge=1, le=2)


# Datos públicos que devuelve la API para un usuario.
class UsuarioRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    mail: str
    dir_usr: str | None = None
    tip_usu: int
    id_usuario: int
    nombre: str
    correo: str
    rol: str
    fecha_registro: datetime


class LoginRespuesta(UsuarioRespuesta):
    access_token: str
    token_type: str = "bearer"


# Campos permitidos para actualizar un usuario.
class UsuarioActualizar(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    dir_usr: str | None = None
    tip_usu: int = Field(default=2, ge=1, le=2)


# Datos aceptados para crear una publicación.
class BlogCrear(BaseModel):
    titulo: str = Field(min_length=2, max_length=200)
    descripcion: str = Field(min_length=1)
    img: str | None = Field(default=None, max_length=255)
    tags: str | None = Field(default=None, max_length=255)


# Formato de respuesta de una publicación.
class BlogRespuesta(BaseModel):
    id_blog: int
    titulo: str
    descripcion: str
    img: str | None = None
    tags: str = ""
    id_publicacion: int
    contenido: str
    imagen: str | None = None
    estado: str
    id_autor: int
    fecha_publicacion: datetime


# Datos mínimos necesarios para crear un comentario.
class ComentarioCrear(BaseModel):
    comentario: str = Field(min_length=1)
    usr_id: int | None = None
    blog_id: int


# Formato de respuesta de un comentario.
class ComentarioRespuesta(BaseModel):
    id_com: int
    comentario: str
    fecha: datetime
    estatus: int
    usr_id: int
    blog_id: int
    id_comentario: int
    id_usuario: int
    id_publicacion: int
    fecha_comentario: datetime


class CalificacionActualizar(BaseModel):
    calificacion: int = Field(ge=1, le=5)


class CalificacionResumen(BaseModel):
    id_publicacion: int
    promedio: float
    total: int
    mi_calificacion: int | None = None


# Credenciales recibidas durante el inicio de sesión.
class LoginRequest(BaseModel):
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=1, max_length=4096)
    
