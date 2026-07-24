import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WhatsApp-inspired palette for the conversation screen only.
class ChatTheme {
  ChatTheme._();

  static const Color header = Color(0xFF008069);
  static const Color headerDark = Color(0xFF075E54);
  static const Color accent = Color(0xFF25D366);
  static const Color outgoing = Color(0xFFD9FDD3);
  static const Color incoming = Color(0xFFFFFFFF);
  static const Color wallpaper = Color(0xFFECE5DD);
  static const Color wallpaperPattern = Color(0xFFD4CBC0);
  static const Color composerBar = Color(0xFFF0F2F5);
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111B21);
  static const Color textSecondary = Color(0xFF667781);
  static const Color timeMine = Color(0xFF667781);
  static const Color timeTheirs = Color(0xFF667781);
  static const Color tickSent = Color(0xFF8696A0);
  static const Color tickRead = Color(0xFF53BDEB);
  static const Color dateChip = Color(0xFFE2F3FB);
  static const Color dateText = Color(0xFF54656F);
  static const Color systemChip = Color(0xFFE2F7CB);
  static const Color senderName = Color(0xFF06CF9C);
  static const Color iconMuted = Color(0xFF54656F);

  /// Side inset so chat column stays readable on tablets / landscape.
  static double contentSideInset(double width) {
    if (width >= 1100) return (width - 800) / 2;
    if (width >= 900) return (width - 720) / 2;
    if (width >= 700) return 32;
    if (width >= 600) return 16;
    return 0;
  }

  static double bubbleMaxWidth(double width) {
    if (width < 340) return width * 0.9;
    if (width < 400) return width * 0.86;
    if (width >= 900) return 480;
    if (width >= 700) return 440;
    return width * 0.78;
  }

  static double bubbleSideGutter(double width) {
    if (width < 360) return 28;
    if (width >= 700) return 56;
    return 44;
  }

  static double mediaWidth(double width) {
    final maxBubble = bubbleMaxWidth(width);
    return (maxBubble * 0.92).clamp(180.0, 340.0);
  }

  static double composerMinHeight(double width) => width < 360 ? 44.0 : 48.0;

  static double headerHeight(double width) => width < 360 ? 54.0 : 58.0;
}

/// Soft doodle-style wallpaper similar to WhatsApp chat background.
class ChatWallpaperPainter extends CustomPainter {
  const ChatWallpaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ChatTheme.wallpaperPattern.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final step = size.width < 400 ? 30.0 : 36.0;
    final rand = math.Random(42);

    for (double y = 8; y < size.height; y += step) {
      for (double x = 8; x < size.width; x += step) {
        final ox = x + (rand.nextDouble() - 0.5) * 8;
        final oy = y + (rand.nextDouble() - 0.5) * 8;
        final kind = rand.nextInt(5);

        switch (kind) {
          case 0:
            canvas.drawCircle(Offset(ox, oy), 2.0 + rand.nextDouble(), paint);
            break;
          case 1:
            canvas.drawLine(
              Offset(ox - 4, oy),
              Offset(ox + 4, oy - 2),
              paint,
            );
            break;
          case 2:
            final path = Path()
              ..moveTo(ox - 3, oy + 2)
              ..quadraticBezierTo(ox, oy - 4, ox + 4, oy + 1);
            canvas.drawPath(path, paint);
            break;
          case 3:
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(ox, oy),
                width: 4.5,
                height: 4.5,
              ),
              paint,
            );
            break;
          default:
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(ox, oy),
                width: 6.5,
                height: 3.5,
              ),
              paint,
            );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
