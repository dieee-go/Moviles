import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/skeletons.dart';
import '../../main.dart';
import '../../theme/app_theme_extensions.dart';
import '../../utils/image_crop_helper.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  const EditEventScreen({super.key, required this.eventId});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime? eventDate;
  TimeOfDay? startTime;
  String? _imageUrl;
  bool _loading = true;
  bool _uploadingImage = false;

  List<Map<String, dynamic>> _allCategories = [];
  Set<String> _selectedCategoryIds = {};
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('events')
          .select('id, name, description, image_url, event_datetime')
          .eq('id', widget.eventId)
          .single();

      final iso = data['event_datetime'] as String?;
      DateTime dt = DateTime.now();
      if (iso != null) {
        dt = DateTime.parse(iso).toLocal();
      }

      titleController.text = data['name'] as String? ?? '';
      descriptionController.text = data['description'] as String? ?? '';
      _imageUrl = data['image_url'] as String?;
      eventDate = DateTime(dt.year, dt.month, dt.day);
      startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);

      // Cargar categorías
      await _loadCategories();

      // Cargar categorías del evento
      await _loadEventCategories();
    } on PostgrestException catch (e) {
      if (mounted) {
        context.showSnackBar('Error: ${e.message}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final data = await supabase.from('interests').select('id, name').order('name');
      setState(() {
        _allCategories = List<Map<String, dynamic>>.from(data);
        _loadingCategories = false;
      });
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error cargando categorías: $e', isError: true);
      }
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadEventCategories() async {
    try {
      final data = await supabase
          .from('event_interests')
          .select('interest_id')
          .eq('event_id', widget.eventId);

      setState(() {
        _selectedCategoryIds = (data as List)
            .map((item) => item['interest_id'] as String)
            .toSet();
      });
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error cargando categorías: $e', isError: true);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final selection = await ImageCropHelper.pickOriginalAndCropped(ratio: 5.0 / 4.0);
      if (selection == null) return;
      final (picked, cropped) = selection;

      setState(() => _uploadingImage = true);

      final fileName = 'event_${widget.eventId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final originalPath = 'events/originals/$fileName';
      final thumbPath = 'events/thumbs/$fileName';

      await supabase.storage.from('events').uploadBinary(
            originalPath,
            await picked.readAsBytes(),
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: picked.mimeType ?? 'image/jpeg',
            ),
          );

      await supabase.storage.from('events').uploadBinary(
            thumbPath,
            await cropped.readAsBytes(),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true, contentType: 'image/jpeg'),
          );

      final publicUrl = supabase.storage.from('events').getPublicUrl(thumbPath);

      setState(() {
        _imageUrl = publicUrl;
        _uploadingImage = false;
      });

      if (mounted) context.showSnackBar('Imagen cargada exitosamente');
    } catch (e) {
      if (mounted) context.showSnackBar('Error cargando imagen: $e', isError: true);
      setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickDate() async {
    final initialDate = eventDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => eventDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final initialTime = startTime ?? const TimeOfDay(hour: 18, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      setState(() => startTime = picked);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (eventDate == null || startTime == null) {
      context.showSnackBar('Selecciona fecha y hora', isError: true);
      return;
    }

    final dt = DateTime(
      eventDate!.year,
      eventDate!.month,
      eventDate!.day,
      startTime!.hour,
      startTime!.minute,
    ).toUtc();

    try {
      // Actualizar evento
      await supabase.from('events').update({
        'name': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'image_url': _imageUrl,
        'event_datetime': dt.toIso8601String(),
      }).eq('id', widget.eventId);

      // Actualizar categorías del evento
      // Primero eliminar las existentes
      await supabase.from('event_interests').delete().eq('event_id', widget.eventId);

      // Luego insertar las nuevas
      if (_selectedCategoryIds.isNotEmpty) {
        final inserts = _selectedCategoryIds.map((catId) => {
          'event_id': widget.eventId,
          'interest_id': catId,
        }).toList();

        await supabase.from('event_interests').insert(inserts);
      }

      if (mounted) {
        context.showSnackBar('Evento actualizado');
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      if (mounted) context.showSnackBar('Error: ${e.message}', isError: true);
    }
  }

  Future<void> _deleteEvent() async {
    try {
      await supabase.from('events').delete().eq('id', widget.eventId);
      if (mounted) {
        context.showSnackBar('Evento eliminado');
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      if (mounted) context.showSnackBar('Error: ${e.message}', isError: true);
    }
  }

  Future<void> _cancelEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar evento'),
        content: const Text('¿Estás seguro de que deseas cancelar este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('events').update({
        'status': 'cancelled',
      }).eq('id', widget.eventId);
      if (mounted) {
        context.showSnackBar('Evento cancelado');
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      if (mounted) context.showSnackBar('Error: ${e.message}', isError: true);
    }
  }

  String _formatLongDate(DateTime d) {
    const days = ['Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo'];
    const months = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
    return '${days[(d.weekday - 1) % 7]}, ${d.day} de ${months[d.month - 1]} de ${d.year}';
  }

  Scaffold _buildLoadingSkeleton() {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Evento')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeletons.box(height: 180, radius: 14),
            const SizedBox(height: 16),
            Skeletons.form(fields: 6, fieldHeight: 52, spacing: 16),
            const SizedBox(height: 18),
            Skeletons.box(width: 220, height: 44, radius: 12),
            const SizedBox(height: 18),
            Skeletons.chips(count: 6, width: 100, height: 34),
            const SizedBox(height: 24),
            Skeletons.box(height: 50, radius: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingSkeleton();
    }

    final longDate = eventDate != null ? _formatLongDate(eventDate!) : '';
    String formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Evento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Vista previa del evento
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      _imageUrl != null && _imageUrl!.isNotEmpty
                          ? Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 180,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 180,
                                color: Theme.of(context).colorScheme.skeletonBackground,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            )
                          : Container(
                              height: 180,
                              color: Theme.of(context).colorScheme.skeletonBackground,
                              alignment: Alignment.center,
                              child: const Icon(Icons.image, size: 48),
                            ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: FloatingActionButton.small(
                          onPressed: _uploadingImage ? null : _pickImage,
                          backgroundColor: Colors.blue,
                          child: _uploadingImage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.edit),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleController.text.isNotEmpty ? titleController.text : 'Titulo del evento',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(longDate),
                        ]),
                        const SizedBox(height: 6),
                        if (startTime != null)
                          Row(children: [
                            const Icon(Icons.access_time, size: 20),
                            const SizedBox(width: 8),
                            Text(formatTime(startTime!)),
                          ]),
                        const SizedBox(height: 10),
                        Text(
                          descriptionController.text.isNotEmpty
                              ? descriptionController.text
                              : 'Descripcion del evento',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Formulario de edición
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Titulo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'El titulo es obligatorio' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripcion',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'La descripcion es obligatoria' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  // Fecha
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(eventDate != null ? _formatLongDate(eventDate!) : 'Selecciona fecha'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Hora
                  OutlinedButton.icon(
                    onPressed: _pickStartTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(startTime != null ? 'Hora: ${startTime!.format(context)}' : 'Selecciona hora'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Categorías
                  Text(
                    'Categorías (máximo 3)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _loadingCategories
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Skeletons.chips(count: 6, width: 110, height: 34),
                        )
                      : Wrap(
                          spacing: 8,
                          children: _allCategories.map((category) {
                            final isSelected = _selectedCategoryIds.contains(category['id']);
                            return FilterChip(
                              label: Text(category['name'] as String),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected && _selectedCategoryIds.length < 3) {
                                    _selectedCategoryIds.add(category['id']);
                                  } else if (!selected) {
                                    _selectedCategoryIds.remove(category['id']);
                                  } else if (selected && _selectedCategoryIds.length >= 3) {
                                    context.showSnackBar('Máximo 3 categorías permitidas');
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),

                  // Botones de acción
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _cancelEvent,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Colors.orange),
                      ),
                      child: const Text(
                        'Cancelar Evento',
                        style: TextStyle(color: Colors.orange, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _deleteEvent,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Eliminar Evento',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
