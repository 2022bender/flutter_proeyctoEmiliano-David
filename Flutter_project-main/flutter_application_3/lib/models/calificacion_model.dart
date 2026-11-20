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
    final miCalificacion = json['mi_calificacion'];
    return CalificacionModel(
      publicacionId: (json['id_publicacion'] as num).toInt(),
      promedio: (json['promedio'] as num).toDouble(),
      total: (json['total'] as num).toInt(),
      miCalificacion:
          miCalificacion is num ? miCalificacion.toInt() : null,
    );
  }
}
