import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// In-app camera with capture → preview → OK / Cancel flow.
/// Uses a full-screen preview so documents stay large and easy to align.
class InAppCameraScreen extends StatefulWidget {
  const InAppCameraScreen({
    super.key,
    this.title = 'Take Photo',
    this.showDocumentGuide = false,
  });

  final String title;
  final bool showDocumentGuide;

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;
  String? _error;
  File? _previewFile;

  bool get _isPreview => _previewFile != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isPreview) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = status.isPermanentlyDenied
            ? 'Camera permission permanently denied. Enable it in Settings.'
            : 'Camera permission is required to take a photo.';
      });
      return;
    }

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

      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        rear,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      debugPrint('[InAppCameraScreen] init error: $e');
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Could not start camera. Please try again.';
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() => _capturing = true);

    try {
      final shot = await controller.takePicture();
      final dir = await getTemporaryDirectory();
      final dest = File(
        '${dir.path}/kyc_cam_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(shot.path).copy(dest.path);

      if (!mounted) return;
      setState(() {
        _previewFile = dest;
        _capturing = false;
      });
    } catch (e) {
      debugPrint('[InAppCameraScreen] capture error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to capture photo. Please try again.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      setState(() => _capturing = false);
    }
  }

  void _onCancel() {
    if (_isPreview) {
      setState(() => _previewFile = null);
      return;
    }
    Navigator.of(context).pop();
  }

  void _onOk() {
    final file = _previewFile;
    if (file == null) return;
    Navigator.of(context).pop(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBody(),
          if (!_isPreview &&
              !_initializing &&
              _error == null &&
              widget.showDocumentGuide)
            _DocumentGuideOverlay(label: widget.title),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _isPreview
                      ? _buildPreviewActions()
                      : _buildCaptureActions(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 26),
          ),
          Expanded(
            child: Text(
              _isPreview ? 'Preview — ${widget.title}' : widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureActions() {
    final canCapture =
        !_initializing && _error == null && !_capturing && _controller != null;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: canCapture ? _capture : null,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
              color: _capturing
                  ? AppColors.textSecondary
                  : AppColors.primaryRed,
            ),
            child: _capturing
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt, color: AppColors.white, size: 30),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(child: SizedBox(height: 48)),
      ],
    );
  }

  Widget _buildPreviewActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retake',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _onOk,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Use Photo',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isPreview) {
      return ColoredBox(
        color: Colors.black,
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.file(
              _previewFile!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      );
    }

    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (_error!.contains('Settings'))
                TextButton(
                  onPressed: openAppSettings,
                  child: Text(
                    'Open Settings',
                    style: GoogleFonts.poppins(color: AppColors.primaryRed),
                  ),
                )
              else
                TextButton(
                  onPressed: _initCamera,
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(color: AppColors.primaryRed),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final controller = _controller!;
    return _FullScreenCameraPreview(controller: controller);
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

    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return SizedBox.expand(child: CameraPreview(controller));
    }

    // previewSize is landscape sensor size; swap for portrait full-screen fill.
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _DocumentGuideOverlay extends StatelessWidget {
  const _DocumentGuideOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final frameW = (maxW * 0.92).clamp(260.0, maxW - 16);
        final frameH = (frameW / 1.58).clamp(150.0, maxH * 0.46);
        final left = (maxW - frameW) / 2;
        final top = (maxH - frameH) / 2;
        final hole = Rect.fromLTWH(left, top, frameW, frameH);
        final topPad = MediaQuery.paddingOf(context).top + 56;

        return IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: Size(maxW, maxH),
                painter: _HoleOverlayPainter(hole: hole, radius: 16),
              ),
              Positioned(
                left: left,
                top: top,
                width: frameW,
                height: frameH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2.4),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: topPad,
                child: Column(
                  children: [
                    Text(
                      'Align $label inside the frame',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Move closer so the document fills the box',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoleOverlayPainter extends CustomPainter {
  const _HoleOverlayPainter({required this.hole, required this.radius});

  final Rect hole;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)));
    final path = Path.combine(PathOperation.difference, overlay, cutout);
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.52),
    );
  }

  @override
  bool shouldRepaint(covariant _HoleOverlayPainter oldDelegate) {
    return oldDelegate.hole != hole || oldDelegate.radius != radius;
  }
}
