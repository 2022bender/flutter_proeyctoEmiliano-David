from sqlalchemy import (
    Column,
    Enum,
    ForeignKey,
    Integer,
    SmallInteger,
    String,
    Text,
    TIMESTAMP,
    CheckConstraint,
    Index,
    UniqueConstraint,
    func,
)
from database import Base


class Usuario(Base):
    __tablename__ = "usuarios"

    id_usuario = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    correo = Column(String(150), unique=True, nullable=False)
    password = Column(String(255), nullable=False)
    rol = Column(
        Enum("administrador", "visor", name="usuarios_rol"),
        nullable=False,
        default="visor",
    )
    fecha_registro = Column(
        TIMESTAMP,
        nullable=False,
        server_default=func.current_timestamp(),
    )


class Publicacion(Base):
    __tablename__ = "publicaciones"

    id_publicacion = Column(Integer, primary_key=True, index=True)
    titulo = Column(String(200), nullable=False)
    contenido = Column(Text, nullable=False)
    imagen = Column(String(255), nullable=True)
    estado = Column(
        Enum("borrador", "publicada", name="publicaciones_estado"),
        nullable=False,
        default="publicada",
    )
    id_autor = Column(
        Integer,
        ForeignKey("usuarios.id_usuario"),
        nullable=False,
    )
    fecha_publicacion = Column(
        TIMESTAMP,
        nullable=False,
        server_default=func.current_timestamp(),
    )


class Comentario(Base):
    __tablename__ = "comentarios"

    id_comentario = Column(Integer, primary_key=True, index=True)
    comentario = Column(Text, nullable=False)
    id_usuario = Column(
        Integer,
        ForeignKey("usuarios.id_usuario"),
        nullable=False,
    )
    id_publicacion = Column(
        Integer,
        ForeignKey("publicaciones.id_publicacion", ondelete="CASCADE"),
        nullable=False,
    )
    fecha_comentario = Column(
        TIMESTAMP,
        nullable=False,
        server_default=func.current_timestamp(),
    )


class Calificacion(Base):
    __tablename__ = "calificaciones"
    __table_args__ = (
        UniqueConstraint(
            "id_usuario",
            "id_publicacion",
            name="uq_calificaciones_usuario_publicacion",
        ),
        CheckConstraint(
            "calificacion BETWEEN 1 AND 5",
            name="chk_calificaciones_rango",
        ),
        Index("idx_calificaciones_publicacion", "id_publicacion"),
    )

    id_calificacion = Column(Integer, primary_key=True, index=True)
    id_usuario = Column(
        Integer,
        ForeignKey("usuarios.id_usuario"),
        nullable=False,
    )
    id_publicacion = Column(
        Integer,
        ForeignKey("publicaciones.id_publicacion", ondelete="CASCADE"),
        nullable=False,
    )
    calificacion = Column(SmallInteger, nullable=False)
    fecha_calificacion = Column(
        TIMESTAMP,
        nullable=False,
        server_default=func.current_timestamp(),
        server_onupdate=func.current_timestamp(),
    )
