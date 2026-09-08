import 'package:flutter/material.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_pending_screen.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_screen.dart';
import 'package:grjoffice_apps/main_shell.dart';
import 'package:grjoffice_apps/models/user_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/user_session.dart';

enum KycHome { app, form, pending }

/// Blocks app access until employee KYC is approved.
class KycGate {
  KycGate._();

  static const approved = 'approved';
  static const submitted = 'submitted';
  static const rejected = 'rejected';

  /// Only company admins skip their own KYC form.
  static const exemptRoles = {
    'super admin',
    'director',
    'administrator',
  };

  static UserModel? get _user =>
      UserSession.instance.user ?? cachedUser();

  static String? get status {
    final raw = _user?.kycStatus?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  /// Role / director designation only — leave or user-view perms must not skip KYC.
  static bool isExemptUser({
    required Iterable<String> roles,
    String? designation,
  }) {
    final normalized = roles.map((r) => r.trim().toLowerCase()).toSet();
    if (normalized.any(exemptRoles.contains)) return true;
    return (designation ?? '').trim().toLowerCase() == 'director';
  }

  /// Login landing: form if not submitted/rejected, pending wait if submitted.
  static KycHome resolveHome({required bool exempt, String? status}) {
    final s = status?.trim().toLowerCase();
    if (exempt || s == approved) return KycHome.app;
    if (s == submitted) return KycHome.pending;
    return KycHome.form;
  }

  static bool get isExempt {
    final user = _user;
    if (user == null) return false;
    return isExemptUser(roles: user.roles, designation: user.designation);
  }

  static bool get canAccessApp => isExempt || status == approved;

  static bool get needsKycForm =>
      resolveHome(exempt: isExempt, status: status) == KycHome.form;

  static bool get isPending =>
      resolveHome(exempt: isExempt, status: status) == KycHome.pending;

  static Widget homeScreen() {
    return switch (resolveHome(exempt: isExempt, status: status)) {
      KycHome.app => const MainShell(),
      KycHome.pending => const EmployeeKycPendingScreen(),
      KycHome.form => const EmployeeKycScreen(),
    };
  }

  static Future<void> syncStatus(String? next) => updateCachedKycStatus(next);
}
