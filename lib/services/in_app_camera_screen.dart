import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// In-app camera with capture → preview → OK / Cancel flow.
class InAppCameraScreen extends StatefulWidget {
  const InAppCameraScreen({super.key});

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
        ResolutionPreset.medium,
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
        '${dir.path}/purchase_cam_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
      // Discard preview and go back to live camera (retake).
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isPreview ? 'Preview' : 'Take Photo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _isPreview ? _buildPreviewActions() : _buildCaptureActions(),
        ),
      ),
    );
  }

  Widget _buildCaptureActions() {
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: (_initializing || _error != null || _capturing) ? null : _capture,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
              color: _capturing ? AppColors.textSecondary : AppColors.primaryRed,
            ),
            child: _capturing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt, color: AppColors.white, size: 28),
          ),
        ),
        const SizedBox(width: 16),
        // Placeholder so capture button stays centered.
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isPreview) {
      return Center(
        child: InteractiveViewer(
          child: Image.file(
            _previewFile!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
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
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }
}
