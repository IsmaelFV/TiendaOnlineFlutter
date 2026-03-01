import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../config/constants/environment.dart';

/// Servicio de compresión de imágenes antes de subir a Supabase Storage
class ImageCompressService {
  ImageCompressService._();

  /// Comprime una imagen desde su ruta de archivo.
  /// Retorna los bytes comprimidos o null si falla.
  static Future<Uint8List?> compressFromPath(String filePath) async {
    final result = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: AppConstants.imageMaxWidth,
      minHeight: AppConstants.imageMaxHeight,
      quality: AppConstants.imageQuality,
      format: CompressFormat.jpeg,
    );
    return result;
  }

  /// Comprime una imagen desde bytes en memoria.
  static Future<Uint8List> compressFromBytes(Uint8List bytes) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: AppConstants.imageMaxWidth,
      minHeight: AppConstants.imageMaxHeight,
      quality: AppConstants.imageQuality,
      format: CompressFormat.jpeg,
    );
    return result;
  }
}
