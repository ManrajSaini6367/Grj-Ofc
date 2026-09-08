import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

class PurchaseMultiImagePicker extends StatelessWidget {
  const PurchaseMultiImagePicker({
    super.key,
    required this.label,
    required this.files,
    required this.onAdd,
    required this.onRemoveAt,
    this.required = true,
    this.emptyActionLabel = 'Take Photo',
    this.emptyHint = 'No file selected.',
  });

  static const _addGreen = Color(0xFF22C55E);

  final String label;
  final List<File> files;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;
  final bool required;
  final String emptyActionLabel;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        required
            ? RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  children: [
                    TextSpan(text: '$label '),
                    const TextSpan(
                      text: '*',
                      style: TextStyle(color: AppColors.primaryRed),
                    ),
                  ],
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
        const SizedBox(height: 8),
        if (files.isEmpty)
          _emptyPicker()
        else ...[
          for (var i = 0; i < files.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _selectedRow(files[i], i),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add More',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _addGreen,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.operationsCardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              backgroundColor: const Color(0xFFE5E7EB),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              emptyActionLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              emptyHint,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedRow(File file, int index) {
    final name = file.path.split(Platform.pathSeparator).last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.operationsCardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              file,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: const Color(0xFFE5E7EB),
                child: const Icon(
                  Icons.image_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name.isEmpty ? 'Photo ${index + 1}' : name,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => onRemoveAt(index),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
