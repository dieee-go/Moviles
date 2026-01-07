import 'package:flutter/material.dart';

import '../../main.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Acceso denegado: no autenticado')),
      );
    }

    return FutureBuilder(
      future: supabase.from('profiles').select('role').eq('id', userId).maybeSingle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text('Acceso denegado')));
        }
        final role = (snapshot.data as Map<String, dynamic>)['role'] as String? ?? '';
        if (role.toLowerCase() == 'admin' || role.toLowerCase() == 'organizer') {
          return child;
        }
        return const Scaffold(
          body: Center(child: Text('Acceso denegado: necesitas permisos de administrador')),
        );
      },
    );
  }
}