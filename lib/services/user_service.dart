import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user_model.dart';
import 'auth_session.dart';

// Realiza las operaciones de administración de usuarios.
class UserService {
  static String get baseUrl => ApiConfig.baseUrl;
  Future<List<UserModel>> obtenerUsuarios() async {
    // Consulta la lista completa de usuarios.
    final respuesta = await http
        .get(Uri.parse('$baseUrl/usuarios'), headers: AuthSession.headers)
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        'Error al consultar usuarios: ${respuesta.statusCode}',
      );
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);

    return datos
        .map(
          (json) => UserModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<UserModel> agregarUsuario(UserModel usuario) async {
    // Registra un usuario nuevo.
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/usuarios'),
          headers: AuthSession.headers,
          body: jsonEncode(usuario.toJsonCrear()),
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode == 201) {
      return UserModel.fromJson(
        jsonDecode(respuesta.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_mensajeError(respuesta));
  }

  Future<UserModel> actualizarUsuario(UserModel usuario) async {
    // Actualiza los datos de un usuario existente.
    final respuesta = await http
        .put(
          Uri.parse('$baseUrl/usuarios/${usuario.id}'),
          headers: AuthSession.headers,
          body: jsonEncode({
            'nom_usr': usuario.nombre,
            'mail': usuario.correo,
            'dir_usr': usuario.direccion,
            'tip_usu': usuario.tipoUsuario,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode == 200) {
      return UserModel.fromJson(
        jsonDecode(respuesta.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_mensajeError(respuesta));
  }

  Future<void> eliminarUsuario(int id) async {
    // Elimina un usuario mediante su identificador.
    final respuesta = await http
        .delete(
          Uri.parse('$baseUrl/usuarios/$id'),
          headers: AuthSession.headers,
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200 && respuesta.statusCode != 204) {
      throw Exception(_mensajeError(respuesta));
    }
  }

  String _mensajeError(http.Response respuesta) {
    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map && datos['detail'] != null) {
        return datos['detail'].toString();
      }
    } catch (_) {
      // La respuesta no contiene JSON.
    }

    return 'Error HTTP ${respuesta.statusCode}: ${respuesta.body}';
  }
}
