import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/calificacion_model.dart';
import 'auth_session.dart';

class CalificacionService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<CalificacionModel> obtener(int publicacionId) async {
    final respuesta = await http
        .get(
          Uri.parse('$baseUrl/calificaciones/$publicacionId'),
          headers: AuthSession.headers,
        )
        .timeout(const Duration(seconds: 10));

    return _leerRespuesta(respuesta);
  }

  Future<CalificacionModel> guardar(
    int publicacionId,
    int estrellas,
  ) async {
    final respuesta = await http
        .put(
          Uri.parse('$baseUrl/calificaciones/$publicacionId'),
          headers: AuthSession.headers,
          body: jsonEncode({'calificacion': estrellas}),
        )
        .timeout(const Duration(seconds: 10));

    return _leerRespuesta(respuesta);
  }

  CalificacionModel _leerRespuesta(http.Response respuesta) {
    final dynamic resultado =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    if (respuesta.statusCode == 200 && resultado is Map<String, dynamic>) {
      return CalificacionModel.fromJson(resultado);
    }

    if (resultado is Map && resultado['detail'] != null) {
      throw Exception(resultado['detail'].toString());
    }

    throw Exception(
      'No se pudo consultar la calificación (HTTP ${respuesta.statusCode})',
    );
  }
}
