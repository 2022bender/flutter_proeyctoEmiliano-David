import 'dart:convert'; //SIRVE PARA TRANSFORMAR EN JSON
import 'package:http/http.dart' as http; 
import '../config/api_config.dart';
import '../models/calificacion_model.dart';
import 'auth_session.dart';

class CalificacionService {
  static String get baseUrl => ApiConfig.baseUrl; //OBTIENE LA DIRECCION API

  Future<CalificacionModel> obtener(int publicacionId) async { //OBTENER CALIFIACION 
    _validarPublicacionId(publicacionId);
    final respuesta = await http
        .get(
          Uri.parse('$baseUrl/calificaciones/$publicacionId'),
          headers: AuthSession.headers,
        )
        .timeout(const Duration(seconds: 10));

    return _leerRespuesta(respuesta, publicacionId);
  }

  Future<CalificacionModel> guardar( //GUARDAR CALIFICACION
    int publicacionId,
    int estrellas,
  ) async {
    _validarPublicacionId(publicacionId);
    if (estrellas < 1 || estrellas > 5) {
      throw ArgumentError.value(estrellas, 'estrellas', 'Debe estar entre 1 y 5');
    }

    final respuesta = await http
        .put(
          Uri.parse('$baseUrl/calificaciones/$publicacionId'),
          headers: AuthSession.headers,
          body: jsonEncode({'calificacion': estrellas}),
        )
        .timeout(const Duration(seconds: 10));

    return _leerRespuesta(respuesta, publicacionId);
  }

  void _validarPublicacionId(int publicacionId) { //SE VALIDA LA CALIFICACION
    if (publicacionId <= 0) {
      throw ArgumentError.value(
        publicacionId,
        'publicacionId',
        'Debe ser un ID de publicación válido',
      );
    }
  }

  CalificacionModel _leerRespuesta(
    http.Response respuesta,
    int publicacionId,
  ) {
    dynamic resultado;
    try {
      resultado = respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    } on FormatException {
      throw Exception(
        respuesta.statusCode == 200
            ? 'La API devolvió una respuesta de calificación no válida'
            : 'No se pudo completar la petición de calificación '
                '(HTTP ${respuesta.statusCode})',
      );
    }

    if (respuesta.statusCode != 200) {
      if (resultado is Map && resultado['detail'] != null) {
        throw Exception(resultado['detail'].toString());
      }

      throw Exception(
        'No se pudo completar la petición de calificación '
        '(HTTP ${respuesta.statusCode})',
      );
    }

    if (resultado is! Map<String, dynamic>) {
      throw Exception('La API devolvió una respuesta de calificación no válida');
    }

    final calificacion = CalificacionModel.fromJson(resultado);
    if (calificacion.publicacionId != publicacionId) {
      throw Exception(
        'La API devolvió una calificación de otra publicación',
      );
    }
    return calificacion;
  }
}
