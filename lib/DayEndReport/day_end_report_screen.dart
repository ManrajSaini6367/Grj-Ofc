import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/DayEndReport/day_end_report_detail_screen.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/utils/app_helpers.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';
import 'package:intl/intl.dart';

/// Day End Report — choose date step (API later).
class DayEndReportScreen extends StatefulWidget {
  const DayEndReportScreen({super.key});

  @override
  State<DayEndReportScreen> createState() => _DayEndReportScreenState();
}

class _DayEndReportScreenState extends State<DayEndReportScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DateTime? _selectedDate;

  static final _displayFormat = DateFormat('dd MMM yyyy');
  static final _prettyFormat = DateFormat('EEE, dd MMM yyyy');

  double _hPad(double width) {
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 28;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: AppColors.white,
              surface: AppColors.cardWhite,
              onSurface: AppColors.headingBlack,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
  }

  void _onNext() {
    final date = _selectedDate;
    if (date == null) {
      message(context, 'Please select a date');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DayEndReportDetailScreen(selectedDate: date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = _hPad(size.width);
    final isCompact = size.width < 420;
    final isWide = size.width >= 720;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.dayEndReport,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Day End Report',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      isCompact ? 16 : 22,
                      hPad,
                      28,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 44,
                          maxWidth: isWide ? 560 : 640,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeroHeader(isCompact: isCompact),
                            SizedBox(height: isCompact ? 16 : 20),
                            _buildInformationCard(
                              isCompact: isCompact,
                              isWide: isWide,
                            ),
                          ],
                        ),
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

  Widget _buildHeroHeader({required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: isCompact ? 22 : 26,
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'CHOOSE DATE',
                style: GoogleFonts.poppins(
                  color: AppColors.headingBlack,
                  fontSize: isCompact ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                'Site',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.borderGray,
              ),
              Text(
                'Day Report',
                style: GoogleFonts.poppins(
                  color: AppColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformationCard({
    required bool isCompact,
    required bool isWide,
  }) {
    final hasDate = _selectedDate != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 16 : 22,
              isCompact ? 16 : 18,
              isCompact ? 16 : 22,
              isCompact ? 14 : 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.operationsCardBg.withValues(alpha: 0.55),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: isCompact ? 40 : 44,
                  height: isCompact ? 40 : 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_note_rounded,
                    color: AppColors.primaryRed,
                    size: isCompact ? 20 : 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Information Site',
                        style: GoogleFonts.poppins(
                          color: AppColors.headingBlack,
                          fontSize: isCompact ? 15.5 : 17,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select a date to view the day-end material report',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: isCompact ? 11.5 : 12.5,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 16 : 22,
              isCompact ? 18 : 22,
              isCompact ? 16 : 22,
              isCompact ? 18 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fieldLabelText(
                  'Date',
                  isRequired: true,
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDateField(isCompact: isCompact),
                if (hasDate) ...[
                  const SizedBox(height: 10),
                  Text(
                    _prettyFormat.format(_selectedDate!),
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryRed,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                SizedBox(height: isCompact ? 18 : 22),
                _buildNextButton(fullWidth: !isWide || isCompact),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({required bool isCompact}) {
    final hasDate = _selectedDate != null;
    final label =
        hasDate ? _displayFormat.format(_selectedDate!) : 'dd/mm/yyyy';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: isCompact ? 50 : 52,
          decoration: BoxDecoration(
            color: hasDate
                ? AppColors.primaryRed.withValues(alpha: 0.04)
                : AppColors.operationsCardBg.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasDate
                  ? AppColors.primaryRed.withValues(alpha: 0.35)
                  : AppColors.borderGray.withValues(alpha: 0.7),
              width: hasDate ? 1.4 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: hasDate
                          ? AppColors.headingBlack
                          : AppColors.inputHint,
                      fontSize: 14.5,
                      fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: AppColors.borderGray.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: hasDate
                        ? AppColors.primaryRed
                        : AppColors.headingBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton({required bool fullWidth}) {
    final button = Material(
      color: AppColors.primaryRed,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      shadowColor: AppColors.primaryRed.withValues(alpha: 0.35),
      child: InkWell(
        onTap: _onNext,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: fullWidth ? double.infinity : null,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: fullWidth ? 16 : 28,
            vertical: 14,
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                size: 18,
                color: AppColors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Next',
                style: GoogleFonts.poppins(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (fullWidth) return button;
    return Align(alignment: Alignment.centerLeft, child: button);
  }
}
