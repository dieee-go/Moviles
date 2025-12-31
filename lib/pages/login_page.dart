import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../screens/home/home_screen.dart';
import 'reset_password_page.dart';
import 'new_password_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _redirecting = false;
  bool _obscurePassword = true;

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _setupAuthListener();
    super.initState();
  }

  void _setupAuthListener() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        if (_redirecting) return;
        final event = data.event;
        final session = data.session;

        // Handle password recovery deep link
        if (event == AuthChangeEvent.passwordRecovery) {
          _redirecting = true;
          if (mounted) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => const NewPasswordPage()))
                .then((_) {
              // Allow subsequent redirects after returning
              _redirecting = false;
            });
          }
          return;
        }

        // Normal auth redirect to home
        if (session != null) {
          _redirecting = true;
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      },
      onError: (error) {
        if (mounted) {
          if (error is AuthException) {
            context.showSnackBar(error.message, isError: true);
          } else {
            context.showSnackBar('Error inesperado', isError: true);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  bool _validateCredentials() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      context.showSnackBar('Ingresa un correo');
      return false;
    }
    if (password.length < 6) {
      context.showSnackBar('La contraseña debe tener al menos 6 caracteres');
      return false;
    }
    return true;
  }

  Future<void> _signIn() async {
    if (!_validateCredentials()) return;
    try {
      setState(() {
        _isLoading = true;
      });
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      if (mounted) context.showSnackBar(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Error inesperado', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          const Text('Inicia sesión con tu cuenta'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            child: Text(_isLoading ? 'Ingresando...' : 'Iniciar sesión'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const ResetPasswordPage()),
              );
            },
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SignupPage()),
              );
            },
            child: const Text('¿No tienes cuenta? Regístrate aquí'),
          ),
        ],
      ),
    );
  }
}