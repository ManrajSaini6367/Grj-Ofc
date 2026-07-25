import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/chat_media_viewer_screen.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/chatscreen/theme/chat_theme.dart';
import 'package:grjoffice_apps/chatscreen/utils/chat_formatters.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.senderName,
    this.showSenderName = false,
    this.isFirstInGroup = true,
  });

  final ChatMessage message;
  final bool isMine;
  final String? senderName;
  final bool showSenderName;
  final bool isFirstInGroup;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxBubble = ChatTheme.bubbleMaxWidth(width);
    final gutter = ChatTheme.bubbleSideGutter(width);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 5),
      bottomRight: Radius.circular(isMine ? 5 : 18),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxBubble,
          minWidth: message.hasMedia ? 0 : 84,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: isMine ? gutter : 12,
            right: isMine ? 12 : gutter,
            top: isFirstInGroup ? 8 : 3,
            bottom: 2,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (showSenderName &&
                  senderName != null &&
                  isFirstInGroup &&
                  !isMine)
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 4),
                  child: Text(
                    senderName!,
                    style: GoogleFonts.poppins(
                      color: _senderColor(senderName!),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isMine ? ChatTheme.outgoing : ChatTheme.incoming,
                  borderRadius: radius,
                  border: isMine
                      ? null
                      : Border.all(color: ChatTheme.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: message.hasMedia
                      ? _MediaBubble(message: message, isMine: isMine)
                      : _TextBubble(message: message, isMine: isMine),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _senderColor(String name) {
    const palette = [
      Color(0xFF8B1D1D),
      Color(0xFFB45309),
      Color(0xFF047857),
      Color(0xFF1D4ED8),
      Color(0xFF7C3AED),
      Color(0xFFBE185D),
      Color(0xFF0F766E),
    ];
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              message.text,
              style: GoogleFonts.poppins(
                color: isMine
                    ? ChatTheme.textOnOutgoing
                    : ChatTheme.textPrimary,
                fontSize: 14.5,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _MetaRow(
            sentAt: message.sentAt,
            isMine: isMine,
            status: message.status,
          ),
        ],
      ),
    );
  }
}

class _MediaBubble extends StatelessWidget {
  const _MediaBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mediaW = ChatTheme.mediaWidth(width);
    final mediaH = mediaW * 0.78;
    final hasCaption = message.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: _MediaPreview(
            message: message,
            width: mediaW - 8,
            height: mediaH,
          ),
        ),
        if (hasCaption)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  color: isMine
                      ? ChatTheme.textOnOutgoing
                      : ChatTheme.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(12, hasCaption ? 6 : 5, 10, 8),
          child: _MetaRow(
            sentAt: message.sentAt,
            isMine: isMine,
            status: message.status,
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.sentAt,
    required this.isMine,
    required this.status,
  });

  final DateTime sentAt;
  final bool isMine;
  final MessageDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ChatFormatters.messageTime(sentAt),
          style: GoogleFonts.poppins(
            color: isMine ? ChatTheme.timeOnOutgoing : ChatTheme.timeOnIncoming,
            fontSize: 10.5,
            height: 1,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 4),
          _StatusIcon(status: status),
        ],
      ],
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.message,
    required this.width,
    required this.height,
  });

  final ChatMessage message;
  final double width;
  final double height;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _open(BuildContext context) {
    final path = message.mediaPath;
    if (path == null || path.isEmpty) return;

    final isNetwork =
        path.startsWith('http://') || path.startsWith('https://');
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

  Widget _image(String path, bool isNetwork) {
    if (isNetwork) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _broken(),
      );
    }
    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _broken(),
    );
  }

  Widget _broken() {
    return Container(
      width: width,
      height: height,
      color: AppColors.operationsCardBg,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = message.mediaPath!;
    final isNetwork =
        path.startsWith('http://') || path.startsWith('https://');
    final radius = BorderRadius.circular(14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (message.isVideo)
                  const ColoredBox(color: Color(0xFF1C1C1C))
                else
                  Hero(
                    tag: 'chat-media-${message.id}',
                    child: _image(path, isNetwork),
                  ),
                if (message.isVideo) ...[
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
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
                            Icons.videocam_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            message.mediaDuration != null
                                ? _formatDuration(message.mediaDuration!)
                                : 'Video',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
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
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.4,
            color: ChatTheme.tickSent,
          ),
        );
      case MessageDeliveryStatus.sent:
        return const Icon(Icons.check, size: 14, color: ChatTheme.tickSent);
      case MessageDeliveryStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: ChatTheme.tickSent);
      case MessageDeliveryStatus.read:
        return const Icon(Icons.done_all, size: 14, color: ChatTheme.tickRead);
      case MessageDeliveryStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444));
    }
  }
}
