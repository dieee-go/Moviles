import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.length < 6) {
      context.showSnackBar('La nueva contraseña debe tener al menos 6 caracteres');
      return false;
    }
    if (password != confirm) {
      context.showSnackBar('Las contraseñas no coinciden');
      return false;
    }
    return true;
  }

  Future<void> _updatePassword() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: _passwordController.text));
      if (mounted) {
        context.showSnackBar('Contraseña actualizada. Inicia sesión nuevamente.');
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('Error inesperado', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva contraseña')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          const Text('Ingresa tu nueva contraseña para completar la recuperación.'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            obscureText: _obscureNew,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmController,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            obscureText: _obscureConfirm,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading ? null : _updatePassword,
            child: Text(_isLoading ? 'Actualizando...' : 'Actualizar contraseña'),
          ),
        ],
      ),
    );
  }
}
