import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_screen.dart';
import 'package:grjoffice_apps/main_shell.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/kyc_gate.dart';
import 'package:grjoffice_apps/utils/app_helpers.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

/// Shown after KYC submit while waiting for admin approval.
class EmployeeKycPendingScreen extends StatefulWidget {
  const EmployeeKycPendingScreen({super.key});

  @override
  State<EmployeeKycPendingScreen> createState() =>
      _EmployeeKycPendingScreenState();
}

class _EmployeeKycPendingScreenState extends State<EmployeeKycPendingScreen> {
  bool _checking = false;
  String? _rejectionReason;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshStatus(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus({bool silent = false}) async {
    if (_checking) return;
    if (!silent) setState(() => _checking = true);

    final kyc = await getMyEmployeeKycApi(context);
    if (!mounted) return;

    final status = (kyc?.kycStatus ?? kyc?.status ?? '').trim().toLowerCase();
    final mapped = switch (status) {
      'approved' => KycGate.approved,
      'rejected' => KycGate.rejected,
      'submitted' => KycGate.submitted,
      _ when status.contains('approv') => KycGate.approved,
      _ when status.contains('reject') => KycGate.rejected,
      _ when status.contains('submit') => KycGate.submitted,
      _ => status.isEmpty ? KycGate.submitted : status,
    };

    await KycGate.syncStatus(mapped);
    if (!mounted) return;

    setState(() {
      _checking = false;
      _rejectionReason = mapped == KycGate.rejected
          ? (kyc?.kycRejectionReason?.toString().trim().isNotEmpty == true
              ? kyc!.kycRejectionReason.toString().trim()
              : null)
          : null;
    });

    if (mapped == KycGate.approved) {
      pushAndRevoveUntil(context, const MainShell());
      return;
    }
    if (mapped == KycGate.rejected && !silent) {
      // Stay on this screen; CTA below opens the form again.
    }
  }

  Future<void> _resubmit() async {
    await KycGate.syncStatus(KycGate.rejected);
    if (!mounted) return;
    pushAndRevoveUntil(context, const EmployeeKycScreen());
  }

  Future<void> _logout() async {
    await logoutApi(context);
  }

  @override
  Widget build(BuildContext context) {
    final rejected = KycGate.status == KycGate.rejected;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const AppLogo(size: 96, showBorder: true),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.borderGray.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: rejected
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFFFF7ED),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            rejected
                                ? Icons.cancel_outlined
                                : Icons.hourglass_top_rounded,
                            size: 32,
                            color: rejected
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          rejected
                              ? 'KYC Rejected'
                              : 'KYC Under Review',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.headingBlack,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          rejected
                              ? (_rejectionReason?.isNotEmpty == true
                                  ? _rejectionReason!
                                  : 'Your KYC was rejected. Please update and submit again.')
                              : 'Your KYC has been submitted successfully.\nPlease wait while admin reviews and approves it.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _checking
                                ? null
                                : () => rejected
                                    ? _resubmit()
                                    : _refreshStatus(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: AppColors.primaryRed
                                  .withValues(alpha: 0.55),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _checking
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(
                                    rejected
                                        ? 'Resubmit KYC'
                                        : 'Check Approval Status',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _logout,
                          child: Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
