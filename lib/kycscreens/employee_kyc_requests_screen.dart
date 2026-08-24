import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/api_config.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_store.dart';
import 'package:grjoffice_apps/models/mykycdatamodal.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class EmployeeKycRequestsScreen extends StatefulWidget {
  const EmployeeKycRequestsScreen({super.key});

  @override
  State<EmployeeKycRequestsScreen> createState() =>
      _EmployeeKycRequestsScreenState();
}

class _EmployeeKycRequestsScreenState extends State<EmployeeKycRequestsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = true;
  List<EmployeeKycConfig> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner && mounted) setState(() => _loading = true);
    final result = await getMyEmployeeKycRequestApi(context, perPage: 50);
    if (!mounted) return;
    final items = result?.items ?? const <MyKycModalData>[];
    setState(() {
      _items = items.map(_fromApiItem).toList();
      _loading = false;
    });
  }

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }

  EmployeeKycConfig _fromApiItem(MyKycModalData kyc) {
    return EmployeeKycConfig(
      employeeId: kyc.employeeId ?? '',
      employeeName: kyc.employeeName ?? '',
      email: kyc.email ?? '',
      phoneNumber: kyc.mobile ?? '',
      assignedSite: kyc.assignedSite ?? '',
      monthlySalary: kyc.monthlySalary ?? '',
      leaveAllocation: kyc.leaveAllocation ?? '',
      employmentType: kyc.employmentType ?? '',
      joiningDate: kyc.joiningDate ?? '',
      foodAllowance: kyc.foodAllowance,
      foodEmployeeAmount: kyc.foodEmployeeAmount ?? '',
      foodCompanyAmount: kyc.foodCompanyAmount ?? '',
      stayAllowance: kyc.stayAllowance,
      stayEmployeeAmount: kyc.stayEmployeeAmount ?? '',
      stayCompanyAmount: kyc.stayCompanyAmount ?? '',
      emergencyContact: kyc.emergencyContact ?? '',
      accountHolderName: kyc.accountHolderName ?? '',
      bankName: kyc.bankName ?? '',
      accountNumber: kyc.accountNumber ?? '',
      ifscCode: kyc.ifscCode ?? '',
      panPath: kyc.panPath ?? '',
      aadhaarFrontPath: kyc.aadhaarFrontPath ?? '',
      aadhaarBackPath: kyc.aadhaarBackPath ?? '',
      marksheet10Path: kyc.marksheet10Path ?? '',
      marksheet12Path: kyc.marksheet12Path ?? '',
      bankChequePath: kyc.bankChequePath ?? '',
      configuredAt: kyc.kycSubmittedAt ?? kyc.savedAt ?? DateTime.now(),
      status: (kyc.kycStatus ?? kyc.status ?? 'Submitted').trim().isEmpty
          ? 'Submitted'
          : (kyc.kycStatus ?? kyc.status ?? 'Submitted'),
      kycId: kyc.id ?? 0,
    );
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
    final contentMax = width >= 1100
        ? 860.0
        : width >= 900
            ? 760.0
            : double.infinity;
    final items = _items;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.employeeKycRequests,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Employee KYC Requests',
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
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () => _load(showSpinner: false),
                      child: items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.25,
                                ),
                                _EmptyState(hPad: hPad),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                hPad,
                                12,
                                hPad,
                                20 + bottomInset,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: contentMax),
                                    child: _ConfigCard(
                                      config: item,
                                      onTap: () {
                                        pushInShell(
                                          context,
                                          EmployeeKycDetailScreen(
                                            config: item,
                                            onUpdated: () =>
                                                _load(showSpinner: false),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.primaryRed,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No KYC submissions yet',
                style: GoogleFonts.poppins(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.headingBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completed Employee KYC submissions will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
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

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.config,
    required this.onTap,
  });

  final EmployeeKycConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final width = MediaQuery.sizeOf(context).width;
    final pad = width < 360 ? 12.0 : 14.0;
    final headerSource = config.employeeName.isNotEmpty
        ? config.employeeName
        : (config.email.isNotEmpty ? config.email : 'E');
    final avatarLetter = headerSource.substring(0, 1).toUpperCase();
    final status = config.status.trim().isEmpty ? 'Submitted' : config.status;
    final statusLower = status.toLowerCase();
    final statusBg = statusLower.contains('reject')
        ? const Color(0xFFFEF2F2)
        : statusLower.contains('pending')
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFECFDF5);
    final statusFg = statusLower.contains('reject')
        ? const Color(0xFFDC2626)
        : statusLower.contains('pending')
            ? const Color(0xFFEA580C)
            : const Color(0xFF059669);

    String yesNo(bool v) => v ? 'Yes' : 'No';

    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderGray.withValues(alpha: 0.4),
            ),
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
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      avatarLetter,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.employeeName.isNotEmpty
                              ? 'Employee'
                              : 'Email',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          config.employeeName.isNotEmpty
                              ? config.employeeName
                              : (config.email.isEmpty ? '—' : config.email),
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.headingBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _MiniRow(
                      label: 'Phone',
                      value: config.phoneNumber.isEmpty
                          ? '—'
                          : config.phoneNumber,
                    ),
                    _MiniRow(
                      label: 'Assigned Site',
                      value: config.assignedSite.isEmpty
                          ? '—'
                          : config.assignedSite,
                    ),
                    _MiniRow(
                      label: 'Salary',
                      value: config.monthlySalary.isEmpty
                          ? '—'
                          : '₹ ${config.monthlySalary}',
                    ),
                    _MiniRow(
                      label: 'Employment',
                      value: config.employmentType.isEmpty
                          ? '—'
                          : config.employmentType,
                    ),
                    _MiniRow(
                      label: 'Food Allowance',
                      value: yesNo(config.foodAllowance),
                    ),
                    if (config.foodAllowance) ...[
                      _MiniRow(
                        label: 'Food Employee',
                        value: '₹ ${config.foodEmployeeAmount}',
                      ),
                      _MiniRow(
                        label: 'Food Company',
                        value: '₹ ${config.foodCompanyAmount}',
                      ),
                    ],
                    _MiniRow(
                      label: 'Stay Allowance',
                      value: yesNo(config.stayAllowance),
                    ),
                    if (config.stayAllowance) ...[
                      _MiniRow(
                        label: 'Stay Employee',
                        value: '₹ ${config.stayEmployeeAmount}',
                      ),
                      _MiniRow(
                        label: 'Stay Company',
                        value: '₹ ${config.stayCompanyAmount}',
                      ),
                    ],
                    _MiniRow(
                      label: 'Emergency',
                      value: config.emergencyContact.isEmpty
                          ? '—'
                          : config.emergencyContact,
                    ),
                    _MiniRow(
                      label: 'Submitted',
                      value: dateFmt.format(config.configuredAt),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View Details →',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 7),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.headingBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeKycDetailScreen extends StatefulWidget {
  const EmployeeKycDetailScreen({
    super.key,
    required this.config,
    this.onUpdated,
  });

  final EmployeeKycConfig config;
  final VoidCallback? onUpdated;

  @override
  State<EmployeeKycDetailScreen> createState() =>
      _EmployeeKycDetailScreenState();
}

class _EmployeeKycDetailScreenState extends State<EmployeeKycDetailScreen> {
  late EmployeeKycConfig _config;
  bool _loading = false;
  bool _actioning = false;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetails());
  }

  bool get _isPending {
    final status = _config.status.toLowerCase();
    return !status.contains('approv') && !status.contains('reject');
  }

  Future<void> _loadDetails() async {
    final id = widget.config.kycId;
    if (id <= 0) return;
    setState(() => _loading = true);
    final result = await showEmployeeKycApi(context, employeeId: id);
    if (!mounted) return;
    final data = result?.data;
    setState(() {
      if (data != null) _config = _fromShowApi(data);
      _loading = false;
    });
  }

  EmployeeKycConfig _fromShowApi(MyKycModalData kyc) {
    return EmployeeKycConfig(
      employeeId: kyc.employeeId ?? _config.employeeId,
      employeeName: kyc.employeeName ?? _config.employeeName,
      email: kyc.email ?? _config.email,
      phoneNumber: kyc.mobile ?? _config.phoneNumber,
      assignedSite: kyc.assignedSite ?? _config.assignedSite,
      monthlySalary: kyc.monthlySalary ?? _config.monthlySalary,
      leaveAllocation: kyc.leaveAllocation ?? _config.leaveAllocation,
      employmentType: kyc.employmentType ?? _config.employmentType,
      joiningDate: kyc.joiningDate ?? _config.joiningDate,
      foodAllowance: kyc.foodAllowance,
      foodEmployeeAmount: kyc.foodEmployeeAmount ?? _config.foodEmployeeAmount,
      foodCompanyAmount: kyc.foodCompanyAmount ?? _config.foodCompanyAmount,
      stayAllowance: kyc.stayAllowance,
      stayEmployeeAmount: kyc.stayEmployeeAmount ?? _config.stayEmployeeAmount,
      stayCompanyAmount: kyc.stayCompanyAmount ?? _config.stayCompanyAmount,
      emergencyContact: kyc.emergencyContact ?? _config.emergencyContact,
      accountHolderName: kyc.accountHolderName ?? _config.accountHolderName,
      bankName: kyc.bankName ?? _config.bankName,
      accountNumber: kyc.accountNumber ?? _config.accountNumber,
      ifscCode: kyc.ifscCode ?? _config.ifscCode,
      panPath: kyc.panPath ?? _config.panPath,
      aadhaarFrontPath: kyc.aadhaarFrontPath ?? _config.aadhaarFrontPath,
      aadhaarBackPath: kyc.aadhaarBackPath ?? _config.aadhaarBackPath,
      marksheet10Path: kyc.marksheet10Path ?? _config.marksheet10Path,
      marksheet12Path: kyc.marksheet12Path ?? _config.marksheet12Path,
      bankChequePath: kyc.bankChequePath ?? _config.bankChequePath,
      configuredAt: kyc.kycSubmittedAt ?? kyc.savedAt ?? _config.configuredAt,
      status: (kyc.kycStatus ?? kyc.status ?? _config.status).trim().isEmpty
          ? _config.status
          : (kyc.kycStatus ?? kyc.status ?? _config.status),
      kycId: kyc.id ?? _config.kycId,
    );
  }

  Future<void> _confirmApprove() async {
    if (_actioning || !_isPending) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Approve KYC',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Approve this employee KYC request?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Approve',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _approve();
  }

  Future<void> _approve() async {
    if (_actioning) return;
    setState(() => _actioning = true);
    final result = await approveEmployeeKycApi(
      context,
      employeeId: _config.kycId,
    );
    if (!mounted) return;
    setState(() {
      _actioning = false;
      if (result != null) {
        final data = result.data;
        _config = data != null
            ? _fromShowApi(data)
            : _config.copyWith(status: 'Approved');
      }
    });
    if (result != null) widget.onUpdated?.call();
  }

  Future<void> _confirmReject() async {
    if (_actioning || !_isPending) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reject KYC',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Reject this employee KYC request?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Reject',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _reject();
  }

  Future<void> _reject() async {
    if (_actioning) return;
    setState(() => _actioning = true);
    final result = await rejectEmployeeKycApi(
      context,
      employeeId: _config.kycId,
    );
    if (!mounted) return;
    setState(() {
      _actioning = false;
      if (result != null) {
        final data = result.data;
        _config = data != null
            ? _fromShowApi(data)
            : _config.copyWith(status: 'Rejected');
      }
    });
    if (result != null) widget.onUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width < 600 ? 16.0 : 24.0;
    final config = _config;

    String yesNo(bool v) => v ? 'Yes' : 'No';

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.headingBlack,
        elevation: 0,
        title: Text(
          'KYC Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              )
            : ListView(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailSection(
                      title: 'Employee Information',
                      rows: [
                        (
                          'Email',
                          config.email.isEmpty ? '—' : config.email,
                        ),
                        (
                          'Phone Number',
                          config.phoneNumber.isEmpty ? '—' : config.phoneNumber,
                        ),
                        (
                          'Password',
                          config.kycPassword.isEmpty ? '—' : '••••••••',
                        ),
                        (
                          'Assigned Site',
                          config.assignedSite.isEmpty
                              ? '—'
                              : config.assignedSite,
                        ),
                        ('Joining Date', config.joiningDate),
                        (
                          'Monthly Salary',
                          config.monthlySalary.isEmpty
                              ? '—'
                              : '₹ ${config.monthlySalary}'
                        ),
                        (
                          'Leave Allocation',
                          config.leaveAllocation.isEmpty
                              ? '—'
                              : '${config.leaveAllocation} leaves / year'
                        ),
                        ('Employment Type', config.employmentType),
                        ('Food Allowance', yesNo(config.foodAllowance)),
                        if (config.foodAllowance) ...[
                          (
                            'Food Employee Amount',
                            '₹ ${config.foodEmployeeAmount}'
                          ),
                          (
                            'Food Company Provides',
                            '₹ ${config.foodCompanyAmount}'
                          ),
                        ],
                        ('Stay Allowance', yesNo(config.stayAllowance)),
                        if (config.stayAllowance) ...[
                          (
                            'Stay Employee Amount',
                            '₹ ${config.stayEmployeeAmount}'
                          ),
                          (
                            'Stay Company Provides',
                            '₹ ${config.stayCompanyAmount}'
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailSection(
                      title: 'Bank Details',
                      rows: [
                        ('Account Holder', config.accountHolderName),
                        ('Bank Name', config.bankName),
                        ('Account Number', config.accountNumber),
                        ('IFSC Code', config.ifscCode),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailSection(
                      title: 'Emergency Contact',
                      rows: [
                        (
                          'Contact Number',
                          config.emergencyContact.isEmpty
                              ? '—'
                              : config.emergencyContact
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Uploaded Documents',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.headingBlack,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailImage(label: 'PAN Card', path: config.panPath),
                    _DetailImage(
                      label: 'Aadhaar Card Front',
                      path: config.aadhaarFrontPath,
                    ),
                    _DetailImage(
                      label: 'Aadhaar Card Back',
                      path: config.aadhaarBackPath,
                    ),
                    _DetailImage(
                      label: '10th Marksheet',
                      path: config.marksheet10Path,
                    ),
                    _DetailImage(
                      label: '12th Marksheet',
                      path: config.marksheet12Path,
                    ),
                    _DetailImage(
                      label: 'Cancelled Cheque',
                      path: config.bankChequePath,
                    ),
                    const SizedBox(height: 8),
                    _EmployeeKycStatusActions(
                      status: config.status,
                      actioning: _actioning,
                      onApprove: _confirmApprove,
                      onReject: _confirmReject,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeKycStatusActions extends StatelessWidget {
  const _EmployeeKycStatusActions({
    required this.status,
    required this.actioning,
    required this.onApprove,
    required this.onReject,
  });

  final String status;
  final bool actioning;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  bool get _isPending {
    final value = status.toLowerCase();
    return !value.contains('approv') && !value.contains('reject');
  }

  Color get _statusColor {
    final value = status.toLowerCase();
    if (value.contains('reject')) return const Color(0xFFDC2626);
    if (value.contains('approv')) return const Color(0xFF059669);
    return const Color(0xFFD97706);
  }

  Color get _statusBg {
    final value = status.toLowerCase();
    if (value.contains('reject')) return const Color(0xFFFEF2F2);
    if (value.contains('approv')) return const Color(0xFFECFDF5);
    return const Color(0xFFFFF7ED);
  }

  @override
  Widget build(BuildContext context) {
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
            status.trim().isEmpty ? 'Submitted' : status,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: _statusColor,
            ),
          ),
        ),
        if (_isPending) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: actioning ? null : onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF059669).withValues(alpha: 0.5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: actioning
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
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
                  onPressed: actioning ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.85),
                    ),
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
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      rows[i].$1,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$2.isEmpty ? '—' : rows[i].$2,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final file = path.trim().isEmpty ? null : File(path);
    final hasFile = file != null && file.existsSync();
    final networkUrl = mediaUrl(path);
    final isNetwork = networkUrl.startsWith('http://') ||
        networkUrl.startsWith('https://');

    Widget image;
    if (hasFile) {
      image = Image.file(
        file,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (isNetwork) {
      image = Image.network(
        networkUrl,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _missingImage(),
      );
    } else {
      image = _missingImage();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image,
          ),
        ],
      ),
    );
  }

  Widget _missingImage() {
    return Container(
      height: 90,
      width: double.infinity,
      alignment: Alignment.center,
      color: AppColors.cardWhite,
      child: Text(
        'No image',
        style: GoogleFonts.poppins(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
