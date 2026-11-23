import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/calificacion_model.dart';
import '../models/comentario_model.dart';
import '../models/post_model.dart';
import '../services/calificacion_service.dart';
import '../services/comentario_service.dart';

// Pantalla que muestra una publicación completa y permite agregar comentarios.
class PostDetailPage extends StatefulWidget {
  // Publicación que se recibió desde la lista del blog.
  final PostModel post;

  // Datos del usuario que inició sesión, necesarios para guardar comentarios.
  final Map<String, dynamic> usuario;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.usuario,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

// Estado de la pantalla de detalle.
class _PostDetailPageState extends State<PostDetailPage> {
  // Controla el texto escrito por el usuario en el campo de comentario.
  final _comentarioController = TextEditingController();

  // Servicio encargado de consultar y registrar comentarios en la API.
  final _comentarioService = ComentarioService();
  final _calificacionService = CalificacionService();

  // Future que contiene los comentarios de la publicación actual.
  late Future<List<ComentarioModel>> _comentarios;
  late Future<CalificacionModel> _calificacion;

  // Evita enviar más de un comentario al mismo tiempo.
  bool _enviando = false;
  bool _guardandoCalificacion = false;

  @override
  void initState() {
    super.initState();

    // Carga los comentarios asociados al ID de la publicación.
    _comentarios = _comentarioService.obtenerComentarios(widget.post.id);
    _calificacion = _calificacionService.obtener(widget.post.id);
  }

  @override
  void dispose() {
    // Libera el controlador cuando la pantalla deja de existir.
    _comentarioController.dispose();
    super.dispose();
  }

  // Valida y envía el comentario del usuario a la API.
  Future<void> _enviarComentario() async {
    final texto = _comentarioController.text.trim();

    // Se acepta el identificador con cualquiera de los nombres usados por la app.
    final identificador = widget.usuario['id_usr'] ?? widget.usuario['id'];
    final usuarioId = identificador is num
        ? identificador.toInt()
        : int.tryParse(identificador?.toString() ?? '');

    // No permite enviar comentarios vacíos.
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un comentario')),
      );
      return;
    }

    // Sin usuario identificado no se puede asociar el comentario.
    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al usuario')),
      );
      return;
    }

    // Deshabilita el botón mientras se realiza la petición.
    setState(() => _enviando = true);

    try {
      // Construye el comentario con el usuario y la publicación actuales.
      await _comentarioService.agregarComentario(
        ComentarioModel(
          id: 0,
          comentario: texto,
          fecha: '',
          estatus: 1,
          usuarioId: usuarioId,
          blogId: widget.post.id,
        ),
      );

      if (!mounted) return;

      // Limpia el campo y vuelve a consultar los comentarios actualizados.
      _comentarioController.clear();
      setState(() {
        _comentarios = _comentarioService.obtenerComentarios(widget.post.id);
      });
    } catch (error) {
      if (!mounted) return;

      // Muestra el error devuelto por la API o por la conexión.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el comentario: $error')),
      );
    } finally {
      // Reactiva el botón aunque la petición falle.
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _guardarCalificacion(int estrellas) async {
    setState(() => _guardandoCalificacion = true);
    try {
      final resumen = await _calificacionService.guardar(
        widget.post.id,
        estrellas,
      );
      if (!mounted) return;
      setState(() => _calificacion = Future.value(resumen));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la calificación: $error')),
      );
    } finally {
      if (mounted) setState(() => _guardandoCalificacion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de publicación')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.imagen.isNotEmpty)
                        Image.network(
                          ApiConfig.resolveImageUri(post.imagen).toString(),
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 160,
                            color: const Color(0xFF1C1510),
                            alignment: Alignment.center,
                            child: const Text('No se pudo cargar la imagen'),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.tags.isNotEmpty) ...[
                              Text(
                                post.tags,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .6,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Text(
                              post.titulo,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 14),
                            Text(post.descripcion),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FutureBuilder<CalificacionModel>(
                  future: _calificacion,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'No se pudieron cargar las calificaciones: ${snapshot.error}',
                      );
                    }

                    final calificacion = snapshot.data!;
                    final seleccion = calificacion.miCalificacion ?? 0;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Califica esta publicación',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (index) {
                                  final estrellas = index + 1;
                                  return IconButton(
                                    tooltip: '$estrellas estrellas',
                                    onPressed: _guardandoCalificacion
                                        ? null
                                        : () => _guardarCalificacion(estrellas),
                                    icon: Icon(
                                      estrellas <= seleccion
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Text(
                              calificacion.total == 0
                                  ? 'Sin calificaciones todavía'
                                  : 'Promedio ${calificacion.promedio.toStringAsFixed(1)} · '
                                      '${calificacion.total} '
                                      '${calificacion.total == 1 ? 'voto' : 'votos'}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              seleccion == 0
                                  ? 'Tu calificación: aún no has votado'
                                  : 'Tu calificación: $seleccion/5',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (_guardandoCalificacion)
                              const LinearProgressIndicator(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 26),
                Text(
                  'Comentarios',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<ComentarioModel>>(
                  future: _comentarios,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Text(
                        'Error al cargar comentarios: ${snapshot.error}',
                      );
                    }

                    final comentarios = snapshot.data ?? [];
                    if (comentarios.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Todavía no hay comentarios.'),
                      );
                    }

                    return Column(
                      children: comentarios
                          .map(
                            (comentario) => Card(
                              margin: const EdgeInsets.only(bottom: 9),
                              child: ListTile(
                                leading: const Icon(Icons.forum_outlined),
                                title: Text(comentario.comentario),
                                subtitle: Text(comentario.fecha),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _comentarioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Escribe un comentario',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _enviando ? null : _enviarComentario,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(_enviando ? 'Enviando...' : 'Comentar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
