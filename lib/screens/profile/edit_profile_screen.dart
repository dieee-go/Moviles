import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  List<Map<String, dynamic>> _allInterests = [];
  Set<String> _selectedInterestIds = {};
  
  List<Map<String, dynamic>> _carreras = [];
  List<Map<String, dynamic>> _departamentos = [];
  String? _selectedCarreraId;
  String? _selectedDepartamentoId;
  String? _userRole;
  
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
      
      // Get user's role
      _userRole = data['role'] as String?;
      
      // Load all carreras
      final carreras = await supabase
          .from('carreras')
          .select('id, name')
          .order('name');
      _carreras = List<Map<String, dynamic>>.from(carreras);
      
      // Load all departamentos
      final departamentos = await supabase
          .from('departamentos')
          .select('id, name')
          .order('name');
      _departamentos = List<Map<String, dynamic>>.from(departamentos);
      
      // Load user's selected carrera (if student)
      if (_userRole == 'student') {
        final userCarrera = await supabase
            .from('user_carrera')
            .select('carrera_id')
            .eq('user_id', userId)
            .maybeSingle();
        if (userCarrera != null) {
          _selectedCarreraId = userCarrera['carrera_id'] as String?;
        }
      }
      
      // Load user's selected departamento (if organizer)
      if (_userRole == 'organizer') {
        final userDepartamento = await supabase
            .from('user_departamento')
            .select('departamento_id')
            .eq('user_id', userId)
            .maybeSingle();
        if (userDepartamento != null) {
          _selectedDepartamentoId = userDepartamento['departamento_id'] as String?;
        }
      }
      
      // Load all available interests
      final interests = await supabase
          .from('interests')
          .select('id, name')
          .order('name');
      _allInterests = List<Map<String, dynamic>>.from(interests);
      
      // Load user's selected interests
      final userInterests = await supabase
          .from('user_interests')
          .select('interest_id')
          .eq('user_id', userId);
      
      _selectedInterestIds = (userInterests as List)
          .map((item) => item['interest_id'] as String)
          .toSet();
      
      debugPrint('Loaded ${_allInterests.length} total interests');
      debugPrint('User has ${_selectedInterestIds.length} selected interests: $_selectedInterestIds');
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
      }).eq('id', userId);

      // Upsert interests (insert if not exists, ignore if already exists)
      // This is more efficient than delete + insert
      if (_selectedInterestIds.isNotEmpty) {
        final interestsToUpsert = _selectedInterestIds
            .map((interestId) => {
                  'user_id': userId,
                  'interest_id': interestId,
                })
            .toList();
        
        debugPrint('Upserting ${interestsToUpsert.length} interests');
        await supabase
            .from('user_interests')
            .upsert(
              interestsToUpsert,
              onConflict: 'user_id,interest_id',
            );
        debugPrint('Successfully upserted interests');
      } else {
        // Delete all interests if none selected
        await supabase
            .from('user_interests')
            .delete()
            .eq('user_id', userId);
      }

      // Handle carrera for students
      if (_userRole == 'student') {
        // Delete existing carrera
        await supabase
            .from('user_carrera')
            .delete()
            .eq('user_id', userId);

        // Insert new carrera if selected
        if (_selectedCarreraId != null) {
          await supabase.from('user_carrera').insert({
            'user_id': userId,
            'carrera_id': _selectedCarreraId,
          });
        }
      }

      // Handle departamento for organizers
      if (_userRole == 'organizer') {
        // Delete existing departamento
        await supabase
            .from('user_departamento')
            .delete()
            .eq('user_id', userId);

        // Insert new departamento if selected
        if (_selectedDepartamentoId != null) {
          await supabase.from('user_departamento').insert({
            'user_id': userId,
            'departamento_id': _selectedDepartamentoId,
          });
        }
      }

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
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Editar Perfil"),
            centerTitle: true,
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          body: _buildLoadingSkeleton(),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Editar Perfil"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          titleTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.black,
          ),
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

                  // Sección de Intereses
                  _buildSectionHeader(
                    icon: Icons.interests,
                    title: 'Mis Intereses',
                  ),
                  const SizedBox(height: 20),
                  _buildInterestsSection(),

                  const SizedBox(height: 16),

                  // Sección de Académica o Departamento (según rol)
                  if (_userRole == 'student') ...[
                    _buildSectionHeader(
                      icon: Icons.school,
                      title: 'Información Académica',
                    ),
                    const SizedBox(height: 20),
                    _buildCarreraDropdown(),
                  ] else if (_userRole == 'organizer') ...[
                    _buildSectionHeader(
                      icon: Icons.business,
                      title: 'Departamento',
                    ),
                    const SizedBox(height: 20),
                    _buildDepartamentoDropdown(),
                  ],

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
      ),
    );
  }

  Widget _buildInterestsSection() {
    final scheme = Theme.of(context).colorScheme;
    
    if (_allInterests.isEmpty) {
      return Center(
        child: Text(
          'No hay intereses disponibles',
          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allInterests.map((interest) {
        final id = interest['id'] as String;
        final name = interest['name'] as String;
        final isSelected = _selectedInterestIds.contains(id);
        
        return FilterChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedInterestIds.add(id);
              } else {
                _selectedInterestIds.remove(id);
              }
            });
          },
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: isSelected ? scheme.primary : scheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          labelStyle: TextStyle(
            color: isSelected ? scheme.primary : scheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCarreraDropdown() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCarreraId,
        hint: const Text('Selecciona tu carrera'),
        items: _carreras.map((carrera) {
          return DropdownMenuItem<String>(
            value: carrera['id'] as String,
            child: Text(carrera['name'] as String),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedCarreraId = value);
        },
        decoration: InputDecoration(
          labelText: 'Carrera',
          prefixIcon: const Icon(Icons.school_outlined),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDepartamentoDropdown() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedDepartamentoId,
        hint: const Text('Selecciona tu departamento'),
        items: _departamentos.map((departamento) {
          return DropdownMenuItem<String>(
            value: departamento['id'] as String,
            child: Text(departamento['name'] as String),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedDepartamentoId = value);
        },
        decoration: InputDecoration(
          labelText: 'Departamento',
          prefixIcon: const Icon(Icons.business_outlined),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
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

  Widget _buildLoadingSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Skeletons.form(
            fields: 6,
            fieldHeight: 56,
            spacing: 16,
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Skeletons.box(
                  height: 52,
                  radius: 12,
                  baseColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Skeletons.box(
                  height: 52,
                  radius: 12,
                  baseColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}