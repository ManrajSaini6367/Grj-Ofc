import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/core/app_navigator.dart';
import 'package:grjoffice_apps/services/connectivity_service.dart';

/// Blocks the app with a non-dismissible popup when the phone has no internet.
class InternetRequiredGuard extends StatefulWidget {
  const InternetRequiredGuard({super.key, required this.child});

  final Widget child;

  @override
  State<InternetRequiredGuard> createState() => _InternetRequiredGuardState();
}

class _InternetRequiredGuardState extends State<InternetRequiredGuard> {
  final ConnectivityService _connectivity = ConnectivityService.instance;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _connectivity.start();
    _connectivity.addListener(_onConnectivityChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onConnectivityChanged());
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    if (_connectivity.isOffline) {
      _showOverlay();
      return;
    }
    _hideOverlay();
  }

  void _showOverlay() {
    if (_entry != null) return;
    final overlay = appNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onConnectivityChanged();
      });
      return;
    }

    _entry = OverlayEntry(
      builder: (context) => const Stack(
        children: [
          ModalBarrier(dismissible: false, color: Color(0x99000000)),
          Center(child: _NoInternetDialog()),
        ],
      ),
    );
    overlay.insert(_entry!);
  }

  void _hideOverlay() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NoInternetDialog extends StatelessWidget {
  const _NoInternetDialog();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'No Internet Connection',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        content: Text(
          'The app needs internet to run. Please turn on mobile data or Wi-Fi, or close the app.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => ConnectivityService.instance.closeApp(),
            child: Text(
              'Close App',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ConnectivityService.instance.openInternetSettings();
              await ConnectivityService.instance.checkNow();
            },
            child: Text(
              'Turn On Internet',
              style: GoogleFonts.poppins(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
