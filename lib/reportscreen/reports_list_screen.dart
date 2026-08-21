import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/reportscreen/labour_attendance_report_screen.dart';
import 'package:grjoffice_apps/reportscreen/report_models.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  final int siteId;
  final String siteName;

  double _hPad(double width) {
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 24;
  }

  int _gridColumns(double width) {
    if (width < 520) return 1;
    if (width < 900) return 2;
    return 3;
  }

  void _openReport(BuildContext context, ReportListItem item) {
    switch (item.type) {
      case ReportType.labourAttendance:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LabourAttendanceReportScreen(
              siteId: siteId,
              siteName: siteName,
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.title} — API coming soon.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = _hPad(width);
    final columns = _gridColumns(width);
    final items = previewReportItems(siteName: siteName);
    final contentMax = width >= 1100 ? 1040.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar.page(
              title: 'Reports',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMax),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'REPORT LIST',
                          style: GoogleFonts.poppins(
                            fontSize: width < 400 ? 18 : 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.headingBlack,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                siteName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final gap = 14.0;
                            final itemWidth = columns == 1
                                ? constraints.maxWidth
                                : (constraints.maxWidth - gap * (columns - 1)) /
                                    columns;

                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: items.map((item) {
                                return SizedBox(
                                  width: itemWidth,
                                  child: _ReportGridCard(
                                    item: item,
                                    onTap: () => _openReport(context, item),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
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
}

class _ReportGridCard extends StatelessWidget {
  const _ReportGridCard({
    required this.item,
    required this.onTap,
  });

  final ReportListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      elevation: 0,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.borderGray.withValues(alpha: 0.35),
            ),
            boxShadow: [
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: item.accentColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
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
