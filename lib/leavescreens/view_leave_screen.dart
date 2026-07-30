import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/getshowleavemodal.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class ViewLeaveScreen extends StatefulWidget {
  const ViewLeaveScreen({super.key, required this.leaveId});

  final String leaveId;

  @override
  State<ViewLeaveScreen> createState() => _ViewLeaveScreenState();
}

class _ViewLeaveScreenState extends State<ViewLeaveScreen> {
  bool _loading = true;
  ShowLeaveData? _leave;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await getShowLeaveApi(context, widget.leaveId);
    if (!mounted) return;
    setState(() {
      _leave = result?.data;
      _loading = false;
    });
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  String _text(String? value, {String fallback = '—'}) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? fallback : v;
  }

  String _date(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('dd MMM yyyy').format(value);
  }

  String _dateTime(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }

  String get _statusKey => (_leave?.status ?? 'pending').trim().toLowerCase();

  String get _statusLabel {
    final key = _statusKey;
    if (key.isEmpty) return 'Pending';
    return key[0].toUpperCase() + key.substring(1);
  }

  Color get _statusColor {
    switch (_statusKey) {
      case 'approved':
        return const Color(0xFF059669);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  Color get _statusBg {
    switch (_statusKey) {
      case 'approved':
        return const Color(0xFFECFDF5);
      case 'rejected':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFFFF7ED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final leave = _leave;
    final days = leave?.durationDays ?? 0;
    final durationLabel = days == 1 ? '1 Day' : '$days Days';

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Leave Details',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : leave == null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Unable to load leave details.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _load,
                                  child: Text(
                                    'Retry',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primaryRed,
                          onRefresh: _load,
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              hPad,
                              16,
                              hPad,
                              24 + MediaQuery.paddingOf(context).bottom,
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.cardWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.borderGray
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _text(
                                              leave.typeLabel ?? leave.type,
                                              fallback: 'Leave',
                                            ),
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.headingBlack,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusBg,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            _statusLabel,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _DetailRow(
                                      label: 'Employee',
                                      value: _text(leave.employeeName),
                                    ),
                                    _DetailRow(
                                      label: 'From Date',
                                      value: _date(leave.fromDate),
                                    ),
                                    _DetailRow(
                                      label: 'To Date',
                                      value: _date(leave.toDate),
                                    ),
                                    _DetailRow(
                                      label: 'Total Days',
                                      value: durationLabel,
                                    ),
                                    _DetailRow(
                                      label: 'Applied On',
                                      value: _dateTime(leave.createdAt),
                                    ),
                                    if ((leave.reviewedByName?.toString() ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      _DetailRow(
                                        label: 'Reviewed By',
                                        value: leave.reviewedByName.toString(),
                                      ),
                                    if ((leave.reviewNote?.toString() ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      _DetailRow(
                                        label: 'Review Note',
                                        value: leave.reviewNote.toString(),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Description',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _text(leave.description),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppColors.textDark,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.headingBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
