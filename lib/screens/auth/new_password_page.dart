import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    if (!hasMinLength || !hasUppercase || !hasLowercase || !hasNumber) {
      context.showSnackBar('La contraseña no cumple los requisitos');
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
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Contraseña actualizada'),
            content: const Text('Tu contraseña fue cambiada exitosamente. Inicia sesión nuevamente.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                child: const Text('Ir a login'),
              ),
            ],
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('Error inesperado', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordMatchIcon() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (confirm.isEmpty) {
      // Retorna un widget invisible para cumplir el tipo Widget
      return const SizedBox.shrink();
    }
    final match = password == confirm;
    return Icon(
      match ? Icons.check_circle : Icons.cancel,
      color: match ? Colors.green : Colors.red,
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos de contraseña:',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          _buildRequirementRow('Al menos 8 caracteres', hasMinLength),
          const SizedBox(height: 6),
          _buildRequirementRow('Al menos una mayúscula (A-Z)', hasUppercase),
          const SizedBox(height: 6),
          _buildRequirementRow('Al menos una minúscula (a-z)', hasLowercase),
          const SizedBox(height: 6),
          _buildRequirementRow('Al menos un número (0-9)', hasNumber),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isMet ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final allValid = hasMinLength && hasUppercase && hasLowercase && hasNumber && password == confirm && password.isNotEmpty && confirm.isNotEmpty;
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
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
              ),
            ),
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
          ),
          _buildPasswordRequirements(),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              color: confirm.isEmpty
                  ? null
                  : (password == confirm ? Colors.green : Colors.red),
            ),
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordMatchIcon(),
                  IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  ),
                ],
              ),
              enabledBorder: confirm.isEmpty
                  ? null
                  : OutlineInputBorder(
                      borderSide: BorderSide(
                        color: password == confirm ? Colors.green : Colors.red,
                      ),
                    ),
              focusedBorder: confirm.isEmpty
                  ? null
                  : OutlineInputBorder(
                      borderSide: BorderSide(
                        color: password == confirm ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading || !allValid ? null : _updatePassword,
            child: Text(_isLoading ? 'Actualizando...' : 'Actualizar contraseña'),
          ),
        ],
      ),
    );
  }
}
