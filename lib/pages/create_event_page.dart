import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../components/event_image_uploader.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _capacityCtrl = TextEditingController();

  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  String? _selectedLocationId;
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _interests = [];
  final Set<String> _selectedInterestIds = {};

  String? _imageUrl;
  bool _submitting = false;
  String? _profileRole;

  @override
  void initState() {
    super.initState();
    _loadRoleAndData();
  }

  Future<void> _loadRoleAndData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final roleRow = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      _profileRole = roleRow?['role'] as String?;
    } catch (_) {}

    // Load locations (catalog) if table exists; else provide local fallback
    try {
      final locs = await supabase
          .from('locations')
          .select('id, name')
          .order('name');
      _locations = List<Map<String, dynamic>>.from(locs);
    } catch (_) {
      _locations = [
        {'id': 'loc-auditorio', 'name': 'Auditorio Principal'},
        {'id': 'loc-salaa', 'name': 'Sala A'},
        {'id': 'loc-salab', 'name': 'Sala B'},
        {'id': 'loc-explanada', 'name': 'Explanada'},
      ];
    }

    // Load interests to reuse as categories
    try {
      final ints = await supabase
          .from('interests')
          .select('id, name')
          .order('name');
      _interests = List<Map<String, dynamic>>.from(ints);
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error cargando categorías: $e', isError: true);
      }
      _interests = [];
    }

    if (mounted) setState(() {});
  }

  String _interestLabel(Map<String, dynamic> row) {
    return (row['name'] as String?) ?? 'Sin nombre';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null || _eventTime == null) {
      context.showSnackBar('Selecciona fecha y hora', isError: true);
      return;
    }
    final user = supabase.auth.currentUser;
    if (user == null) {
      context.showSnackBar('Inicia sesión', isError: true);
      return;
    }
    if (!(_profileRole == 'organizer' || _profileRole == 'admin')) {
      context.showSnackBar('Solo organizadores o administradores pueden crear eventos', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      final eventDateTime = DateTime(
        _eventDate!.year,
        _eventDate!.month,
        _eventDate!.day,
        _eventTime!.hour,
        _eventTime!.minute,
      ).toUtc();

      // Insert using schema field names
      final insert = await supabase
          .from('events')
          .insert({
            'name': _nameCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'capacity': int.tryParse(_capacityCtrl.text.trim()) ?? 0,
            'organizer_id': user.id,
            'event_datetime': eventDateTime.toIso8601String(),
            'location_id': _selectedLocationId,
            'image_url': _imageUrl,
          })
          .select('id')
          .maybeSingle();

      final eventId = insert?['id'] as String?;
      if (eventId == null) {
        throw Exception('No se pudo crear el evento');
      }

      if (_selectedInterestIds.isNotEmpty) {
        final rows = _selectedInterestIds.map((iid) => {
              'event_id': eventId,
              'interest_id': iid,
            });
        await supabase.from('event_interests').insert(rows.toList());
      }

      // image_url already set during insert per schema

      if (mounted) {
        context.showSnackBar('Evento creado correctamente');
        Navigator.of(context).pop();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        context.showSnackBar('Error: ${e.message}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error inesperado', isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _eventTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del evento'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacidad'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_eventDate == null
                          ? 'Seleccionar fecha'
                          : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_eventTime == null
                          ? 'Seleccionar hora'
                          : '${_eventTime!.hour.toString().padLeft(2, '0')}:${_eventTime!.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedLocationId,
                items: _locations
                    .map((loc) => DropdownMenuItem<String>(
                          value: loc['id'] as String,
                          child: Text(loc['name'] as String),
                        ))
                    .toList(),
                decoration: const InputDecoration(labelText: 'Ubicación'),
                onChanged: (v) => setState(() => _selectedLocationId = v),
              ),
              const SizedBox(height: 12),
              Text('Categorías (máximo 3)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _interests.map((i) {
                  final id = i['id'] as String;
                  final selected = _selectedInterestIds.contains(id);
                  return FilterChip(
                    selected: selected,
                    label: Text(_interestLabel(i)),
                    onSelected: (v) {
                      setState(() {
                        if (v && _selectedInterestIds.length < 3) {
                          _selectedInterestIds.add(id);
                        } else if (!v) {
                          _selectedInterestIds.remove(id);
                        } else if (v && _selectedInterestIds.length >= 3) {
                          context.showSnackBar('Máximo 3 categorías permitidas');
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              EventImageUploader(
                imageUrl: _imageUrl,
                onUpload: (url) => setState(() => _imageUrl = url),
                width: 150,
                height: 90,
                buttonLabel: 'Seleccionar imagen',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('Crear evento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
