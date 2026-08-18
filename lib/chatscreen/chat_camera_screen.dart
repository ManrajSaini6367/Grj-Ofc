import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

enum ChatCameraMode { video, photo }

class ChatCameraResult {
  const ChatCameraResult({
    required this.file,
    required this.isVideo,
    this.duration,
  });

  final File file;
  final bool isVideo;
  final Duration? duration;
}

/// WhatsApp-style chat camera: live preview, tap photo, hold video.
class ChatCameraScreen extends StatefulWidget {
  const ChatCameraScreen({
    super.key,
    this.maxVideoDuration = const Duration(minutes: 2),
  });

  final Duration maxVideoDuration;

  @override
  State<ChatCameraScreen> createState() => _ChatCameraScreenState();
}

class _ChatCameraScreenState extends State<ChatCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  bool _initializing = true;
  bool _busy = false;
  bool _switching = false;
  String? _error;
  bool _micGranted = false;
  bool _audioEnabled = false;

  ChatCameraMode _mode = ChatCameraMode.photo;
  FlashMode _flashMode = FlashMode.off;
  bool _recording = false;
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;
  DateTime? _recordStartedAt;

  File? _previewFile;
  bool _previewIsVideo = false;
  Duration? _previewDuration;
  VideoPlayerController? _previewVideo;

  bool get _isVideoMode => _mode == ChatCameraMode.video;

  /// Bumped on every open/flip so a stale init cannot overwrite the live camera.
  int _openGeneration = 0;

  bool get _isPreview => _previewFile != null;
  bool get _ready =>
      !_initializing &&
      !_switching &&
      _error == null &&
      _controller != null &&
      _controller!.value.isInitialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _previewVideo?.dispose();
    final c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isPreview || _switching) return;
    final controller = _controller;

    if (state == AppLifecycleState.inactive) {
      if (_recording) {
        unawaited(_stopRecording(discard: true));
      }
      if (controller != null) {
        _controller = null;
        unawaited(controller.dispose());
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null || !_controller!.value.isInitialized) {
        unawaited(_openCameraAt(_cameraIndex, enableAudio: _micGranted));
      }
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    final camStatus = await Permission.camera.request();
    if (!camStatus.isGranted) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = camStatus.isPermanentlyDenied
            ? 'Camera permission permanently denied. Enable it in Settings.'
            : 'Camera permission is required.';
      });
      return;
    }

    final micStatus = await Permission.microphone.request();
    _micGranted = micStatus.isGranted;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _error = 'No camera found on this device.';
        });
        return;
      }

      _cameras = cameras;
      final backIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      // Open WITH mic when allowed so recording never re-inits (no black flash).
      await _openCameraAt(
        backIndex >= 0 ? backIndex : 0,
        enableAudio: _micGranted,
      );
    } catch (e, st) {
      debugPrint('[ChatCameraScreen] bootstrap error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Could not start camera. Please try again.';
      });
    }
  }

  Future<void> _openCameraAt(int index, {required bool enableAudio}) async {
    if (_cameras.isEmpty) return;
    final safeIndex = index.clamp(0, _cameras.length - 1);
    final generation = ++_openGeneration;

    // 1) Detach preview from the old controller immediately (prevents abandoned Surface).
    final old = _controller;
    if (mounted) {
      setState(() {
        _controller = null;
        _switching = true;
        _initializing = true;
        _error = null;
        _flashMode = FlashMode.off;
      });
    } else {
      _controller = null;
    }

    // 2) Fully release the previous camera before opening the next.
    if (old != null) {
      try {
        await old.dispose();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 280));
    }

    if (!mounted || generation != _openGeneration) return;

    final description = _cameras[safeIndex];
    final controller = CameraController(
      description,
      // Lower preset keeps chat videos smaller for server upload limits.
      ResolutionPreset.low,
      enableAudio: enableAudio,
    );

    try {
      await controller.initialize();
      if (!mounted || generation != _openGeneration) {
        await controller.dispose();
        return;
      }

      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}

      if (!mounted || generation != _openGeneration) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _cameraIndex = safeIndex;
        _audioEnabled = enableAudio;
        _initializing = false;
        _switching = false;
        _error = null;
        _flashMode = FlashMode.off;
      });
    } catch (e, st) {
      debugPrint('[ChatCameraScreen] openCamera error: $e\n$st');
      try {
        await controller.dispose();
      } catch (_) {}

      if (generation != _openGeneration) return;

      if (enableAudio && mounted) {
        await _openCameraAt(safeIndex, enableAudio: false);
        return;
      }

      if (!mounted) return;
      setState(() {
        _initializing = false;
        _switching = false;
        _error = 'Could not start camera. Please try again.';
      });
    }
  }

  Future<void> _releaseCamera() async {
    final old = _controller;
    _controller = null;
    if (old != null) {
      try {
        await old.dispose();
      } catch (_) {}
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _busy || _switching || _isPreview) return;

    if (_recording) {
      await _stopRecording(discard: true);
    }

    final current = _cameras[_cameraIndex];
    final wantFront = current.lensDirection != CameraLensDirection.front;
    var next = _cameras.indexWhere(
      (c) => wantFront
          ? c.lensDirection == CameraLensDirection.front
          : c.lensDirection == CameraLensDirection.back,
    );
    if (next < 0) {
      next = (_cameraIndex + 1) % _cameras.length;
    }

    HapticFeedback.selectionClick();
    await _openCameraAt(next, enableAudio: _micGranted);
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (!_ready ||
        _busy ||
        _recording ||
        controller == null ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() => _busy = true);
    HapticFeedback.mediumImpact();

    try {
      final shot = await controller.takePicture();
      final dir = await getTemporaryDirectory();
      final dest = File(
        '${dir.path}/chat_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(shot.path).copy(dest.path);

      if (!mounted) return;
      setState(() {
        _previewFile = dest;
        _previewIsVideo = false;
        _previewDuration = null;
        _busy = false;
      });
    } catch (e, st) {
      debugPrint('[ChatCameraScreen] photo error: $e\n$st');
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('Failed to capture photo.');
    }
  }

  void _beginRecordingUi() {
    _recordTimer?.cancel();
    _recordStartedAt = DateTime.now();
    _recordElapsed = Duration.zero;
    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final started = _recordStartedAt;
      if (started == null || !mounted) return;
      final elapsed = DateTime.now().difference(started);
      setState(() => _recordElapsed = elapsed);
      if (elapsed >= widget.maxVideoDuration) {
        unawaited(_stopRecording());
      }
    });
    setState(() {
      _recording = true;
      if (!_isVideoMode) _mode = ChatCameraMode.video;
      _recordElapsed = Duration.zero;
    });
  }

  Future<void> _startRecording() async {
    if (_busy || _switching) return;

    if (!_micGranted) {
      final mic = await Permission.microphone.request();
      _micGranted = mic.isGranted;
      if (!_micGranted) {
        _toast('Microphone permission is required for video.');
        return;
      }
      // Only reopen if mic was just granted and camera has no audio.
      if (!_audioEnabled) {
        await _openCameraAt(_cameraIndex, enableAudio: true);
      }
    }

    if (!_recording) _beginRecordingUi();

    final live = _controller;
    if (live == null ||
        !live.value.isInitialized ||
        live.value.isRecordingVideo) {
      _recordTimer?.cancel();
      if (mounted) {
        setState(() {
          _recording = false;
          _recordElapsed = Duration.zero;
        });
      }
      return;
    }

    try {
      // No camera re-init here — preview stays live.
      await live.startVideoRecording();
      HapticFeedback.heavyImpact();
    } catch (e, st) {
      debugPrint('[ChatCameraScreen] start video error: $e\n$st');
      _recordTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _recordElapsed = Duration.zero;
      });
      _toast('Could not start video recording.');
    }
  }

  Future<void> _stopRecording({bool discard = false}) async {
    final controller = _controller;
    _recordTimer?.cancel();
    _recordTimer = null;

    if (controller == null || !controller.value.isRecordingVideo) {
      if (mounted) {
        setState(() {
          _recording = false;
          _recordElapsed = Duration.zero;
        });
      }
      return;
    }

    setState(() => _busy = true);
    final duration = _recordElapsed;

    try {
      final file = await controller.stopVideoRecording();
      HapticFeedback.mediumImpact();

      if (discard) {
        try {
          await File(file.path).delete();
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _recording = false;
          _busy = false;
          _recordElapsed = Duration.zero;
        });
        return;
      }

      final dir = await getTemporaryDirectory();
      final dest = File(
        '${dir.path}/chat_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await File(file.path).copy(dest.path);

      // Release camera before VideoPlayer — avoids Android decoder / channel clashes.
      await _releaseCamera();
      await _loadPreviewVideo(dest);

      if (!mounted) return;
      setState(() {
        _recording = false;
        _busy = false;
        _recordElapsed = Duration.zero;
        _previewFile = dest;
        _previewIsVideo = true;
        _previewDuration = duration;
      });
    } catch (e, st) {
      debugPrint('[ChatCameraScreen] stop video error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _recording = false;
        _busy = false;
        _recordElapsed = Duration.zero;
      });
      _toast('Failed to save video.');
    }
  }

  Future<void> _loadPreviewVideo(File file) async {
    try {
      await _previewVideo?.dispose();
      _previewVideo = null;
      final v = VideoPlayerController.file(
        file,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await v.initialize();
      await v.setLooping(true);
      await v.play();
      _previewVideo = v;
    } catch (e) {
      debugPrint('[ChatCameraScreen] preview video error: $e');
      _previewVideo = null;
    }
  }

  void _onShutterTap() {
    if (_busy || (!_ready && !_recording)) return;
    if (_recording) {
      unawaited(_stopRecording());
      return;
    }
    if (!_ready) return;
    if (_mode == ChatCameraMode.photo) {
      unawaited(_capturePhoto());
    } else {
      unawaited(_startRecording());
    }
  }

  void _onShutterLongPressStart() {
    if (_busy || !_ready || _recording) return;
    _beginRecordingUi();
    unawaited(_startRecording());
  }

  void _onShutterLongPressEnd() {
    if (_recording) unawaited(_stopRecording());
  }

  Future<void> _retake() async {
    await _previewVideo?.dispose();
    _previewVideo = null;
    setState(() {
      _previewFile = null;
      _previewIsVideo = false;
      _previewDuration = null;
    });
    unawaited(_openCameraAt(_cameraIndex, enableAudio: _micGranted));
  }

  void _confirm() {
    final file = _previewFile;
    if (file == null) return;
    Navigator.of(context).pop(
      ChatCameraResult(
        file: file,
        isVideo: _previewIsVideo,
        duration: _previewDuration,
      ),
    );
  }

  void _close() {
    if (_recording) {
      unawaited(_stopRecording(discard: true).then((_) {
        if (mounted) Navigator.of(context).pop();
      }));
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _cycleFlash() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _recording) return;
    final next = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    try {
      await c.setFlashMode(next);
      if (!mounted) return;
      setState(() => _flashMode = next);
    } catch (_) {
      _toast('Flash not available on this camera.');
    }
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.always:
      case FlashMode.torch:
        return Icons.flash_on_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.off:
        return Icons.flash_off_rounded;
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy || _recording) return;
    try {
      final picked = await ImagePicker().pickMedia(
        imageQuality: 92,
      );
      if (picked == null || !mounted) return;
      final path = picked.path;
      final isVideo = path.toLowerCase().endsWith('.mp4') ||
          path.toLowerCase().endsWith('.mov') ||
          path.toLowerCase().endsWith('.webm') ||
          (picked.mimeType?.startsWith('video/') ?? false);

      final dir = await getTemporaryDirectory();
      final ext = isVideo ? 'mp4' : 'jpg';
      final dest = File(
        '${dir.path}/chat_gallery_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await File(path).copy(dest.path);

      if (isVideo) {
        await _releaseCamera();
        await _loadPreviewVideo(dest);
      }

      if (!mounted) return;
      setState(() {
        _previewFile = dest;
        _previewIsVideo = isVideo;
        _previewDuration = null;
      });
    } catch (e) {
      debugPrint('[ChatCameraScreen] gallery error: $e');
      _toast('Could not open gallery.');
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: GoogleFonts.poppins())),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isPreview,
              child: _buildCameraLayer(),
            ),
          ),

          // Top: close · timer · flash  (matches WhatsApp)
          if (!_isPreview)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, topInset + 10, 14, 0),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      _CircleChromeButton(
                        icon: Icons.close,
                        onPressed: _close,
                      ),
                      Expanded(
                        child: Center(
                          child: _recording
                              ? _RecordingTimerBadge(
                                  label: _formatDuration(_recordElapsed),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      _CircleChromeButton(
                        icon: _flashIcon,
                        onPressed: _ready ? () => unawaited(_cycleFlash()) : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isPreview)
            Positioned(
              top: 0,
              left: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, topInset + 10, 14, 0),
                child: _CircleChromeButton(
                  icon: Icons.close,
                  onPressed: _close,
                ),
              ),
            ),

          if (!_isPreview)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildWhatsAppBottom(bottomInset),
            ),
          if (_isPreview)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildPreviewActions(bottomInset),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_isPreview) {
      if (_previewIsVideo) {
        final v = _previewVideo;
        if (v != null && v.value.isInitialized) {
          return ColoredBox(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio:
                    v.value.aspectRatio == 0 ? 9 / 16 : v.value.aspectRatio,
                child: VideoPlayer(v),
              ),
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_rounded, color: Colors.white70, size: 64),
              const SizedBox(height: 12),
              Text(
                'Video ready',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_previewDuration != null) ...[
                const SizedBox(height: 6),
                Text(
                  _formatDuration(_previewDuration!),
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        );
      }
      return InteractiveViewer(
        child: Image.file(
          _previewFile!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    if (_initializing && _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    if (_error != null && _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _error!.contains('Settings')
                    ? openAppSettings
                    : _bootstrap,
                child: Text(
                  _error!.contains('Settings') ? 'Open Settings' : 'Retry',
                  style: GoogleFonts.poppins(color: AppColors.primaryRed),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    return _FullScreenCameraPreview(controller: controller);
  }


  Widget _buildWhatsAppBottom(double bottomInset) {
    const shutterSize = 78.0;
    final progress = widget.maxVideoDuration.inMilliseconds == 0
        ? 0.0
        : (_recordElapsed.inMilliseconds /
                widget.maxVideoDuration.inMilliseconds)
            .clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 10 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_recording)
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white70,
              size: 26,
            ),
          if (!_recording) const SizedBox(height: 6),
          SizedBox(
            height: shutterSize,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: !_recording
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: _CircleChromeButton(
                            icon: Icons.photo_library_outlined,
                            size: 46,
                            iconSize: 22,
                            onPressed: () => unawaited(_pickFromGallery()),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                SizedBox(
                  width: shutterSize,
                  height: shutterSize,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onShutterTap,
                    onLongPressStart: (_) => _onShutterLongPressStart(),
                    onLongPressEnd: (_) => _onShutterLongPressEnd(),
                    onLongPressCancel: _onShutterLongPressEnd,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Container(
                          width: shutterSize,
                          height: shutterSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                        if (_recording)
                          SizedBox(
                            width: shutterSize,
                            height: shutterSize,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFE53935),
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: _recording ? 28 : 62,
                          height: _recording ? 28 : 62,
                          decoration: BoxDecoration(
                            color: _recording
                                ? const Color(0xFFE53935)
                                : (_isVideoMode
                                    ? const Color(0xFFE53935)
                                    : Colors.white),
                            borderRadius:
                                BorderRadius.circular(_recording ? 6 : 31),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: !_recording
                        ? _CircleChromeButton(
                            icon: Icons.cameraswitch_rounded,
                            size: 46,
                            iconSize: 24,
                            onPressed: _cameras.length > 1 &&
                                    !_switching &&
                                    !_busy
                                ? () => unawaited(_flipCamera())
                                : null,
                          )
                        : const SizedBox(width: 46),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!_recording) _buildModeStrip(),
        ],
      ),
    );
  }

  Widget _buildModeStrip() {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ModePill(
            label: 'Video',
            selected: _mode == ChatCameraMode.video,
            onTap: () => setState(() => _mode = ChatCameraMode.video),
          ),
          const SizedBox(width: 10),
          _ModePill(
            label: 'Photo',
            selected: _mode == ChatCameraMode.photo,
            onTap: () => setState(() => _mode = ChatCameraMode.photo),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewActions(double bottomInset) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 16, 8, 12 + bottomInset),
      child: Row(
        children: [
          TextButton(
            onPressed: () => unawaited(_retake()),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: Text(
              'Retake',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _confirm,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: Text(
              'Send',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenCameraPreview extends StatelessWidget {
  const _FullScreenCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final isFront =
        controller.description.lensDirection == CameraLensDirection.front;
    final previewSize = controller.value.previewSize;

    Widget preview = CameraPreview(controller);
    if (isFront) {
      preview = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: preview,
      );
    }

    if (previewSize == null) {
      return preview;
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: preview,
        ),
      ),
    );
  }
}

class _RecordingTimerBadge extends StatelessWidget {
  const _RecordingTimerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xCC1A1A1A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CircleChromeButton extends StatelessWidget {
  const _CircleChromeButton({
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.iconSize = 24,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x66000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: onPressed == null ? Colors.white38 : Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
