import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/reportscreen/labour_attendance_report_screen.dart';
import 'package:grjoffice_apps/reportscreen/report_detail_screen.dart';
import 'package:grjoffice_apps/reportscreen/report_models.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  final int siteId;
  final String siteName;

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  List<ReportListItem> _items = [];
  bool _loading = true;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReports());
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);

    final response = await getReportsApi(
      context,
      siteId: widget.siteId,
    );

    if (!mounted) return;

    final apiItems = response?.data?.items ?? const [];
    setState(() {
      _items = reportItemsFromApi(apiItems);
      _loading = false;
    });
  }

  void _openReport(BuildContext context, ReportListItem item) {
    if (item.opensLabourAttendanceScreen) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LabourAttendanceReportScreen(
            report: item,
            siteId: widget.siteId,
            siteName: widget.siteName,
          ),
        ),
      );
      return;
    }

    if (item.path == null || item.path!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.title} has no report path configured.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportDetailScreen(
          report: item,
          siteId: widget.siteId,
          siteName: widget.siteName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = _hPad(width);
    final columns = _gridColumns(width);
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
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: _loadReports,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                                        widget.siteName,
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
                                if (_items.isEmpty)
                                  _EmptyReportsState(onRetry: _loadReports)
                                else
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final gap = 14.0;
                                      final itemWidth = columns == 1
                                          ? constraints.maxWidth
                                          : (constraints.maxWidth -
                                                  gap * (columns - 1)) /
                                              columns;

                                      return Wrap(
                                        spacing: gap,
                                        runSpacing: gap,
                                        children: _items.map((item) {
                                          return SizedBox(
                                            width: itemWidth,
                                            child: _ReportGridCard(
                                              item: item,
                                              onTap: () =>
                                                  _openReport(context, item),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReportsState extends StatelessWidget {
  const _EmptyReportsState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 42,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'No reports available for this site.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
