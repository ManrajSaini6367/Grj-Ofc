import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:video_player/video_player.dart';

/// Full-screen media viewer for chat photos and videos.
class ChatMediaViewerScreen extends StatefulWidget {
  const ChatMediaViewerScreen({
    super.key,
    required this.path,
    required this.isVideo,
    this.heroTag,
  });

  final String path;
  final bool isVideo;
  final String? heroTag;

  @override
  State<ChatMediaViewerScreen> createState() => _ChatMediaViewerScreenState();
}

class _ChatMediaViewerScreenState extends State<ChatMediaViewerScreen> {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _failed = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      // Wait a frame so the route is fully mounted before creating the player.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_initVideo());
      });
    } else {
      _ready = true;
    }
  }

  Future<void> _initVideo() async {
    try {
      final file = File(widget.path);
      if (!await file.exists()) {
        if (!mounted) return;
        setState(() {
          _failed = true;
          _ready = true;
        });
        return;
      }

      // Prefer URI on Android — more reliable with Media3 / pigeon channel.
      final controller = VideoPlayerController.file(
        file,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      _video = controller;
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onVideoTick);
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) return;
      setState(() {
        _ready = true;
        _failed = false;
      });
    } catch (e, st) {
      debugPrint('[ChatMediaViewer] video error: $e\n$st');
      try {
        await _video?.dispose();
      } catch (_) {}
      _video = null;
      if (!mounted) return;
      setState(() {
        _failed = true;
        _ready = true;
      });
    }
  }

  void _onVideoTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final v = _video;
    v?.removeListener(_onVideoTick);
    v?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    if (v.value.isPlaying) {
      v.pause();
    } else {
      v.play();
    }
    setState(() => _showControls = true);
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: widget.isVideo ? _toggleControls : null,
            child: Center(child: _buildBody()),
          ),
          if (_showControls || !widget.isVideo)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_ready) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    if (widget.isVideo) {
      if (_failed || _video == null || !_video!.value.isInitialized) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not play this video.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _ready = false;
                    _failed = false;
                  });
                  unawaited(_initVideo());
                },
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(color: AppColors.primaryRed),
                ),
              ),
            ],
          ),
        );
      }

      final v = _video!;
      final position = v.value.position;
      final duration = v.value.duration;

      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio:
                v.value.aspectRatio == 0 ? 16 / 9 : v.value.aspectRatio,
            child: VideoPlayer(v),
          ),
          if (_showControls) ...[
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  v.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VideoProgressIndicator(
                    v,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.primaryRed,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _format(position),
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _format(duration),
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    final image = Image.file(
      File(widget.path),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        'Could not open this photo.',
        style: GoogleFonts.poppins(color: Colors.white70),
      ),
    );

    if (widget.heroTag != null) {
      return Hero(
        tag: widget.heroTag!,
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: image,
        ),
      );
    }
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: image,
    );
  }
}
