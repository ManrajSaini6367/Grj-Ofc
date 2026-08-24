import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/reportscreen/labour_attendance_report_screen.dart';
import 'package:grjoffice_apps/reportscreen/report_detail_screen.dart';
import 'package:grjoffice_apps/reportscreen/report_models.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ReportListItem> _items = [];
  bool _loading = true;
  bool _missingSite = false;

  int? get _siteId => selectedSiteId();

  String get _siteName {
    final named = selectedSiteName()?.trim();
    if (named != null && named.isNotEmpty) return named;
    final id = _siteId;
    if (id == null) return '';
    final fromCache = siteNameById(cachedSites() ?? const [], id)?.trim();
    if (fromCache != null && fromCache.isNotEmpty) return fromCache;
    return 'Site $id';
  }

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
    final siteId = _siteId;
    if (siteId == null) {
      setState(() {
        _items = [];
        _loading = false;
        _missingSite = true;
      });
      return;
    }

    setState(() {
      _loading = true;
      _missingSite = false;
    });

    final response = await getReportsApi(
      context,
      siteId: siteId,
    );

    if (!mounted) return;

    final apiItems = response?.data?.items ?? const [];
    setState(() {
      _items = reportItemsFromApi(apiItems);
      _loading = false;
    });
  }

  void _openReport(BuildContext context, ReportListItem item) {
    final siteId = _siteId;
    if (siteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select a site from the App Bar to view reports.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final apiPath = item.resolvedPath;
    if (apiPath.isEmpty) {
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

    if (item.opensLabourAttendanceScreen) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LabourAttendanceReportScreen(
            report: item,
            siteId: siteId,
            siteName: _siteName,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportDetailScreen(
          report: item,
          siteId: siteId,
          siteName: _siteName,
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
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.report,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar.shell(
              title: 'Reports',
              scaffoldKey: _scaffoldKey,
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
                                        _siteName.isEmpty
                                            ? 'No site selected'
                                            : _siteName,
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
                                  _EmptyReportsState(
                                    onRetry: _missingSite ? null : _loadReports,
                                    message: _missingSite
                                        ? 'Select a site from the App Bar to view reports.'
                                        : 'No reports available for this site.',
                                  )
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
  const _EmptyReportsState({
    this.onRetry,
    this.message = 'No reports available for this site.',
  });

  final VoidCallback? onRetry;
  final String message;

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
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          if (onRetry != null) ...[
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
