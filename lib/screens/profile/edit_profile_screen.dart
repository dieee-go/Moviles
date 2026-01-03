import 'package:flutter/material.dart';
import '../../components/skeletons.dart';
import '../../main.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _primerApellidoCtrl;
  late TextEditingController _segundoApellidoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _carreraCtrl;
  
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  
  bool _loading = true;
  bool _saving = false;
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _primerApellidoCtrl = TextEditingController();
    _segundoApellidoCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _carreraCtrl = TextEditingController();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _loadProfile();
    _slideController.forward();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _primerApellidoCtrl.dispose();
    _segundoApellidoCtrl.dispose();
    _emailCtrl.dispose();
    _carreraCtrl.dispose();
    _slideController.dispose();
    _focusNode?.dispose();
    super.dispose();
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

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 16,
          color: scheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: isDark 
            ? Colors.grey[900]?.withValues(alpha: 0.3)
            : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: scheme.outline.withValues(alpha: 0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: scheme.outline.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: scheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'Campo obligatorio';
          }
          return null;
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Editar Perfil"),
          centerTitle: true,
        ),
        body: _buildLoadingSkeleton(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: isDark 
        ? scheme.surface 
        : Colors.grey[50],
      body: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: FadeTransition(
          opacity: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de Nombre
                  _buildSectionHeader(
                    icon: Icons.person,
                    title: 'Información Básica',
                  ),
                  const SizedBox(height: 20),
                  _buildCustomTextField(
                    controller: _nombreCtrl,
                    label: 'Nombre',
                    hint: 'Tu nombre completo',
                    icon: Icons.person_outline,
                    isRequired: true,
                  ),
                  
                  // Apellidos
                  Row(
                    children: [
                      Expanded(
                        child: _buildCustomTextField(
                          controller: _primerApellidoCtrl,
                          label: 'Primer Apellido',
                          hint: 'Primer apellido',
                          icon: Icons.badge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCustomTextField(
                          controller: _segundoApellidoCtrl,
                          label: 'Segundo Apellido',
                          hint: 'Segundo apellido',
                          icon: Icons.badge,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sección de Contacto
                  _buildSectionHeader(
                    icon: Icons.email,
                    title: 'Información de Contacto',
                  ),
                  const SizedBox(height: 20),
                  _buildCustomTextField(
                    controller: _emailCtrl,
                    label: 'Correo Electrónico',
                    hint: 'tu.email@ejemplo.com',
                    icon: Icons.email_outlined,
                    isRequired: true,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Sección de Académica
                  _buildSectionHeader(
                    icon: Icons.school,
                    title: 'Información Académica',
                  ),
                  const SizedBox(height: 20),
                  _buildCustomTextField(
                    controller: _carreraCtrl,
                    label: 'Carrera/Departamento',
                    hint: 'Ej: Ingeniería en Informática',
                    icon: Icons.school_outlined,
                  ),

                  const SizedBox(height: 40),

                  // Botones de Acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving 
                            ? null 
                            : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancelar",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            backgroundColor: scheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    scheme.onPrimary,
                                  ),
                                ),
                              )
                            : const Text(
                                "Guardar Cambios",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    final scheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: scheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  Scaffold _buildLoadingSkeleton() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Skeletons.form(fields: 6, fieldHeight: 56, spacing: 16),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: Skeletons.box(height: 52, radius: 12)),
                const SizedBox(width: 12),
                Expanded(child: Skeletons.box(height: 52, radius: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}