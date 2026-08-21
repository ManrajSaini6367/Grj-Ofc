import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

/// Labour Attendance Report — UI only (API wiring later).
class LabourAttendanceReportScreen extends StatefulWidget {
  const LabourAttendanceReportScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  final int siteId;
  final String siteName;

  @override
  State<LabourAttendanceReportScreen> createState() =>
      _LabourAttendanceReportScreenState();
}

class _LabourAttendanceReportScreenState
    extends State<LabourAttendanceReportScreen> {
  static const _contractorPlaceholder = 'Please Choose';

  String _contractor = _contractorPlaceholder;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _searched = false;

  static final _dateFmt = DateFormat('dd/MM/yyyy');

  double _hPad(double width) {
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 24;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  void _onSearch() {
    if (_contractor == _contractorPlaceholder) {
      _snack('Please choose a contractor.');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _snack('Please select start and end date.');
      return;
    }
    setState(() => _searched = true);
  }

  void _onClear() {
    setState(() {
      _contractor = _contractorPlaceholder;
      _startDate = null;
      _endDate = null;
      _searched = false;
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = _hPad(width);
    final isCompact = width < 520;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Labour Attendance',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPageHeader(),
                        const SizedBox(height: 16),
                        _buildFilterCard(isCompact: isCompact),
                        const SizedBox(height: 16),
                        _buildTableCard(isCompact: isCompact),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports List',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Reports Management Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.siteName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryRed,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCard({required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCompact) ...[
            _buildContractorField(),
            const SizedBox(height: 12),
            _buildDateField(
              label: 'Start date',
              value: _startDate,
              onTap: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: 12),
            _buildDateField(
              label: 'End Date',
              value: _endDate,
              onTap: () => _pickDate(isStart: false),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildContractorField()),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: 'Start date',
                    value: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: 'End Date',
                    value: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Search',
                icon: Icons.search,
                backgroundColor: const Color(0xFF2563EB),
                onPressed: _onSearch,
              ),
              _ActionButton(
                label: 'Clear',
                icon: Icons.refresh,
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: AppColors.headingBlack,
                onPressed: _onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contractor',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _contractor,
          isExpanded: true,
          decoration: _fieldDecoration(),
          items: [
            DropdownMenuItem(
              value: _contractorPlaceholder,
              child: Text(
                _contractorPlaceholder,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: InputDecorator(
            decoration: _fieldDecoration().copyWith(
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
            child: Text(
              value == null ? 'dd/mm/yyyy' : _dateFmt.format(value),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: value == null
                    ? AppColors.inputHint
                    : AppColors.headingBlack,
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: AppColors.primaryRed.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildTableCard({required bool isCompact}) {
    if (!_searched) {
      return _buildReportShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 40,
                color: AppColors.textSecondary.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 12),
              Text(
                'Select contractor and date range, then tap Search.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rows = _previewRowsForDesign();
    final rangeLabel = _rangeLabel();

    return _buildReportShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReportBanner(rangeLabel: rangeLabel, dayCount: rows.length),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
              child: Text(
                'No attendance records found for this period.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...rows.asMap().entries.map((entry) {
              final isLast = entry.key == rows.length - 1;
              return _buildDayCard(
                row: entry.value,
                showDivider: !isLast,
                isCompact: isCompact,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReportShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  String _rangeLabel() {
    if (_startDate == null || _endDate == null) return '';
    return '${DateFormat('dd MMM').format(_startDate!)} – '
        '${DateFormat('dd MMM yyyy').format(_endDate!)}';
  }

  /// Temporary rows so mobile card layout is visible before API wiring.
  List<_LabourDayRow> _previewRowsForDesign() {
    if (_startDate == null || _endDate == null) return const [];

    final rows = <_LabourDayRow>[];
    var day = _startDate!;
    final end = _endDate!;

    while (!day.isAfter(end) && rows.length < 7) {
      rows.add(_LabourDayRow(date: day));
      day = day.add(const Duration(days: 1));
    }
    return rows;
  }

  Widget _buildReportBanner({
    required String rangeLabel,
    required int dayCount,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LABOUR ATTENDANCE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _contractor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                    height: 1.25,
                  ),
                ),
                if (rangeLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rangeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderGray.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '$dayCount ${dayCount == 1 ? 'day' : 'days'}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard({
    required _LabourDayRow row,
    required bool showDivider,
    required bool isCompact,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: AppColors.borderGray.withValues(alpha: 0.28),
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('dd MMM yyyy').format(row.date),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEE').format(row.date).toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMetricSection(
            title: 'Regular',
            metrics: [
              _MetricTile(label: 'Mason', value: row.mason),
              _MetricTile(label: 'Beldar', value: row.beldar),
              _MetricTile(label: 'Coolie', value: row.coolie),
            ],
            isCompact: isCompact,
            emphasized: true,
          ),
          const SizedBox(height: 12),
          _buildMetricSection(
            title: 'Overtime',
            metrics: [
              _MetricTile(label: 'Mason Over', value: row.masonOver),
              _MetricTile(label: 'Beldar Over', value: row.beldarOver),
              _MetricTile(label: 'Coolie Over', value: row.coolieOver),
            ],
            isCompact: isCompact,
            emphasized: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSection({
    required String title,
    required List<_MetricTile> metrics,
    required bool isCompact,
    required bool emphasized,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final useGrid = isCompact || constraints.maxWidth < 560;
            if (useGrid) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildMetricTile(metrics[0], emphasized)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMetricTile(metrics[1], emphasized)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildMetricTile(metrics[2], emphasized),
                ],
              );
            }

            return Row(
              children: metrics.asMap().entries.map((entry) {
                final isLast = entry.key == metrics.length - 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: _buildMetricTile(entry.value, emphasized),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricTile(_MetricTile metric, bool emphasized) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.operationsCardBg
            : AppColors.backgroundGray.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.displayValue,
            style: GoogleFonts.poppins(
              fontSize: emphasized ? 20 : 16,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabourDayRow {
  const _LabourDayRow({
    required this.date,
    this.mason,
    this.beldar,
    this.coolie,
    this.masonOver,
    this.beldarOver,
    this.coolieOver,
  });

  final DateTime date;
  final num? mason;
  final num? beldar;
  final num? coolie;
  final num? masonOver;
  final num? beldarOver;
  final num? coolieOver;
}

class _MetricTile {
  const _MetricTile({required this.label, this.value});

  final String label;
  final num? value;

  String get displayValue => value == null ? '—' : '$value';
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    this.foregroundColor = AppColors.white,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}
