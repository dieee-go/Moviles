import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prueba1/main.dart';

class EventImageUploader extends StatefulWidget {
  const EventImageUploader({
    super.key,
    this.imageUrl,
    required this.onUpload,
    this.width = 150,
    this.height = 150,
    this.buttonLabel = 'Subir imagen',
  });

  final String? imageUrl;
  final void Function(String) onUpload;
  final double width;
  final double height;
  final String buttonLabel;

  @override
  State<EventImageUploader> createState() => _EventImageUploaderState();
}

class _EventImageUploaderState extends State<EventImageUploader> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.imageUrl == null || widget.imageUrl!.isEmpty)
              Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.event, color: Colors.grey),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.imageUrl!,
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _upload,
              icon: const Icon(Icons.image_outlined),
              label: Text(widget.buttonLabel),
            ),
          ],
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
