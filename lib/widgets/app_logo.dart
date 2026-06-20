import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

/// Official app logo — file: [assetPath]
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 38,
    this.circular = true,
    this.showBorder = false,
  });

  static const assetPath = 'assets/images/grj_logo.png';

  final double size;
  final bool circular;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (size * pixelRatio).round();

    Widget logo = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      cacheWidth: cacheSize,
      cacheHeight: cacheSize,
      errorBuilder: (_, __, ___) => _fallback(),
    );

    if (circular) {
      logo = ClipOval(child: logo);
    }

    if (showBorder) {
      logo = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: logo,
      );
    }

    return SizedBox(width: size, height: size, child: logo);
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryRed, width: 2),
        color: AppColors.cardWhite,
      ),
      child: Center(
        child: Text(
          'GRJ',
          style: GoogleFonts.poppins(
            color: AppColors.primaryRed,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
