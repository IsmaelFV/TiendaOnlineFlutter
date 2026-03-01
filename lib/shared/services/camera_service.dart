import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Servicio para capturar imágenes desde cámara o galería
class CameraService {
  CameraService._();

  static final _picker = ImagePicker();

  /// Mostrar picker con opción de cámara o galería
  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 90,
  }) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: imageQuality,
    );

    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  /// Seleccionar múltiples imágenes de galería
  static Future<List<File>> pickMultipleImages({
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 90,
  }) async {
    final pickedFiles = await _picker.pickMultiImage(
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: imageQuality,
    );

    return pickedFiles.map((xFile) => File(xFile.path)).toList();
  }
}
