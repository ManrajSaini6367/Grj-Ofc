import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

/// Conversation UI tokens — aligned with GRJ Office brand.
class ChatTheme {
  ChatTheme._();

  static const Color header = AppColors.cardWhite;
  static const Color accent = AppColors.primaryRed;
  static const Color outgoing = Color(0xFF8B1D1D);
  static const Color outgoingSoft = Color(0xFFF6EAEA);
  static const Color incoming = Color(0xFFFFFFFF);
  static const Color wallpaper = Color(0xFFF4F5F7);
  static const Color composerBar = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFF3F4F6);
  static const Color textOnOutgoing = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color timeOnOutgoing = Color(0xFFECDADA);
  static const Color timeOnIncoming = Color(0xFF9CA3AF);
  static const Color tickSent = Color(0xFFD4BABA);
  static const Color tickRead = Color(0xFF93C5FD);
  static const Color dateChip = Color(0xFFE8EAED);
  static const Color dateText = Color(0xFF6B7280);
  static const Color systemChip = Color(0xFFE8EAED);
  static const Color iconMuted = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  static double contentSideInset(double width) {
    if (width >= 1100) return (width - 780) / 2;
    if (width >= 900) return (width - 700) / 2;
    if (width >= 700) return 36;
    if (width >= 600) return 20;
    return 0;
  }

  static double bubbleMaxWidth(double width) {
    if (width < 340) return width * 0.88;
    if (width < 400) return width * 0.84;
    if (width >= 900) return 460;
    if (width >= 700) return 420;
    return width * 0.76;
  }

  static double bubbleSideGutter(double width) {
    if (width < 360) return 24;
    if (width >= 700) return 64;
    return 48;
  }

  static double mediaWidth(double width) {
    return (bubbleMaxWidth(width) * 0.92).clamp(176.0, 320.0);
  }

  static double composerMinHeight(double width) => width < 360 ? 46.0 : 50.0;

  static double headerHeight(double width) => width < 360 ? 56.0 : 60.0;
}
