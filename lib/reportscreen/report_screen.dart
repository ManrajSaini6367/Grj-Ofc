import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/reportscreen/reports_list_screen.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

/// Step 1 — Choose Site (web-style Reports entry).
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<SiteModel> _sites = [];
  int? _selectedSiteId;
  bool _loadingSites = true;

  double _hPad(double width) {
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 24;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSites());
  }

  Future<void> _loadSites() async {
    final cached = cachedSites();
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _applySites(cached);
        _loadingSites = false;
      });
    }

    final sites = await sitesApi(context);
    if (!mounted) return;
    setState(() {
      _applySites(sites ?? cached ?? const []);
      _loadingSites = false;
    });
  }

  void _applySites(List<SiteModel> sites) {
    _sites = sites.where((s) => s.name.trim().isNotEmpty).toList();
    final preferred = selectedSiteId();
    if (preferred != null && _sites.any((s) => s.id == preferred)) {
      _selectedSiteId = preferred;
    } else if (_sites.isNotEmpty) {
      _selectedSiteId = _sites.first.id;
    }
  }

  String? _selectedSiteName() {
    if (_selectedSiteId == null) return null;
    return siteNameById(_sites, _selectedSiteId!);
  }

  void _onNext() {
    final siteId = _selectedSiteId;
    final siteName = _selectedSiteName();
    if (siteId == null || siteName == null || siteName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a site.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportsListScreen(
          siteId: siteId,
          siteName: siteName,
        ),
      ),
    );
    saveSiteId(siteId, siteName: siteName);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = _hPad(width);
    final isWide = width >= 720;

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
          children: [
            AppTopBar.shell(
              title: 'Reports',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 560 : 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'CHOOSE SITE',
                          style: GoogleFonts.poppins(
                            fontSize: width < 400 ? 18 : 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.headingBlack,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.borderGray.withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Information Site',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.headingBlack,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Site',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _loadingSites
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      child: Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: AppColors.primaryRed,
                                          ),
                                        ),
                                      ),
                                    )
                                  : DropdownButtonFormField<int>(
                                      value: _selectedSiteId,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        hintText: '-- Select an option --',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: AppColors.inputHint,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.cardWhite,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                            color: AppColors.borderGray
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                            color: AppColors.borderGray
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                            color: AppColors.primaryRed
                                                .withValues(alpha: 0.55),
                                            width: 1.4,
                                          ),
                                        ),
                                      ),
                                      items: _sites
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s.id,
                                              child: Text(
                                                s.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _selectedSiteId = v),
                                    ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _loadingSites || _sites.isEmpty
                                          ? null
                                          : _onNext,
                                  icon: const Icon(Icons.description_outlined,
                                      size: 18),
                                  label: Text(
                                    'Next',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: AppColors.white,
                                    disabledBackgroundColor: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.45),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
