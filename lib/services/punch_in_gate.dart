import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/attendance_service.dart';
import 'package:grjoffice_apps/services/user_session.dart';

/// Blocks app access until the user punches in when [attendanceAllow] is enabled.
class PunchInGate {
  PunchInGate._();

  static const accessMessage = 'Please punch in first to access';

  /// Prevents rapid taps from queueing many snackbars.
  static DateTime? _lastAccessMessageAt;
  static const _accessMessageCooldown = Duration(seconds: 2);

  static bool get isRequired {
    return UserSession.instance.user?.attendanceAllow ??
        cachedUser()?.attendanceAllow ??
        false;
  }

  static bool get canAccessApp {
    if (!isRequired) return true;
    return AttendanceService.instance.isPunchedIn;
  }

  static bool ensureAccess(BuildContext context, {bool showMessage = true}) {
    if (canAccessApp) return true;
    if (showMessage && context.mounted) {
      _showAccessMessageOnce(context);
    }
    return false;
  }

  static void _showAccessMessageOnce(BuildContext context) {
    final now = DateTime.now();
    final last = _lastAccessMessageAt;
    if (last != null && now.difference(last) < _accessMessageCooldown) {
      return;
    }
    _lastAccessMessageAt = now;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(accessMessage),
        backgroundColor: AppColors.primaryRed,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  static VoidCallback? guard(BuildContext context, VoidCallback? action) {
    if (action == null) return null;
    return () {
      if (ensureAccess(context)) action();
    };
  }
}

/// Visually dims locked content and shows [PunchInGate.accessMessage] on tap.
class PunchInLockedLayer extends StatelessWidget {
  const PunchInLockedLayer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AttendanceService.instance,
      builder: (context, _) {
        if (PunchInGate.canAccessApp) return child;

        return Stack(
          children: [
            AbsorbPointer(
              child: Opacity(opacity: 0.55, child: child),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => PunchInGate.ensureAccess(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
