CREATE TABLE IF NOT EXISTS calificaciones (
  id_calificacion INT NOT NULL AUTO_INCREMENT,
  id_usuario INT NOT NULL,
  id_publicacion INT NOT NULL,
  calificacion TINYINT UNSIGNED NOT NULL,
  fecha_calificacion TIMESTAMP NOT NULL
    DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_calificacion),
  UNIQUE KEY uq_calificaciones_usuario_publicacion
    (id_usuario, id_publicacion),
  KEY idx_calificaciones_publicacion (id_publicacion),
  CONSTRAINT chk_calificaciones_rango
    CHECK (calificacion BETWEEN 1 AND 5),
  CONSTRAINT fk_calificaciones_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
  CONSTRAINT fk_calificaciones_publicacion
    FOREIGN KEY (id_publicacion)
    REFERENCES publicaciones(id_publicacion)
    ON DELETE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
