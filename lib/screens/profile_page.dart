import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_session.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/user_drawer.dart';
import '../widgets/brand_lockup.dart';
import '../theme/koltsevaya_theme.dart';

// Pantalla para consultar y editar el perfil del usuario.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// Estado del formulario y datos actuales del perfil.
class _ProfilePageState extends State<ProfilePage> {
  static String get baseUrl => ApiConfig.baseUrl;
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _direccion = TextEditingController();
  Map<String, dynamic> _usuario = {};
  bool _cargando = false;
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    // Carga los datos enviados desde la pantalla anterior.
    super.didChangeDependencies();
    if (_inicializado) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _usuario = Map<String, dynamic>.from(args);
    }
    _nombre.text = _usuario['nom_usr']?.toString() ?? '';
    _correo.text = _usuario['mail']?.toString() ?? '';
    _direccion.text = _usuario['dir_usr']?.toString() ?? '';
    _inicializado = true;
  }

  @override
  void dispose() {
    // Libera los controladores del formulario.
    _nombre.dispose();
    _correo.dispose();
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    // Valida y guarda los cambios del perfil mediante la API.
    if (!_formKey.currentState!.validate()) return;
    final id = _usuario['id_usr'];
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No se recibió el identificador del usuario. Vuelve a iniciar sesión.')),
      );
      return;
    }
    setState(() => _cargando = true);
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/usuarios/$id'),
            headers: AuthSession.headers,
            body: jsonEncode({
              'nom_usr': _nombre.text.trim(),
              'mail': _correo.text.trim().toLowerCase(),
              'dir_usr': _direccion.text.trim().isEmpty
                  ? null
                  : _direccion.text.trim(),
              'tip_usu': (_usuario['tip_usu'] as num?)?.toInt() ?? 1,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final dynamic data =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;
      if (response.statusCode != 200) {
        final detail = data is Map ? data['detail'] : null;
        throw Exception(
            detail?.toString() ?? 'Error HTTP ${response.statusCode}');
      }
      if (data is Map<String, dynamic>) {
        _usuario = Map<String, dynamic>.from(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construye el formulario y el menú lateral del perfil.
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      drawer: (_usuario['tip_usu'] as num? ?? 1).toInt() == 1
          ? AdminDrawer(usuario: _usuario, rutaActual: '/profile')
          : UserDrawer(usuario: _usuario, rutaActual: '/profile'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
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
                      const SizedBox(height: 24),
                      const CircleAvatar(
                        radius: 38,
                        backgroundColor: Color(0xFF24170F),
                        foregroundColor: KoltsevayaColors.amber,
                        child: Icon(Icons.person_outline, size: 42),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nombre,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                        ),
                        validator: (v) => v == null || v.trim().length < 2
                            ? 'Ingresa un nombre válido'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _correo,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Ingresa un correo válido'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _direccion,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _cargando ? null : _guardar,
                        icon: const Icon(Icons.save),
                        label: Text(
                            _cargando ? 'Guardando...' : 'Guardar cambios'),
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
