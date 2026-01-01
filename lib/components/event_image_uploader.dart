import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unieventos/main.dart';
import '../theme/app_theme_extensions.dart';

class EventImageUploader extends StatefulWidget {
  const EventImageUploader({
    super.key,
    this.imageUrl,
    required this.onUpload,
    this.width = 300,
    this.height = 200,
  });

  final String? imageUrl;
  final void Function(String) onUpload;
  final double width;
  final double height;

  @override
  State<EventImageUploader> createState() => _EventImageUploaderState();
}

class _EventImageUploaderState extends State<EventImageUploader> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Imagen o placeholder
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: widget.width == 300 ? double.infinity : widget.width,
            height: widget.height,
            color: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                ? Colors.transparent
                : Theme.of(context).colorScheme.skeletonBackground,
            child: widget.imageUrl == null || widget.imageUrl!.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Añadir imagen del evento',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context).colorScheme.skeletonBackground,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ),
        // Botón de edición en esquina inferior derecha
        Positioned(
          bottom: 8,
          right: 8,
          child: FloatingActionButton.small(
            onPressed: _isLoading ? null : _upload,
            backgroundColor: Colors.blue,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.edit, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<void> _upload() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final user = supabase.auth.currentUser;
      final path = user != null ? '${user.id}/$fileName' : fileName;

      await supabase.storage.from('event-images').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: imageFile.mimeType, upsert: true),
      );

      final imageUrlResponse = await supabase.storage
          .from('event-images')
          .createSignedUrl(path, 60 * 60 * 24 * 365 * 10);

      widget.onUpload(imageUrlResponse);
    } on StorageException catch (error) {
      if (mounted) {
        context.showSnackBar(error.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        context.showSnackBar('Ocurrió un error inesperado', isError: true);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }
}
