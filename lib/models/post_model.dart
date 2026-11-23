// Representa una publicación recibida desde la API.
class PostModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String imagen;
  final String tags;

  const PostModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.tags,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Convierte la respuesta JSON del backend en un objeto Dart.
    final identificador = json['id_publicacion'] ?? json['id_blog'];
    if (identificador is! num) {
      throw const FormatException('La publicación no contiene un ID válido');
    }

    return PostModel(
      id: identificador.toInt(),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      imagen: json['img']?.toString() ?? '',
      tags: json['tags']?.toString() ?? '',
    );
  }
}
