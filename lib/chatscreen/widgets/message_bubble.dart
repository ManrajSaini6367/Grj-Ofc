import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/chat_media_viewer_screen.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/chatscreen/utils/chat_formatters.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.senderName,
    this.showSenderName = false,
  });

  final ChatMessage message;
  final bool isMine;
  final String? senderName;
  final bool showSenderName;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSenderName && senderName != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 4),
                child: Text(
                  senderName!,
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: message.hasMedia
                  ? const EdgeInsets.fromLTRB(4, 4, 4, 6)
                  : const EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: BoxDecoration(
                color: isMine
                    ? AppColors.primaryRed.withValues(alpha: 0.12)
                    : AppColors.cardWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                border: Border.all(
                  color: isMine
                      ? AppColors.primaryRed.withValues(alpha: 0.18)
                      : AppColors.borderGray.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.hasMedia)
                    _MediaPreview(message: message)
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        message.text,
                        style: GoogleFonts.poppins(
                          color: AppColors.headingBlack,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(
                      right: message.hasMedia ? 6 : 0,
                      left: message.hasMedia ? 6 : 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ChatFormatters.messageTime(message.sentAt),
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          _StatusIcon(status: message.status),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.message});

  final ChatMessage message;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _open(BuildContext context) {
    final path = message.mediaPath;
    if (path == null || path.isEmpty) return;

    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (!isNetwork && !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Media file is no longer available.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ChatMediaViewerScreen(
          path: path,
          isVideo: message.isVideo,
          heroTag: message.isVideo ? null : 'chat-media-${message.id}',
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = message.mediaPath!;
    final radius = BorderRadius.circular(12);
    final heroTag = 'chat-media-${message.id}';
    final isNetwork =
        path.startsWith('http://') || path.startsWith('https://');

    if (message.isVideo) {
      // No VideoPlayer in the list — avoids Android pigeon channel conflicts.
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: Container(
              width: double.infinity,
              height: 220,
              color: const Color(0xFF1A1A1A),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            message.mediaDuration != null
                                ? _formatDuration(message.mediaDuration!)
                                : 'Video',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: radius,
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: radius,
            child: isNetwork
                ? Image.network(
                    path,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: AppColors.operationsCardBg,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  )
                : Image.file(
                    File(path),
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: AppColors.operationsCardBg,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final MessageDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.textSecondary,
          ),
        );
      case MessageDeliveryStatus.sent:
        return const Icon(
          Icons.check,
          size: 14,
          color: AppColors.textSecondary,
        );
      case MessageDeliveryStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: AppColors.textSecondary,
        );
      case MessageDeliveryStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: AppColors.selectionBlue,
        );
    }
  }
}
