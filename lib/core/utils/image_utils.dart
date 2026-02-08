import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  static Future<String?> convertFileToBase64(File file) async {
    try {
      final Uint8List? result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 50,
      );

      if (result == null) return null;

      return base64Encode(result);
    } catch (e) {
      debugPrint("Image Encoding Error: $e");
      return null;
    }
  }

  static bool isValidBase64(String? value) {
    return value != null && value.isNotEmpty && value.length > 100;
  }
}
