import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.user,
    this.radius = 24,
    this.showOnlineDot = false,
    this.isGroup = false,
    this.groupLabel,
    this.groupColor,
    this.groupIcon,
  });

  final ChatUser? user;
  final double radius;
  final bool showOnlineDot;
  final bool isGroup;
  final String? groupLabel;
  final Color? groupColor;
  final IconData? groupIcon;

  @override
  Widget build(BuildContext context) {
    final label = isGroup
        ? (groupLabel?.trim().isNotEmpty == true
            ? groupLabel!.trim()[0].toUpperCase()
            : 'G')
        : (user?.initials ?? '?');

    final bg = isGroup
        ? (groupColor ?? AppColors.primaryRed).withValues(alpha: 0.15)
        : AppColors.primaryRed.withValues(alpha: 0.12);

    final fg = isGroup ? (groupColor ?? AppColors.primaryRed) : AppColors.primaryRed;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          child: isGroup
              ? Icon(
                  groupIcon ?? Icons.groups_rounded,
                  color: fg,
                  size: radius,
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: fg,
                    fontSize: radius * 0.72,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        if (showOnlineDot && user?.isOnline == true)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.42,
              height: radius * 0.42,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardWhite, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class GroupProfileAvatar extends StatelessWidget {
  const GroupProfileAvatar({
    super.key,
    required this.label,
    this.color,
    this.radius = 48,
    this.onTap,
    this.showCamera = false,
  });

  final String label;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final bool showCamera;

  @override
  Widget build(BuildContext context) {
    final bg = (color ?? AppColors.primaryRed).withValues(alpha: 0.15);
    final fg = color ?? AppColors.primaryRed;
    final initial = label.trim().isNotEmpty ? label.trim()[0].toUpperCase() : 'G';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: bg,
            child: Text(
              initial,
              style: GoogleFonts.poppins(
                color: fg,
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showCamera)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardWhite, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
