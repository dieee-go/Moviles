import 'package:flutter/material.dart';
import '../../components/skeletons.dart';
import '../../main.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _primerApellidoCtrl;
  late TextEditingController _segundoApellidoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _carreraCtrl;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _primerApellidoCtrl = TextEditingController();
    _segundoApellidoCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _carreraCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }
      final data = await supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

      _nombreCtrl.text = data['nombre'] as String? ?? '';
      _primerApellidoCtrl.text = data['primer_apellido'] as String? ?? '';
      _segundoApellidoCtrl.text = data['segundo_apellido'] as String? ?? '';
      _emailCtrl.text = data['email'] as String? ?? '';
      _carreraCtrl.text = data['carrera'] as String? ?? '';
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error cargando perfil: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('profiles').update({
        'nombre': _nombreCtrl.text.trim(),
        'primer_apellido': _primerApellidoCtrl.text.trim(),
        'segundo_apellido': _segundoApellidoCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'carrera': _carreraCtrl.text.trim(),
      }).eq('id', userId);

      if (mounted) {
        context.showSnackBar('Perfil actualizado');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error al guardar: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _primerApellidoCtrl.dispose();
    _segundoApellidoCtrl.dispose();
    _emailCtrl.dispose();
    _carreraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingSkeleton();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil"), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _primerApellidoCtrl,
                decoration: const InputDecoration(labelText: "Primer apellido"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _segundoApellidoCtrl,
                decoration: const InputDecoration(labelText: "Segundo apellido"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Correo electrónico"),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _carreraCtrl,
                decoration: const InputDecoration(labelText: "Carrera/Departamento"),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("Cancelar"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Guardar Cambios"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold _buildLoadingSkeleton() {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil"), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeletons.form(fields: 5, fieldHeight: 52, spacing: 16),
            const SizedBox(height: 24),
            Skeletons.box(height: 50, radius: 12),
          ],
        ),
      ),
    );
  }
}