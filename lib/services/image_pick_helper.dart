import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/services/in_app_camera_screen.dart';
import 'package:image_picker/image_picker.dart';

const _maxImageBytes = 4 * 1024 * 1024; // 4 MB

enum _PickChoice { camera, gallery }

/// Safe image pick for purchase / KYC flows.
/// Camera uses in-app preview (avoids Android killing the Flutter process).
///
/// [fromCamera] `true` = camera, `false` = gallery, `null` = ask via sheet.
Future<File?> pickPurchaseImageFile(
  BuildContext context, {
  String? title,
  bool documentGuide = false,
  bool? fromCamera,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(const Duration(milliseconds: 80));
  if (!context.mounted) return null;

  _PickChoice? choice;
  if (fromCamera == true) {
    choice = _PickChoice.camera;
  } else if (fromCamera == false) {
    choice = _PickChoice.gallery;
  } else {
    choice = await showModalBottomSheet<_PickChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.headingBlack,
                      ),
                    ),
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primaryRed,
                  ),
                  title: Text(
                    'Take Photo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(context, _PickChoice.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primaryRed,
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(context, _PickChoice.gallery),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  if (choice == null || !context.mounted) return null;
  await Future<void>.delayed(const Duration(milliseconds: 150));
  if (!context.mounted) return null;

  if (choice == _PickChoice.camera) {
    return _openInAppCamera(
      context,
      title: title ?? 'Take Photo',
      documentGuide: documentGuide,
    );
  }
  return _pickFromGallery(context);
}

Future<File?> _openInAppCamera(
  BuildContext context, {
  String title = 'Take Photo',
  bool documentGuide = false,
}) async {
  try {
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (_) => InAppCameraScreen(
          title: title,
          showDocumentGuide: documentGuide,
        ),
        fullscreenDialog: true,
      ),
    );
    if (file == null) return null;
    return await _stabilizeFile(file);
  } catch (e, stack) {
    debugPrint('[pickPurchaseImageFile] camera error: $e');
    debugPrint('[pickPurchaseImageFile] stack: $stack');
    if (context.mounted) {
      _showPickError(context, 'Could not open camera. Please try again.');
    }
    return null;
  }
}

Future<File?> _pickFromGallery(BuildContext context) async {
  try {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 65,
      requestFullMetadata: false,
    );
    if (xfile == null) return null;
    return await _stabilizePickedFile(xfile);
  } catch (e, stack) {
    debugPrint('[pickPurchaseImageFile] gallery error: $e');
    debugPrint('[pickPurchaseImageFile] stack: $stack');
    if (context.mounted) {
      _showPickError(context, 'Could not open gallery. Please try again.');
    }
    return null;
  }
}

void _showPickError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message, style: GoogleFonts.poppins())),
  );
}

/// Recover image if Android killed the activity while an external picker was open.
Future<File?> recoverLostPurchaseImage() async {
  try {
    final response = await ImagePicker().retrieveLostData();
    if (response.isEmpty || response.file == null) return null;
    return await _stabilizePickedFile(response.file!);
  } catch (e) {
    debugPrint('[recoverLostPurchaseImage] error: $e');
    return null;
  }
}

Future<File?> _stabilizePickedFile(XFile xfile) async {
  return _stabilizeFile(File(xfile.path));
}

Future<File?> _stabilizeFile(File src) async {
  if (!await src.exists()) {
    debugPrint('[pickPurchaseImageFile] source missing: ${src.path}');
    return null;
  }

  final size = await src.length();
  if (size <= 0) return null;

  if (size <= _maxImageBytes) return src;

  debugPrint('[pickPurchaseImageFile] image too large: $size bytes');
  return null;
}

/// Backward-compatible helper returning [XFile].
Future<XFile?> pickPurchaseImage(BuildContext context) async {
  final file = await pickPurchaseImageFile(context);
  if (file == null) return null;
  return XFile(file.path);
}
