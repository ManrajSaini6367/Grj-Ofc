import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/kycscreens/kyc_models.dart';
import 'package:grjoffice_apps/kycscreens/kyc_service.dart';
import 'package:grjoffice_apps/kycscreens/kyc_wizard_screen.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

/// Employee view: KYC status + entry into the KYC wizard.
class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final _service = KycService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = true;

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await _service.ensureLoaded();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _onUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdated);
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 24;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final request = _service.myRequest;
    final status = request?.status ?? KycStatus.notStarted;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.kycVerification,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'KYC Verification',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        14,
                        hPad,
                        20,
                      ),
                      children: [
                        _HeaderCard(status: status, request: request),
                        const SizedBox(height: 14),
                        if (status == KycStatus.notStarted)
                          _NotStartedCard(
                            onStart: () => pushInShell(
                              context,
                              const KycWizardScreen(readOnly: false),
                            ),
                          )
                        else
                          _UnderReviewOrFinalCard(
                            status: status,
                            request: request,
                            onView: () => pushInShell(
                              context,
                              KycWizardScreen(
                                initialRequest: request,
                                readOnly: status == KycStatus.pending ||
                                    status == KycStatus.approved,
                              ),
                            ),
                            onEdit: () => pushInShell(
                              context,
                              KycWizardScreen(
                                initialRequest: request,
                                readOnly: false,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.status,
    required this.request,
  });

  final KycStatus status;
  final KycRequest? request;

  Color get _statusColor {
    switch (status) {
      case KycStatus.notStarted:
        return const Color(0xFF9CA3AF);
      case KycStatus.pending:
        return const Color(0xFFD97706);
      case KycStatus.approved:
        return const Color(0xFF059669);
      case KycStatus.rejected:
        return const Color(0xFFDC2626);
    }
  }

  Color get _statusBg {
    switch (status) {
      case KycStatus.notStarted:
        return const Color(0xFFF3F4F6);
      case KycStatus.pending:
        return const Color(0xFFFFF7ED);
      case KycStatus.approved:
        return const Color(0xFFECFDF5);
      case KycStatus.rejected:
        return const Color(0xFFFEF2F2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitted = request?.submittedAt;
    final verified = request?.verifiedAt;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == KycStatus.approved
                          ? Icons.check_circle_rounded
                          : status == KycStatus.rejected
                              ? Icons.cancel_rounded
                              : Icons.hourglass_top_rounded,
                      size: 16,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status == KycStatus.notStarted
                          ? 'Not Started'
                          : status.label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (submitted != null)
                Text(
                  'Submitted: ${dateFmt.format(submitted)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (verified != null) ...[
            const SizedBox(height: 10),
            Text(
              'Verified on ${dateFmt.format(verified)}',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotStartedCard extends StatelessWidget {
  const _NotStartedCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Your KYC',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fill your personal, identity, and bank details to get verified.',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Start KYC',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _UnderReviewOrFinalCard extends StatelessWidget {
  const _UnderReviewOrFinalCard({
    required this.status,
    required this.request,
    required this.onView,
    required this.onEdit,
  });

  final KycStatus status;
  final KycRequest? request;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final reason = request?.rejectionReason;

    if (status == KycStatus.pending || status == KycStatus.approved) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderGray.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status == KycStatus.pending
                  ? 'Your KYC is under verification.'
                  : 'KYC Approved successfully.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.headingBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status == KycStatus.pending
                  ? 'Please wait while HR reviews your documents.'
                  : 'You can review your KYC details anytime.',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onView,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.primaryRed.withValues(alpha: 0.8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // rejected
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your KYC was rejected.',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 10),
          if (reason != null && reason.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reason: $reason',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headingBlack,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 420
                    ? double.infinity
                    : null,
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.primaryRed.withValues(alpha: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Edit KYC',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width < 420
                    ? double.infinity
                    : null,
                child: ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Resubmit',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

