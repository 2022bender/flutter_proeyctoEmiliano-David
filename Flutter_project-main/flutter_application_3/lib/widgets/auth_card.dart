import 'package:flutter/material.dart';

// Contenedor visual que agrupa los formularios de autenticación.
class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Aplica el estilo de tarjeta al contenido recibido.

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 410),
          child: SizedBox(
            width: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }
}
