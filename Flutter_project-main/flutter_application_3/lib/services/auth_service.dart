import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_session.dart';

// Contiene las validaciones y peticiones relacionadas con autenticación.
class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;

  String? validarLogin({
    // Comprueba que el formulario de inicio de sesión esté completo.
    required String usuario,
    required String password,
  }) {
    if (usuario.trim().isEmpty || password.isEmpty) {
      return 'Ingresa tu correo y contraseña';
    }
    return null;
  }

  String? validarRegistro({
    // Comprueba los datos antes de registrar un nuevo usuario.
    required String nombre,
    required String correo,
    required String password,
    required String confirmarpassword,
  }) {
    if (nombre.isEmpty ||
        correo.isEmpty ||
        password.isEmpty ||
        confirmarpassword.isEmpty) {
      return 'Completa todos los campos';
    }

    if (!correo.contains('@')) {
      return 'Ingresa un correo válido';
    }

    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (password != confirmarpassword) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  Future<Map<String, dynamic>> registrarUsuario({
    // Envía los datos de registro al endpoint de usuarios.
    required String nombre,
    required String correo,
    required String password,
    String? direccion,
  }) async {
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/usuarios'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'nom_usr': nombre.trim(),
            'mail': correo.trim().toLowerCase(),
            'password': password,
            'dir_usr': direccion,
            'tip_usu': 2,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic resultado =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;

    if ((respuesta.statusCode == 200 || respuesta.statusCode == 201) &&
        resultado is Map<String, dynamic>) {
      return resultado;
    }

    if (resultado is Map && resultado['detail'] != null) {
      throw Exception(resultado['detail'].toString());
    }

    throw Exception(
        'No se pudo registrar el usuario (HTTP ${respuesta.statusCode})');
  }

  Future<Map<String, dynamic>> autenticar({
    // Envía las credenciales y devuelve los datos del usuario autenticado.
    required String correo,
    required String password,
  }) async {
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'mail': correo.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic resultado = jsonDecode(respuesta.body);

    if (respuesta.statusCode == 200 && resultado is Map<String, dynamic>) {
      AuthSession.iniciar(resultado);
      return resultado;
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Correo o contraseña incorrectos');
    }

    if (resultado is Map && resultado['detail'] != null) {
      throw Exception(resultado['detail'].toString());
    }

    throw Exception(
      'Error al iniciar sesión: HTTP ${respuesta.statusCode}',
    );
  }
}
