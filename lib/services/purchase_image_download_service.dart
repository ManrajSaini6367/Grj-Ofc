import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Saves purchase images to the device public Downloads folder.
class PurchaseImageDownloadService {
  PurchaseImageDownloadService._();

  static const _channel = MethodChannel('grjoffice_apps/downloads');

  static Future<String> downloadToDownloadsFolder({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await _requestPermissions();
    final safeName = _sanitizeFileName(fileName);
    return _saveBytes(bytes, safeName);
  }

  static Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;
    // Needed only on older Android versions for public Downloads writes.
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }

  static Future<String> _saveBytes(Uint8List bytes, String fileName) async {
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<String>(
          'saveToDownloads',
          <String, dynamic>{
            'bytes': bytes,
            'fileName': fileName,
          },
        );
        if (result != null && result.isNotEmpty) return result;
      } catch (e) {
        debugPrint('[PurchaseImageDownloadService] MediaStore save failed: $e');
      }

      // Fallback for older devices / OEM quirks.
      final dir = Directory('/storage/emulated/0/Download/GRJ_Purchases');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/GRJ_Purchases');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _sanitizeFileName(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (cleaned.isEmpty) {
      return 'purchase_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    if (!cleaned.contains('.')) return '$cleaned.jpg';
    return cleaned;
  }
}
