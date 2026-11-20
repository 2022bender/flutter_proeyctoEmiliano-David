import 'package:flutter/material.dart';

import '../theme/koltsevaya_theme.dart';
import '../services/auth_session.dart';
import 'brand_lockup.dart';

// Menú lateral con las opciones disponibles para administradores.
class AdminDrawer extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final String rutaActual;

  const AdminDrawer({
    super.key,
    required this.usuario,
    required this.rutaActual,
  });

  String get nombre => usuario['nom_usr']?.toString() ?? 'Administrador';
  String get correo => usuario['mail']?.toString() ?? '';

  void _navegar(BuildContext context, String ruta) {
    Navigator.pop(context);
    if (ruta == rutaActual) return;
    Navigator.pushReplacementNamed(
      context,
      ruta,
      arguments: usuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Construye las opciones de navegación y cierre de sesión.
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: KoltsevayaColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLockup(compact: true),
                  const SizedBox(height: 22),
                  Text(nombre, style: Theme.of(context).textTheme.titleMedium),
                  if (correo.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(correo, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'ADMINISTRACIÓN',
                    style: TextStyle(
                      color: KoltsevayaColors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            _opcion(context, Icons.people_alt_outlined, 'Gestión de usuarios',
                '/users'),
            _opcion(context, Icons.person_add_alt_1, 'Registrar usuario',
                '/register'),
            _opcion(context, Icons.post_add, 'Agregar blog', '/add-blog'),
            _opcion(context, Icons.account_circle_outlined, 'Mi perfil',
                '/profile'),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: KoltsevayaColors.orange),
              title: const Text('Cerrar sesión',
                  style: TextStyle(color: KoltsevayaColors.orange)),
              onTap: () {
                AuthSession.cerrar();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _opcion(
    BuildContext context,
    IconData icono,
    String titulo,
    String ruta,
  ) {
    final seleccionado = ruta == rutaActual;
    return ListTile(
      leading: Icon(
        icono,
        color: seleccionado ? KoltsevayaColors.orange : null,
      ),
      title: Text(titulo),
      selected: seleccionado,
      onTap: () => _navegar(context, ruta),
    );
  }
}
