import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unieventos/main.dart';

import '../utils/image_crop_helper.dart';

class Avatar extends StatefulWidget {
  const Avatar({super.key, required this.imageUrl, required this.onUpload});

  final String? imageUrl;
  final void Function(String) onUpload;

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Avatar circular
        GestureDetector(
          onTap: (widget.imageUrl ?? '').isEmpty ? null : () => _openViewer(widget.imageUrl!),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: widget.imageUrl == null || widget.imageUrl!.isEmpty
                  ? Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        // Botón de edición en la esquina inferior derecha
        Positioned(
          bottom: 0,
          right: 0,
          child: FloatingActionButton.small(
            onPressed: _isLoading ? null : _upload,
            backgroundColor: Theme.of(context).colorScheme.primary,
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
    final selection = await ImageCropHelper.pickOriginalAndCropped(ratio: 1.0);
    if (selection == null) return;
    final (picked, cropped) = selection;

    setState(() => _isLoading = true);

    try {
      final originalBytes = await ImageCropHelper.compressToMaxBytes(await picked.readAsBytes());
      final croppedBytes = await ImageCropHelper.compressToMaxBytes(await cropped.readAsBytes());

      final user = supabase.auth.currentUser;
      final userPrefix = user != null ? '${user.id}/' : '';
      final timestamp = DateTime.now().toIso8601String();
      final contentType = picked.mimeType ?? 'image/jpeg';

      // 1) Subir original
      final originalPath = '${userPrefix}originals/avatar_$timestamp.jpg';
      await supabase.storage.from('avatars').uploadBinary(
            originalPath,
            originalBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      // 2) Subir recortada (thumb)
      final thumbPath = '${userPrefix}thumbs/avatar_$timestamp.jpg';
      await supabase.storage.from('avatars').uploadBinary(
            thumbPath,
            croppedBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final thumbUrl = await supabase.storage
          .from('avatars')
          .createSignedUrl(thumbPath, 60 * 60 * 24 * 365 * 10);

      widget.onUpload(thumbUrl);
    } on StorageException catch (error) {
      if (mounted) {
        context.showSnackBar(error.message, isError: true);
      }
    } catch (error) {
      if (mounted) {
        context.showSnackBar('Unexpected error occurred', isError: true);
      }
    }

    setState(() => _isLoading = false);
  }

  void _openViewer(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Hero(
              tag: 'avatar-viewer',
              child: Image.network(
                url,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
