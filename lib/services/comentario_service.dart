import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/comentario_model.dart';
import 'auth_session.dart';

// Realiza las operaciones HTTP de la sección de comentarios.
class ComentarioService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<List<ComentarioModel>> obtenerComentarios(int blogId) async {
    // Consulta los comentarios filtrados por publicación.
    final uri = Uri.parse('$baseUrl/comentarios').replace(
      queryParameters: {'blog_id': '$blogId'},
    );

    final respuesta = await http.get(uri).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        'Error al consultar comentarios (HTTP ${respuesta.statusCode})',
      );
    }

    final datos = jsonDecode(respuesta.body);
    if (datos is! List) {
      throw Exception('La respuesta de comentarios no es válida');
    }

    return datos
        .map((json) => ComentarioModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> agregarComentario(
    // Registra un comentario nuevo en la API.
    ComentarioModel comentario,
  ) async {
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/comentarios'),
          headers: AuthSession.headers,
          body: jsonEncode(comentario.toJsonCrear()),
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
      throw Exception(
        'No se pudo registrar el comentario: ${respuesta.body}',
      );
    }
  }
}
