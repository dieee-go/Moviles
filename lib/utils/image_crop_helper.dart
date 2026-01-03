import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Utilidad para seleccionar y recortar imágenes (compatible con web y mobile)
class ImageCropHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Abre la galería, permite seleccionar y recortar 1:1 (avatar). Devuelve bytes de la imagen recortada.
  static Future<Uint8List?> pickAndCropAvatarBytes() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    final cropped = await _cropXFile(picked, ratio: 1.0);
    return cropped?.readAsBytes();
  }

  /// Abre la galería, permite seleccionar y recortar 5:4 (evento). Devuelve bytes de la imagen recortada.
  static Future<Uint8List?> pickAndCropEventBytes() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    final cropped = await _cropXFile(picked, ratio: 5.0 / 4.0);
    return cropped?.readAsBytes();
  }

  /// Recorta un archivo existente (XFile) y retorna el CroppedFile
  static Future<CroppedFile?> cropXFile({required XFile file, required double ratio}) {
    return _cropXFile(file, ratio: ratio);
  }

  /// Selecciona y recorta devolviendo el XFile original y el CroppedFile (para subir original + thumb)
  static Future<(XFile, CroppedFile)?> pickOriginalAndCropped({required double ratio}) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    final cropped = await _cropXFile(picked, ratio: ratio);
    if (cropped == null) return null;
    return (picked, cropped);
  }

  /// Comprime la imagen (JPEG) hasta que esté bajo el límite indicado.
  /// Si no puede decodificar, devuelve los bytes originales.
  static Future<Uint8List> compressToMaxBytes(
    Uint8List bytes, {
    int maxBytes = 5 * 1024 * 1024,
    int minQuality = 50,
  }) async {
    if (bytes.lengthInBytes <= maxBytes) return bytes;

    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      var quality = 90;
      Uint8List current = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
      while (current.lengthInBytes > maxBytes && quality > minQuality) {
        quality = (quality - 10).clamp(minQuality, 100);
        current = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
      }
      return current;
    } catch (_) {
      return bytes;
    }
  }

  static Future<CroppedFile?> _cropXFile(XFile file, {required double ratio}) {
    return ImageCropper().cropImage(
      sourcePath: file.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      aspectRatio: CropAspectRatio(ratioX: ratio, ratioY: 1.0),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar imagen',
          toolbarColor: const Color(0xFF1976D2),
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Recortar imagen',
          aspectRatioLockDimensionSwapEnabled: true,
        ),
      ],
    );
  }
}
