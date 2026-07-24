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
      topLeft: Radius.circular(isMine ? 10 : (isFirstInGroup ? 0 : 10)),
      topRight: Radius.circular(isMine ? (isFirstInGroup ? 0 : 10) : 10),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxBubble,
          minWidth: message.hasMedia ? 0 : 80,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: isMine ? gutter : 6,
            right: isMine ? 6 : gutter,
            top: isFirstInGroup ? 6 : 2,
            bottom: 1.5,
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
                  padding: const EdgeInsets.only(left: 8, bottom: 3),
                  child: Text(
                    senderName!,
                    style: GoogleFonts.roboto(
                      color: _senderColor(senderName!),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Material(
                color: isMine ? ChatTheme.outgoing : ChatTheme.incoming,
                elevation: 0.6,
                shadowColor: Colors.black26,
                borderRadius: radius,
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
      Color(0xFF06CF9C),
      Color(0xFF02A698),
      Color(0xFF53BDEB),
      Color(0xFFFFBC38),
      Color(0xFFFF7A7A),
      Color(0xFFC38FFF),
      Color(0xFF7D9CFF),
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
      padding: const EdgeInsets.fromLTRB(11, 8, 10, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              message.text,
              style: GoogleFonts.roboto(
                color: ChatTheme.textPrimary,
                fontSize: 15.5,
                height: 1.38,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
          child: _MediaPreview(
            message: message,
            width: mediaW - 6,
            height: mediaH,
          ),
        ),
        if (message.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 9, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.text,
                style: GoogleFonts.roboto(
                  color: ChatTheme.textPrimary,
                  fontSize: 15,
                  height: 1.32,
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            message.text.trim().isNotEmpty ? 5 : 4,
            8,
            6,
          ),
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
          style: GoogleFonts.roboto(
            color: ChatTheme.timeMine,
            fontSize: 11,
            height: 1,
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 3),
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
            style: GoogleFonts.roboto(),
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
    final radius = BorderRadius.circular(6);

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
                      size: 58,
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            message.mediaDuration != null
                                ? _formatDuration(message.mediaDuration!)
                                : 'Video',
                            style: GoogleFonts.roboto(
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
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
          child: Padding(
            padding: EdgeInsets.all(1),
            child: CircularProgressIndicator(
              strokeWidth: 1.4,
              color: ChatTheme.tickSent,
            ),
          ),
        );
      case MessageDeliveryStatus.sent:
        return const Icon(Icons.check, size: 15, color: ChatTheme.tickSent);
      case MessageDeliveryStatus.delivered:
        return const Icon(Icons.done_all, size: 15, color: ChatTheme.tickSent);
      case MessageDeliveryStatus.read:
        return const Icon(Icons.done_all, size: 15, color: ChatTheme.tickRead);
    }
  }
}
