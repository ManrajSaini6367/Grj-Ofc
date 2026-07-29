import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/kycscreens/kyc_models.dart';
import 'package:grjoffice_apps/kycscreens/kyc_service.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class KycRequestsScreen extends StatefulWidget {
  const KycRequestsScreen({super.key});

  @override
  State<KycRequestsScreen> createState() => _KycRequestsScreenState();
}

class _KycRequestsScreenState extends State<KycRequestsScreen> {
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
    final width = MediaQuery.sizeOf(context).width;
    final contentMax = width >= 1100 ? 860.0 : width >= 900 ? 760.0 : double.infinity;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.kycRequests,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'KYC Requests',
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
                  : _service.requests.isEmpty
                      ? _EmptyState(hPad: hPad)
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            hPad,
                            12,
                            hPad,
                            18 + bottomInset,
                          ),
                          itemCount: _service.requests.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final req = _service.requests[index];
                            return Center(
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: contentMax),
                                child: _KycRequestCard(
                                  request: req,
                                  onView: () {
                                    pushInShell(
                                      context,
                                      KycRequestDetailScreen(requestId: req.id),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hPad});

  final double hPad;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad + 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: AppColors.primaryRed,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No KYC requests yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.headingBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'As employees submit KYC, requests will appear here for approval.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KycRequestCard extends StatelessWidget {
  const _KycRequestCard({
    required this.request,
    required this.onView,
  });

  final KycRequest request;
  final VoidCallback onView;

  Color get _statusColor {
    switch (request.status) {
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
    switch (request.status) {
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
    final dateFmt = DateFormat('d MMM yyyy');
    final initials = request.employeeName
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  initials.isEmpty ? 'E' : initials,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.employeeName,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.headingBlack,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Employee ID : ${request.employeeId}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  request.status.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Submitted: ${dateFmt.format(request.submittedAt)}',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 160,
              child: OutlinedButton(
                onPressed: onView,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.primaryRed.withValues(alpha: 0.85),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KycRequestDetailScreen extends StatefulWidget {
  const KycRequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  State<KycRequestDetailScreen> createState() => _KycRequestDetailScreenState();
}

class _KycRequestDetailScreenState extends State<KycRequestDetailScreen> {
  final _service = KycService.instance;
  bool _submitting = false;
  final _reasonCtrl = TextEditingController();
  bool _showRejectReason = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await _service.ensureLoaded();
    if (!mounted) return;
    setState(() {});
  }

  void _onUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdated);
    _reasonCtrl.dispose();
    super.dispose();
  }

  KycRequest? get _request {
    try {
      return _service.requests.firstWhere((e) => e.id == widget.requestId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = _request;
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width < 600 ? 14.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              title: Text(
                'HR Detail',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
              ),
              backgroundColor: AppColors.cardWhite,
              foregroundColor: AppColors.headingBlack,
              elevation: 0,
            ),
            Expanded(
              child: req == null
                  ? const Center(child: Text('Request not found.'))
                  : ListView(
                      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 20),
                      children: [
                        _HrSectionHeader(title: 'Personal Details'),
                        const SizedBox(height: 8),
                        _InfoGrid(items: [
                          _InfoItem(
                              label: 'Full Name',
                              value: req.fullName),
                          _InfoItem(
                              label: 'Mobile',
                              value: req.mobileNumber),
                          _InfoItem(
                              label: 'Email',
                              value: req.email),
                          _InfoItem(
                              label: 'Date of Birth',
                              value: DateFormat('d MMM yyyy')
                                  .format(req.dateOfBirth)),
                          _InfoItem(
                              label: 'Gender',
                              value: req.gender),
                          _InfoItem(
                              label: 'Employee ID',
                              value: req.employeeId),
                        ]),
                        const SizedBox(height: 14),
                        _HrSectionHeader(title: 'Address'),
                        const SizedBox(height: 8),
                        _InfoGrid(items: [
                          _InfoItem(label: 'Address Line', value: req.addressLine),
                          _InfoItem(label: 'City', value: req.city),
                          _InfoItem(label: 'State', value: req.state),
                          _InfoItem(label: 'Pincode', value: req.pincode),
                        ]),
                        const SizedBox(height: 14),
                        _HrSectionHeader(title: 'Bank Details'),
                        const SizedBox(height: 8),
                        _InfoGrid(items: [
                          _InfoItem(label: 'Account Holder', value: req.accountHolderName),
                          _InfoItem(label: 'Bank Name', value: req.bankName),
                          _InfoItem(label: 'Account Number', value: req.accountNumber),
                          _InfoItem(label: 'IFSC Code', value: req.ifscCode),
                        ]),
                        const SizedBox(height: 14),
                        _HrSectionHeader(title: 'Uploaded Documents'),
                        const SizedBox(height: 8),
                        _DocsRow(
                          frontPath: req.identityFrontPath,
                          backPath: req.identityBackPath,
                          label: req.identityProofType.label,
                        ),
                        const SizedBox(height: 14),
                        _HrSectionHeader(title: 'Profile Photo'),
                        const SizedBox(height: 8),
                        _ProfilePhoto(profilePhotoPath: req.profilePhotoPath),
                        const SizedBox(height: 16),
                        _HrStatusAndActions(
                          status: req.status,
                          rejectionReason: req.rejectionReason,
                          onApprove: () async {
                            if (_submitting) return;
                            setState(() => _submitting = true);
                            await _service.approve(req.id);
                            if (!mounted) return;
                            setState(() {
                              _submitting = false;
                              _showRejectReason = false;
                              _reasonCtrl.clear();
                            });
                          },
                          onRejectPressed: () {
                            setState(() => _showRejectReason = true);
                          },
                          showRejectReason: _showRejectReason,
                          reasonCtrl: _reasonCtrl,
                          onSubmitReject: () async {
                            final reason = _reasonCtrl.text.trim();
                            if (reason.isEmpty) return;
                            setState(() => _submitting = true);
                            await _service.reject(req.id, reason);
                            if (!mounted) return;
                            setState(() {
                              _submitting = false;
                              _showRejectReason = false;
                            });
                          },
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

class _HrSectionHeader extends StatelessWidget {
  const _HrSectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14.5,
        fontWeight: FontWeight.w900,
        color: AppColors.headingBlack,
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value});
  final String label;
  final String value;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final twoCol = width >= 520;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: twoCol ? 2 : 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 10,
        childAspectRatio: twoCol ? 3.2 : 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                  color: AppColors.headingBlack,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DocsRow extends StatelessWidget {
  const _DocsRow({
    required this.frontPath,
    required this.backPath,
    required this.label,
  });

  final String frontPath;
  final String? backPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    final front = File(frontPath);
    final hasBack = backPath != null && backPath!.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: _DocTile(
            title: '$label - Front',
            file: front.existsSync() ? front : null,
            fallbackIcon: Icons.document_scanner_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DocTile(
            title: '$label - Back',
            file: hasBack && File(backPath!).existsSync() ? File(backPath!) : null,
            fallbackIcon: Icons.photo_size_select_actual_rounded,
          ),
        ),
      ],
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.title,
    required this.file,
    required this.fallbackIcon,
  });

  final String title;
  final File? file;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: file == null
                ? Container(
                    height: 110,
                    color: const Color(0xFFF7F8FA),
                    alignment: Alignment.center,
                    child: Icon(fallbackIcon,
                        color: AppColors.textSecondary, size: 30),
                  )
                : Image.file(
                    file!,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.profilePhotoPath});
  final String profilePhotoPath;

  @override
  Widget build(BuildContext context) {
    final file = File(profilePhotoPath);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: file.existsSync()
            ? Image.file(
                file,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Container(
                height: 180,
                color: const Color(0xFFF7F8FA),
                alignment: Alignment.center,
                child: const Icon(Icons.person, color: AppColors.textSecondary, size: 30),
              ),
      ),
    );
  }
}

class _HrStatusAndActions extends StatelessWidget {
  const _HrStatusAndActions({
    required this.status,
    required this.rejectionReason,
    required this.onApprove,
    required this.onRejectPressed,
    required this.showRejectReason,
    required this.reasonCtrl,
    required this.onSubmitReject,
  });

  final KycStatus status;
  final String? rejectionReason;
  final VoidCallback onApprove;
  final VoidCallback onRejectPressed;
  final bool showRejectReason;
  final TextEditingController reasonCtrl;
  final VoidCallback onSubmitReject;

  Color get _statusColor {
    switch (status) {
      case KycStatus.pending:
        return const Color(0xFFD97706);
      case KycStatus.approved:
        return const Color(0xFF059669);
      case KycStatus.rejected:
        return const Color(0xFFDC2626);
      case KycStatus.notStarted:
        return const Color(0xFF9CA3AF);
    }
  }

  Color get _statusBg {
    switch (status) {
      case KycStatus.pending:
        return const Color(0xFFFFF7ED);
      case KycStatus.approved:
        return const Color(0xFFECFDF5);
      case KycStatus.rejected:
        return const Color(0xFFFEF2F2);
      case KycStatus.notStarted:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = status == KycStatus.pending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _statusBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status.label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: _statusColor,
            ),
          ),
        ),
        if (status == KycStatus.rejected && rejectionReason != null && rejectionReason!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
              ),
              child: Text(
                'Reason: ${rejectionReason!}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingBlack,
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        if (isPending) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Approve',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRejectPressed,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.85)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (showRejectReason && isPending) ...[
          const SizedBox(height: 12),
          Text(
            'Rejection Reason',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: AppColors.headingBlack),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: reasonCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter reason for rejection...',
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmitReject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Submit Rejection',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

