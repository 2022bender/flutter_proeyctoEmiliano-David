import 'package:flutter/foundation.dart';

// Centraliza las direcciones de la API según la plataforma donde se ejecuta la app.
class ApiConfig {
  static String get baseUrl {
    // Flutter Web accede al backend mediante localhost.
    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  static Uri resolveUri(String path) {
    // Convierte rutas relativas del backend en URLs completas.
    final uri = Uri.parse(path);
    if (uri.hasScheme) return uri;
    return Uri.parse(baseUrl).resolveUri(uri);
  }

  static Uri resolveImageUri(String path) {
    // Convierte enlaces de imágenes externas en URLs compatibles con Flutter Web.
    final uri = Uri.tryParse(path.trim());
    if (uri == null || !uri.hasScheme) return resolveUri(path);

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return Uri.parse('$baseUrl/image-proxy').replace(
        queryParameters: {'url': uri.toString()},
      );
    }

    return uri;
  }
}
