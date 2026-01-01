import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/skeletons.dart';
import '../../main.dart';
import '../../services/interests_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;
  bool _redirecting = false;
  bool _obscurePassword = true;

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _nombreController;
  late final TextEditingController _primerApellidoController;
  late final TextEditingController _segundoApellidoController;
  late final TextEditingController _telefonoController;
  late final StreamSubscription<AuthState> _authStateSubscription;

  final _interestsService = InterestsService();

  List<Map<String, dynamic>> _intereses = [];
  late Map<String, bool> _interesesSeleccionados;
  bool _cargandoIntereses = true;
  String? _errorIntereses;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nombreController = TextEditingController();
    _primerApellidoController = TextEditingController();
    _segundoApellidoController = TextEditingController();
    _telefonoController = TextEditingController();

    _loadInterests();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        if (_redirecting) return;
        final session = data.session;
        if (session != null) {
          _redirecting = true;
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
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

  Future<void> _loadInterests() async {
    try {
      final intereses = await _interestsService.loadInterests();
      
      setState(() {
        _intereses = intereses;
        _interesesSeleccionados = {
          for (var interes in intereses)
            _interestsService.getInterestId(interes): false
        };
        _cargandoIntereses = false;
        _errorIntereses = null;
      });
    } catch (e) {
      setState(() {
        _cargandoIntereses = false;
        _errorIntereses = e.toString();
      });
      if (mounted) {
        context.showSnackBar(
          'Error cargando intereses: $e',
          isError: true,
        );
      }
    }
  }

  String _getDisplayName(Map<String, dynamic> item) {
    return _interestsService.getDisplayName(item);
  }

  bool _validateForm() {
    final nombre = _nombreController.text.trim();
    final primerApellido = _primerApellidoController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final telefono = _telefonoController.text.trim();

    if (nombre.isEmpty) {
      context.showSnackBar('Ingresa tu nombre');
      return false;
    }
    if (primerApellido.isEmpty) {
      context.showSnackBar('Ingresa tu primer apellido');
      return false;
    }
    if (email.isEmpty) {
      context.showSnackBar('Ingresa un correo');
      return false;
    }
    if (password.length < 6) {
      context.showSnackBar('La contraseña debe tener al menos 6 caracteres');
      return false;
    }
    if (telefono.isEmpty) {
      context.showSnackBar('Ingresa un teléfono');
      return false;
    }

    return true;
  }

  Future<void> _signUp() async {
    if (!_validateForm()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // 1) Crear usuario con email y contraseña
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'nombre': _nombreController.text.trim(),
          'primer_apellido': _primerApellidoController.text.trim(),
          'segundo_apellido': _segundoApellidoController.text.trim(),
          'telefono': _telefonoController.text.trim(),
        },
        emailRedirectTo: kIsWeb
            ? null
            : 'com.example.unieventos://login-callback/',
      );

      final user = response.user;
      if (user != null) {
        // El perfil lo crea el trigger en auth.users; solo guardamos intereses si hay sesión
        final selectedInterestIds = _interesesSeleccionados.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

        final hasSession = response.session != null || supabase.auth.currentSession != null;

        if (selectedInterestIds.isNotEmpty && hasSession) {
          try {
            await _interestsService.saveUserInterests(user.id, selectedInterestIds);
          } on PostgrestException catch (e) {
            if (mounted) {
              context.showSnackBar(
                'Error guardando intereses: ${e.message}',
                isError: true,
              );
            }
          }
        }

        // Si hay sesión activa, actualiza datos adicionales del perfil
        if (hasSession) {
          try {
            await supabase.from('profiles').update({
              'email': _emailController.text.trim(),
              'nombre': _nombreController.text.trim(),
              'primer_apellido': _primerApellidoController.text.trim(),
              'segundo_apellido': _segundoApellidoController.text.trim(),
              'telefono': _telefonoController.text.trim(),
            }).eq('id', user.id);
          } on PostgrestException catch (e) {
            if (mounted) {
              context.showSnackBar(
                'Perfil creado, pero no se pudo actualizar los datos: ${e.message}',
                isError: true,
              );
            }
          }
        }
      }

      if (mounted) {
        if (response.session != null) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/check-email');
        }
      }
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _primerApellidoController.dispose();
    _segundoApellidoController.dispose();
    _telefonoController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        children: [
          const Text('Crea tu cuenta'),
          const SizedBox(height: 18),
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(labelText: 'Nombre *'),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _primerApellidoController,
            decoration: const InputDecoration(labelText: 'Primer Apellido *'),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _segundoApellidoController,
            decoration: const InputDecoration(labelText: 'Segundo Apellido'),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _telefonoController,
            decoration: const InputDecoration(labelText: 'Teléfono *'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Correo institucional *'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña *',
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
          ),
          const SizedBox(height: 24),
          Text(
            'Selecciona tus intereses (máximo 3):',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (_cargandoIntereses)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Skeletons.chips(count: 8, width: 90, height: 36),
            )
          else if (_errorIntereses != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No se pudieron cargar los intereses. ${_errorIntereses!}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _loadInterests,
                  child: const Text('Reintentar'),
                ),
              ],
            )
          else if (_intereses.isEmpty)
            const Text('No hay intereses disponibles.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _intereses.map((interes) {
                final id = _interestsService.getInterestId(interes);
                final name = _getDisplayName(interes);
                final isSelected = _interesesSeleccionados[id] ?? false;
                
                return FilterChip(
                  selected: isSelected,
                  label: Text(name),
                  onSelected: (selected) {
                    setState(() {
                      if (selected && (_interesesSeleccionados.values.where((v) => v).length < 3)) {
                        _interesesSeleccionados[id] = true;
                      } else if (!selected) {
                        _interesesSeleccionados[id] = false;
                      } else if (selected && (_interesesSeleccionados.values.where((v) => v).length >= 3)) {
                        context.showSnackBar('Máximo 3 intereses permitidos');
                      }
                    });
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            child: Text(_isLoading ? 'Creando cuenta...' : 'Registrarse'),
          ),
        ],
      ),
    );
  }
}