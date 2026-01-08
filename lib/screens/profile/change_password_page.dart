import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    if (newPassword.length < 6) {
      context.showSnackBar('La nueva contraseña debe tener al menos 6 caracteres');
      return false;
    }
    
    if (newPassword != confirmPassword) {
      context.showSnackBar('Las contraseñas no coinciden');
      return false;
    }
    
    return true;
  }

  Future<void> _changePassword() async {
    if (!_validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');
      
      final email = user.email;
      if (email == null) throw Exception('Email no disponible');
      
      // Validar contraseña actual
      try {
        await supabase.auth.signInWithPassword(
          email: email,
          password: _currentPasswordController.text,
        );
      } on AuthException {
        if (mounted) context.showSnackBar('Contraseña actual incorrecta', isError: true);
        return;
      }
      
      // Cambiar a la nueva contraseña
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );
      
      if (mounted) {
        context.showSnackBar('Contraseña actualizada correctamente');
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) context.showSnackBar('Error: ${e.message}', isError: true);
    } catch (e) {
      if (mounted) context.showSnackBar('Error inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordMatchIcon() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    if (confirmPassword.isEmpty) {
      return IconButton(
        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
      );
    }
    
    final match = newPassword == confirmPassword;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          match ? Icons.check_circle : Icons.cancel,
          color: match ? Colors.green : Colors.red,
        ),
        IconButton(
          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _newPasswordController.text;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar contraseña'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        children: [
          const Text(
            'Para cambiar tu contraseña, primero debes ingresar tu contraseña actual.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _currentPasswordController,
            decoration: InputDecoration(
              labelText: 'Contraseña actual',
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            obscureText: _obscureCurrent,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            obscureText: _obscureNew,
            enabled: !_isLoading,
          ),
          _buildPasswordRequirements(),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirmar nueva contraseña',
              suffixIcon: _buildPasswordMatchIcon(),
            ),
            obscureText: _obscureConfirm,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _changePassword,
            child: Text(_isLoading ? 'Actualizando...' : 'Actualizar contraseña'),
          ),
        ],
      ),
    );
  }
}
