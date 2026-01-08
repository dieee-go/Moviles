import 'package:flutter/material.dart';

class PassCheckEmailScreen extends StatelessWidget {
  const PassCheckEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablece tu contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Revisa tu bandeja de entrada',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Te enviamos un correo para restablecer tu contraseña. Sigue el enlace y luego inicia sesión para continuar.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Ir a iniciar sesión'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/welcome');
                },
                child: const Text('Volver al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}