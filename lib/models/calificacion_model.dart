// Resumen público y calificación del usuario para una publicación.
class CalificacionModel {
  final int publicacionId;
  final double promedio;
  final int total;
  final int? miCalificacion;

  const CalificacionModel({
    required this.publicacionId,
    required this.promedio,
    required this.total,
    required this.miCalificacion,
  });

  factory CalificacionModel.fromJson(Map<String, dynamic> json) {
    final publicacionId = json['id_publicacion'];
    final promedio = json['promedio'];
    final total = json['total'];
    final miCalificacion = json['mi_calificacion'];

    if (publicacionId is! num || promedio is! num || total is! num) {
      throw const FormatException(
        'La respuesta de calificaciones no tiene el formato esperado',
      );
    }
    if (publicacionId <= 0 ||
        promedio < 0 ||
        promedio > 5 ||
        total < 0 ||
        total != total.toInt() ||
        (miCalificacion != null &&
            (miCalificacion is! num ||
                miCalificacion != miCalificacion.toInt() ||
                miCalificacion < 1 ||
                miCalificacion > 5))) {
      throw const FormatException(
        'La respuesta contiene una calificación fuera de rango',
      );
    }

    return CalificacionModel(
      publicacionId: publicacionId.toInt(),
      promedio: promedio.toDouble(),
      total: total.toInt(),
      miCalificacion:
          miCalificacion is num ? miCalificacion.toInt() : null,
    );
  }
}
