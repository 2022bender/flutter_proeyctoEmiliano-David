import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/user_drawer.dart';
import '../widgets/brand_lockup.dart';

// Pantalla donde un administrador crea una publicación.
class AddBlogPage extends StatefulWidget {
  const AddBlogPage({super.key});

  @override
  State<AddBlogPage> createState() => _AddBlogPageState();
}

// Estado del formulario de creación de publicaciones.
class _AddBlogPageState extends State<AddBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _tags = TextEditingController();
  final _imagenUrl = TextEditingController();
  final _servicio = PostService();

  bool _guardando = false;
  Map<String, dynamic> _usuario = {};

  @override
  void didChangeDependencies() {
    // Recupera los datos del usuario para configurar el menú.
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _usuario = Map<String, dynamic>.from(args);
    }
  }

  @override
  void dispose() {
    // Libera los controladores de los campos.
    _titulo.dispose();
    _descripcion.dispose();
    _tags.dispose();
    _imagenUrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await _servicio.agregarPost(
        titulo: _titulo.text,
        descripcion: _descripcion.text,
        imagenUrl: _imagenUrl.text,
        tags: _tags.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación agregada correctamente')),
      );
      _titulo.clear();
      _descripcion.clear();
      _tags.clear();
      _imagenUrl.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construye el formulario para título, descripción, imagen y etiquetas.
    final esAdministrador = (_usuario['tip_usu'] as num? ?? 2).toInt() == 1;
    final nombre = _usuario['nom_usr']?.toString() ?? 'Usuario';
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar publicación')),
      drawer: esAdministrador
          ? AdminDrawer(usuario: _usuario, rutaActual: '/add-blog')
          : UserDrawer(usuario: _usuario, rutaActual: '/add-blog'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandLockup(compact: true),
                      const SizedBox(height: 22),
                      Text(
                        'Nueva publicación',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                          '${esAdministrador ? 'Administrador' : 'Usuario'}: $nombre'),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titulo,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa el título'
                            : v.trim().length < 2
                                ? 'El título debe tener al menos 2 caracteres'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descripcion,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa la descripción'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _imagenUrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Enlace de la imagen',
                          hintText: 'https://ejemplo.com/imagen.jpg',
                        ),
                        validator: (valor) {
                          final url = Uri.tryParse(valor?.trim() ?? '');
                          if (url == null ||
                              !url.hasScheme ||
                              (url.scheme != 'http' && url.scheme != 'https') ||
                              url.host.isEmpty) {
                            return 'Ingresa un enlace válido (http:// o https://)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tags,
                        decoration: const InputDecoration(
                          labelText: 'Etiquetas (opcional)',
                          hintText: 'flutter, tecnología, móvil',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: Text(_guardando
                            ? 'Guardando...'
                            : 'Guardar publicación'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
