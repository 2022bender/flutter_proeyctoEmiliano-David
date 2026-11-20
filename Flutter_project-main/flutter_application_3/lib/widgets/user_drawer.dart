import 'package:flutter/material.dart';

import '../theme/koltsevaya_theme.dart';
import '../services/auth_session.dart';
import 'brand_lockup.dart';

// Menú lateral para usuarios normales.
class UserDrawer extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final String rutaActual;

  const UserDrawer({
    super.key,
    required this.usuario,
    required this.rutaActual,
  });

  String get nombre => usuario['nom_usr']?.toString() ?? '';
  String get correo => usuario['mail']?.toString() ?? '';

  void _navegar(BuildContext context, String ruta) {
    // Cierra el menú y navega a la sección seleccionada.
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
    // Presenta los datos del usuario y sus opciones de navegación.
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
                ],
              ),
            ),
            _opcion(context, Icons.article_outlined, 'Blog', '/blog'),
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
      title: Text(
        titulo,
        style: TextStyle(
          color: seleccionado ? KoltsevayaColors.amber : null,
        ),
      ),
      selected: seleccionado,
      onTap: () => _navegar(context, ruta),
    );
  }
}
