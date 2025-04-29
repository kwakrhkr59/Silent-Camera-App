import 'dart:typed_data';
import 'package:flutter/services.dart';

class ImageSaver {
  static const MethodChannel _channel =
      MethodChannel('com.example.myapp/imagesaver');

  static Future<String?> saveImageToGallery(
      Uint8List imageBytes, String fileName) async {
    final result = await _channel.invokeMethod('saveImageToGallery', {
      'bytes': imageBytes,
      'fileName': fileName,
    });
    return result as String?;
  }
}
