// Mantiene el token de la sesión mientras la aplicación está abierta.
class AuthSession {
  static String? _accessToken;
  static int? _tipoUsuario;

  static bool get esAdministrador => _tipoUsuario == 1;

  static Map<String, String> get headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  static void iniciar(Map<String, dynamic> respuesta) {
    _accessToken = respuesta['access_token']?.toString();
    final tipo = respuesta['tip_usu'];
    _tipoUsuario = tipo is num ? tipo.toInt() : int.tryParse('$tipo');
  }

  static void cerrar() {
    _accessToken = null;
    _tipoUsuario = null;
  }
}
