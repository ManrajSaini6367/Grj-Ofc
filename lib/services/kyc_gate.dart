import 'package:flutter/material.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_pending_screen.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_screen.dart';
import 'package:grjoffice_apps/main_shell.dart';
import 'package:grjoffice_apps/models/user_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/services/user_session.dart';

/// Blocks app access until employee KYC is approved.
class KycGate {
  KycGate._();

  static const approved = 'approved';
  static const submitted = 'submitted';
  static const rejected = 'rejected';

  static const _exemptRoles = {
    'super admin',
    'director',
    'administrator',
    'hr',
    'project manager',
    'ho accounts',
    'back office',
  };

  static UserModel? get _user =>
      UserSession.instance.user ?? cachedUser();

  static String? get status {
    final raw = _user?.kycStatus?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  /// KYC managers / directors can use the app without completing KYC themselves.
  static bool get isExempt {
    final user = _user;
    if (user == null) return false;

    final roles = user.roles.map((r) => r.trim().toLowerCase()).toSet();
    if (roles.any(_exemptRoles.contains)) return true;

    final designation = (user.designation ?? '').trim().toLowerCase();
    if (designation == 'director') return true;

    final perms = PermissionService.instance;
    return perms.can('view_users') || perms.can('view_leaves');
  }

  static bool get canAccessApp => isExempt || status == approved;

  static bool get needsKycForm =>
      !isExempt && (status == null || status == rejected);

  static bool get isPending => !isExempt && status == submitted;

  static Widget homeScreen() {
    if (canAccessApp) return const MainShell();
    if (isPending) return const EmployeeKycPendingScreen();
    return const EmployeeKycScreen();
  }

  static Future<void> syncStatus(String? next) => updateCachedKycStatus(next);
}
