import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

/// Popup site selection dialog matching the existing list UI style.
class SiteSelectionDialog extends StatelessWidget {
  const SiteSelectionDialog({
    super.key,
    required this.sites,
    required this.selectedSite,
  });

  final List<String> sites;
  final String selectedSite;

  static Future<String?> show(
    BuildContext context, {
    required List<String> sites,
    required String selectedSite,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => SiteSelectionDialog(
        sites: sites,
        selectedSite: selectedSite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width < 360 ? width * 0.92 : width < 600 ? 340.0 : 380.0;

    return Dialog(
      backgroundColor: AppColors.cardWhite,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Site',
                      style: GoogleFonts.poppins(
                        color: AppColors.headingBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderGray),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: sites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final site = sites[index];
                  final isSelected = site == selectedSite;
                  return Material(
                    color: isSelected ? AppColors.selectionBlue : Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(site),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                site,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? AppColors.white : AppColors.textDark,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_rounded, color: AppColors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
