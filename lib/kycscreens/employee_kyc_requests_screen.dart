import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_store.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class EmployeeKycRequestsScreen extends StatefulWidget {
  const EmployeeKycRequestsScreen({super.key});

  @override
  State<EmployeeKycRequestsScreen> createState() =>
      _EmployeeKycRequestsScreenState();
}

class _EmployeeKycRequestsScreenState extends State<EmployeeKycRequestsScreen> {
  final _store = EmployeeKycStore.instance;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await _store.ensureLoaded();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _onUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_onUpdated);
    super.dispose();
  }

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
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
    final items = _store.items;
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
                  : items.isEmpty
                      ? _EmptyState(hPad: hPad)
                      : ListView.separated(
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
                                      EmployeeKycDetailScreen(config: item),
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
                      config.employeeId.isEmpty
                          ? 'E'
                          : config.employeeId.substring(0, 1).toUpperCase(),
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
                          'Employee ID',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          config.employeeId.isEmpty ? '—' : config.employeeId,
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
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      config.status,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
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

class EmployeeKycDetailScreen extends StatelessWidget {
  const EmployeeKycDetailScreen({super.key, required this.config});

  final EmployeeKycConfig config;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width < 600 ? 16.0 : 24.0;

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
        child: ListView(
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
                        ('Employee ID', config.employeeId),
                        ('Assigned Site', config.assignedSite),
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
            child: hasFile
                ? Image.file(
                    file,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
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
                  ),
          ),
        ],
      ),
    );
  }
}
