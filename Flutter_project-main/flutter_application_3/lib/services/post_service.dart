import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/post_model.dart';
import 'auth_session.dart';

// Realiza las operaciones HTTP relacionadas con publicaciones.
class PostService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<PostModel> agregarPost({
    // Guarda una publicación y su enlace de imagen.
    required String titulo,
    required String descripcion,
    required String imagenUrl,
    String? tags,
  }) async {
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/blog'),
          headers: AuthSession.headers,
          body: jsonEncode({
            'titulo': titulo.trim(),
            'descripcion': descripcion.trim(),
            'img': imagenUrl.trim(),
            'tags': tags?.trim(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic resultado =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;

    if ((respuesta.statusCode == 200 || respuesta.statusCode == 201) &&
        resultado is Map<String, dynamic>) {
      return PostModel.fromJson(resultado);
    }

    if (resultado is Map && resultado['detail'] != null) {
      throw Exception(resultado['detail'].toString());
    }

    throw Exception(
      'No se pudo guardar la publicación (HTTP ${respuesta.statusCode})',
    );
  }

  Future<List<PostModel>> obtenerPosts() async {
    // Obtiene todas las publicaciones disponibles.
    final respuesta = await http.get(
      Uri.parse('$baseUrl/blog'),
    );

    if (respuesta.statusCode != 200) {
      throw Exception('Error al consultar publicaciones');
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);

    return datos
        .map(
          (json) => PostModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
