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

  /// Writes bytes to app cache so [OpenFilex] can open via FileProvider.
  /// Prefer this path for opening; use [downloadToDownloadsFolder] to also
  /// keep a public copy in Downloads.
  static Future<String> saveToCacheForOpen({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final safeName = fileName.toLowerCase().endsWith('.pdf')
        ? _sanitizeFileName(fileName)
        : sanitizePdfFileName(fileName);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Captures the visible Flutter WebView on Android and saves a PDF copy.
  static Future<String> captureWebViewPdf({required String fileName}) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('WebView PDF capture is only supported on Android.');
    }
    await _requestPermissions();
    final safeName = _sanitizeFileName(fileName);
    final pdfName =
        safeName.toLowerCase().endsWith('.pdf') ? safeName : '$safeName.pdf';
    final result = await _channel.invokeMethod<String>(
      'captureWebViewPdf',
      <String, dynamic>{'fileName': pdfName},
    );
    if (result == null || result.isEmpty) {
      throw StateError('Native WebView PDF capture returned no path.');
    }
    return result;
  }

  static Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) return;
    try {
      // WRITE_EXTERNAL_STORAGE is only declared up to API 28. On newer Android
      // MediaStore writes do not need this permission; requesting it can log
      // "No permissions found in manifest" and confuse the UX.
      final status = await Permission.storage.status;
      if (status.isDenied) {
        await Permission.storage.request();
      }
    } catch (e) {
      debugPrint('[PurchaseImageDownloadService] storage permission skipped: $e');
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

  static String sanitizePdfFileName(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (cleaned.isEmpty) {
      return 'challan_${DateTime.now().millisecondsSinceEpoch}.pdf';
    }
    return cleaned.toLowerCase().endsWith('.pdf') ? cleaned : '$cleaned.pdf';
  }
}
