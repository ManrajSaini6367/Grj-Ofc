import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:image_picker/image_picker.dart';

/// Safe image pick for Android — avoid opening camera then gallery in a row
/// (that often kills the Flutter activity → "Lost connection to device").
Future<XFile?> pickPurchaseImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
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
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryRed),
                title: Text('Take Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryRed),
                title: Text('Choose from Gallery', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    },
  );

  if (source == null) return null;

  try {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 75,
      requestFullMetadata: false,
    );
  } catch (e) {
    debugPrint('[pickPurchaseImage] error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open camera/gallery. Please try again.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
    return null;
  }
}
