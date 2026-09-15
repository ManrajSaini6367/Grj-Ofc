import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/DayEndReport/activities.dart';
import 'package:grjoffice_apps/attendancescreen/attendance_screen.dart';
import 'package:grjoffice_apps/attendancescreen/contractor_attendance_screen.dart';
import 'package:grjoffice_apps/AmaniLabour/amani_labours.dart';
import 'package:grjoffice_apps/SupplierList/suppliers.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/services/attendance_service.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/location_service.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/services/punch_in_gate.dart';
import 'package:grjoffice_apps/services/punch_in_location_validator.dart';
import 'package:grjoffice_apps/services/user_session.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';
import 'package:grjoffice_apps/widgets/site_selection_dialog.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AttendanceService _attendance = AttendanceService.instance;
  final LocationService _location = LocationService.instance;

  String _selectedSite = '';
  bool _isProcessingPunch = false;
  bool _isLoadingSites = true;
  List<SiteModel> _siteItems = [];
  List<String> _sites = [];

  static const _operations = [
    _OperationItem(
      Icons.inventory_2_outlined,
      'Supplier',
      'SUPPLIER',
      anyOf: [AppPermissions.suppliersView],
    ),
    _OperationItem(
      Icons.groups_outlined,
      'Amani Labour',
      'AMANI LABOUR',
      anyOf: [AppPermissions.contractorsView],
    ),
    _OperationItem(
      Icons.storefront_outlined,
      'Store',
      'STORE',
      anyOf: [
        AppPermissions.itemsView,
        AppPermissions.itemsCreate,
      ],
    ),
    _OperationItem(
      Icons.shopping_cart_outlined,
      'Purchase',
      'PURCHASE',
      anyOf: [
        AppPermissions.purchasesView,
        AppPermissions.purchasesCreate,
        AppPermissions.purchasesViewAll,
      ],
    ),
    _OperationItem(
      Icons.badge_outlined,
      'Employer Attendances',
      'EMPLOYER ATTENDANCES',
      anyOf: [
        AppPermissions.employerAttendancesView,
        AppPermissions.employerAttendancesCreate,
        AppPermissions.viewAttendances,
      ],
    ),
    _OperationItem(
      Icons.people_outline,
      'Contractor Attendances',
      'CONTRACTOR ATTENDANCES',
      anyOf: [
        AppPermissions.labourAttendancesView,
        AppPermissions.labourAttendancesCreate,
        AppPermissions.labourAttendancesReport,
      ],
    ),
  ];

  List<_OperationItem> get _visibleOperations {
    final perms = PermissionService.instance;
    return _operations.where((item) {
      if (item.anyOf.isEmpty) return true;
      return perms.canAny(item.anyOf);
    }).toList();
  }

  // static const _supplies = [
  //   // _SupplyItem(
  //   //   Icons.print_outlined,
  //   //   'Plotter Ink Cyan',
  //   //   'Requested by John D. • Site A',
  //   // ),
  //   // _SupplyItem(
  //   //   Icons.menu_book_outlined,
  //   //   'Field Notebooks',
  //   //   'Completed 6h ago',
  //   // ),
  // ];

  /// Login / profile `attendance_allow` — controls Punch In card on Dashboard.
  bool get _attendanceAllowed =>
      UserSession.instance.user?.attendanceAllow ??
      cachedUser()?.attendanceAllow ??
      false;

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  void initState() {
    super.initState();
    _attendance.addListener(_onAttendanceChanged);
    _restoreSavedSiteFromCache();
    _bootstrap();
  }

  void _restoreSavedSiteFromCache() {
    final cached = cachedSites();
    if (cached != null && cached.isNotEmpty) {
      _siteItems = cached;
      _sites = siteNames(cached);
      _selectedSite = _resolveSelectedSiteName(cached) ?? '';
      _isLoadingSites = false;
      return;
    }
    final savedName = selectedSiteName()?.trim();
    if (savedName != null && savedName.isNotEmpty) {
      _selectedSite = savedName;
    }
  }

  Future<void> _bootstrap() async {
    await _attendance.load();
    await _loadSites();
    if (mounted && _attendanceAllowed) {
      await _syncAttendanceAcrossSites();
    }
    if (_attendanceAllowed) {
      final granted = await _location.initialize();
      if (_attendance.isPunchedIn && granted) {
        await _location.startTracking();
      }
    }
    if (mounted) setState(() {});
  }

  /// Unlocks the app if the user already punched in at any assigned site.
  Future<void> _syncAttendanceAcrossSites() async {
    if (!_attendanceAllowed) return;
    final result = await getTodayAttendanceForAccessApi(
      context,
      siteIds: _assignedSiteIds(),
      showErrors: false,
    );
    if (result != null) {
      await _attendance.applyTodayStatus(
        result.status,
        punchSiteId: result.punchSiteId,
      );
    }
  }

  List<int> _assignedSiteIds() {
    final user = UserSession.instance.user ?? cachedUser();
    final ids = <int>{
      if (user != null && user.siteId > 0) user.siteId,
      ...?user?.siteIds,
    };
    if (ids.isEmpty) {
      final sites = _siteItems.isNotEmpty
          ? _siteItems
          : (cachedSites() ?? const <SiteModel>[]);
      ids.addAll(sites.map((site) => site.id));
    }
    return ids.toList();
  }

  Future<void> _loadSites() async {
    final sites = await sitesApi(context, perPage: 100);
    if (!mounted) return;

    if (sites != null && sites.isNotEmpty) {
      final names = siteNames(sites);
      final resolvedName =
          _resolveSelectedSiteName(sites) ?? names.first;

      _siteItems = sites;
      _sites = names;
      _selectedSite = resolvedName;
      await _saveSelectedSite(resolvedName);
      if (!mounted) return;
      setState(() => _isLoadingSites = false);
      return;
    }

    setState(() => _isLoadingSites = false);
  }

  String? _resolveSelectedSiteName(List<SiteModel> sites) {
    final names = siteNames(sites);
    if (names.isEmpty) return null;

    final savedId = selectedSiteId();
    if (savedId != null && savedId > 0) {
      final name = siteNameById(sites, savedId);
      if (name != null && names.contains(name)) return name;
    }

    final savedName = selectedSiteName()?.trim();
    if (savedName != null &&
        savedName.isNotEmpty &&
        names.contains(savedName)) {
      return savedName;
    }

    return _defaultSiteName(sites) ?? names.first;
  }

  String? _defaultSiteName(List<SiteModel> sites) {
    final user = cachedUser();
    if (user == null || user.siteId <= 0) return null;
    return siteNameById(sites, user.siteId);
  }

  Future<void> _saveSelectedSite(String siteName) async {
    final sites = _siteItems.isNotEmpty
        ? _siteItems
        : (cachedSites() ?? const <SiteModel>[]);
    for (final site in sites) {
      if (site.name == siteName) {
        await saveSiteId(site.id, siteName: siteName);
        return;
      }
    }
  }

  @override
  void dispose() {
    _attendance.removeListener(_onAttendanceChanged);
    super.dispose();
  }

  void _onAttendanceChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  SiteModel? _siteForPunchIn([List<SiteModel>? sites]) {
    final list = sites ?? _siteItems;
    if (_selectedSite.isNotEmpty) {
      for (final site in list) {
        if (site.name == _selectedSite) return site;
      }
    }
    final id = selectedSiteId();
    if (id != null) {
      for (final site in list) {
        if (site.id == id) return site;
      }
    }
    return null;
  }

  Future<SiteModel?> _resolvePunchSite() async {
    final fetched = await sitesApi(context, perPage: 100);
    if (!mounted) return null;

    if (fetched != null && fetched.isNotEmpty) {
      _siteItems = fetched;
      _sites = siteNames(fetched);
    }

    if (_selectedSite.isNotEmpty) {
      await _saveSelectedSite(_selectedSite);
    }

    return _siteForPunchIn(_siteItems);
  }

  void _showPunchMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
    setState(() => _isProcessingPunch = false);
  }

  Future<void> _handlePunchIn() async {
    if (!_attendanceAllowed) return;
    if (_isProcessingPunch || !_attendance.canPunchIn) return;
    setState(() => _isProcessingPunch = true);

    final site = await _resolvePunchSite();
    if (!mounted) return;
    if (site == null) {
      _showPunchMessage('Please select a site first.');
      return;
    }
    if (!site.hasCoordinates) {
      _showPunchMessage(
        'Punch-in not allowed you are outside that location.',      );
      return;
    }
    if (!site.hasPunchRadius) {
      _showPunchMessage(
        'Allowed punch-in distance is not configured for this site.',
      );
      return;
    }

    final access = await _location.prepareForForegroundUse();
    if (!access.isReady) {
      _showPunchMessage(access.message);
      return;
    }

    final radiusMeters = site.radiusMeters!;
    final maxAccuracyMeters =
        PunchInLocationValidator.maxAcceptableAccuracyMeters(radiusMeters);
    final desiredAccuracyMeters =
        maxAccuracyMeters < 50 ? maxAccuracyMeters : 50.0;
    final position = await _location.getAccurateCurrentLocation(
      reason: 'PUNCH IN location',
      desiredAccuracyMeters: desiredAccuracyMeters,
      maxAccuracyMeters: maxAccuracyMeters,
    );
    if (position == null) {
      _showPunchMessage(
        'Unable to get an accurate GPS location. Try again in an open area.',
      );
      return;
    }

    final locationCheck = PunchInLocationValidator.validate(
      userLatitude: position.latitude,
      userLongitude: position.longitude,
      allowedLatitude: site.latitude!,
      allowedLongitude: site.longitude!,
      radiusKm: site.radiusKm!,
    );
    if (!locationCheck.allowed) {
      _showPunchMessage(
        locationCheck.message ??
            'You are outside that location.',
      );
      return;
    }

    final result = await punchInApi(
      context,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() => _isProcessingPunch = false);
      return;
    }

    await _attendance.applyTodayStatus(
      result.toTodayStatus(),
      punchSiteId: result.attendance?.siteId ?? selectedSiteId(),
    );
    await _location.startTracking();

    setState(() => _isProcessingPunch = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Punched in successfully.')),
    );
  }

  Future<void> _handlePunchOut() async {
    if (!_attendanceAllowed) return;
    if (_isProcessingPunch || !_attendance.canPunchOut) return;
    setState(() => _isProcessingPunch = true);

    final granted = await _location.initialize();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required to punch out.')),
      );
      setState(() => _isProcessingPunch = false);
      return;
    }

    final position = await _location.getCurrentLocation(reason: 'PUNCH OUT location');
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to fetch current location. Try again.')),
        );
        setState(() => _isProcessingPunch = false);
      }
      return;
    }

    final result = await punchOutApi(
      context,
      latitude: position.latitude,
      longitude: position.longitude,
      siteId: _attendance.punchSiteId,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() => _isProcessingPunch = false);
      return;
    }

    await _attendance.applyTodayStatus(result.toTodayStatus());
    await _location.stopTracking();

    setState(() => _isProcessingPunch = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Punched out successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final canOpenMenus = !_attendanceAllowed || _attendance.isPunchedIn;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawerEnableOpenDragGesture: canOpenMenus,
      endDrawerEnableOpenDragGesture: canOpenMenus,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.dashboard,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderGray.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: _buildTopBar(),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryRed,
                onRefresh: _bootstrap,
                child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 14),
                            AnimatedBuilder(
                              animation: UserSession.instance,
                              builder: (context, _) {
                                if (!_attendanceAllowed) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    _AttendanceCard(
                                      attendance: _attendance,
                                      isProcessingPunch: _isProcessingPunch,
                                      onPunchIn: _handlePunchIn,
                                      onPunchOut: _handlePunchOut,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              },
                            ),
                            PunchInLockedLayer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildQuickActions(),
                                  const SizedBox(height: 24),
                                  AnimatedBuilder(
                                    animation: PermissionService.instance,
                                    builder: (context, _) {
                                      final visibleOps = _visibleOperations;
                                      if (visibleOps.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildSectionTitle('Operations'),
                                          const SizedBox(height: 12),
                                          _buildOperationsGrid(
                                            constraints.maxWidth,
                                            visibleOps,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  // const SizedBox(height: 24),
                                  // _buildSectionTitle('Office Supplies'),
                                  // const SizedBox(height: 12),
                                  // ..._supplies.map(_buildSupplyCard),
                                  // const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (!PunchInGate.ensureAccess(context)) return;
            _scaffoldKey.currentState?.openDrawer();
          },
          child: const AppLogo(size: 40),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildSiteSelector()),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.iconBgGray,
            border: Border.all(color: AppColors.borderGray),
          ),
          child: IconButton(
            onPressed: () {
              if (!PunchInGate.ensureAccess(context)) return;
              _scaffoldKey.currentState?.openEndDrawer();
            },
            icon: Icon(Icons.person_outline, color: AppColors.textSecondary, size: 22),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildSiteSelector() {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _isLoadingSites || _sites.isEmpty
            ? null
            : _openSiteSelection,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(
            children: [
              Expanded(
                child: _isLoadingSites
                    ? Text(
                        'Loading sites...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Text(
                        _selectedSite.isEmpty ? 'Select site' : _selectedSite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSiteSelection() async {
    if (_sites.isEmpty) return;
    final selected = await SiteSelectionDialog.show(
      context,
      sites: _sites,
      selectedSite: _selectedSite.isEmpty ? _sites.first : _selectedSite,
    );
    if (selected != null && selected != _selectedSite) {
      await _saveSelectedSite(selected);
      if (mounted) setState(() => _selectedSite = selected);
      await _syncAttendanceAcrossSites();
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Back Office Portal',
          style: TextStyle(
            color: AppColors.headingBlack,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Administrative command center & logistics',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return AnimatedBuilder(
      animation: PermissionService.instance,
      builder: (context, _) {
        final showActivity =
            PermissionService.instance.can(AppPermissions.viewDayReport);

        return Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Chats',
                subtitle: 'Manage Chats',
                onTap: () => navigateToMainTab(context, MainTab.chats),
              ),
            ),
            if (showActivity) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.history,
                  title: 'Activity',
                  subtitle: 'Check all activity',
                  onTap: () => pushInShell(context, const ActivitiesScreen()),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.operationsCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 26),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.headingBlack,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.headingBlack,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildOperationsGrid(
    double maxWidth,
    List<_OperationItem> operations,
  ) {
    final crossAxisCount = maxWidth >= 520 ? 3 : 2;
    final aspectRatio = maxWidth < 360 ? 1.18 : 1.28;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: aspectRatio,
      ),
      itemCount: operations.length,
      itemBuilder: (context, index) =>
          _buildOperationCard(operations[index]),
    );
  }

  void _openOperation(_OperationItem item) {
    switch (item.title) {
      case 'Supplier':
        pushInShell(context, const SuppliersScreen(isActive: true));
      case 'Amani Labour':
        pushInShell(context, const ContractorsScreen(isActive: true));
      case 'Store':
        navigateToMainTab(context, MainTab.store);
      case 'Purchase':
        navigateToMainTab(context, MainTab.purchase);
      case 'Employer Attendances':
        pushInShell(context, const AttendanceScreen());
      case 'Contractor Attendances':
        pushInShell(context, const ContractorAttendanceScreen());
    }
  }

  Widget _buildOperationCard(_OperationItem item) {
    return GestureDetector(
      onTap: () => _openOperation(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.operationsCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, color: AppColors.primaryRed, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.headingBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationItem {
  const _OperationItem(
    this.icon,
    this.title,
    this.subtitle, {
    this.anyOf = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Empty = always visible. Otherwise user needs any of these permissions.
  final List<String> anyOf;
}

class _AttendanceCard extends StatefulWidget {
  const _AttendanceCard({
    required this.attendance,
    required this.isProcessingPunch,
    required this.onPunchIn,
    required this.onPunchOut,
  });

  final AttendanceService attendance;
  final bool isProcessingPunch;
  final Future<void> Function() onPunchIn;
  final Future<void> Function() onPunchOut;

  @override
  State<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<_AttendanceCard> {
  @override
  void initState() {
    super.initState();
    widget.attendance.addListener(_onAttendanceChanged);
  }

  @override
  void dispose() {
    widget.attendance.removeListener(_onAttendanceChanged);
    super.dispose();
  }

  void _onAttendanceChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  String _punchedInSubtitle(AttendanceService attendance) {
    final punchSiteId =
        attendance.punchSiteId ?? attendance.todayAttendance?.siteId;
    final currentSiteId = selectedSiteId();
    if (punchSiteId == null ||
        currentSiteId == null ||
        punchSiteId == currentSiteId) {
      return 'Tap punch out when you finish';
    }

    final punchSiteName = attendance.todayAttendance?.siteName?.trim() ??
        siteNameById(cachedSites() ?? const [], punchSiteId)?.trim();
    if (punchSiteName != null && punchSiteName.isNotEmpty) {
      return 'Punched in at $punchSiteName. This site is unlocked.';
    }
    return 'Already punched in. This site is unlocked.';
  }

  Widget _buildPunchButton(bool isPunchedIn) {
    final canAct = isPunchedIn
        ? widget.attendance.canPunchOut
        : widget.attendance.canPunchIn;

    return SizedBox(
      width: 122,
      height: 46,
      child: ElevatedButton(
        onPressed: widget.isProcessingPunch || !canAct
            ? null
            : (isPunchedIn ? widget.onPunchOut : widget.onPunchIn),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPunchedIn ? AppColors.headingBlack : AppColors.punchLightGreen,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: widget.isProcessingPunch
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
              )
            : Text(
                isPunchedIn ? 'PUNCH OUT' : 'PUNCH IN',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendance = widget.attendance;
    final isPunchedIn = attendance.isPunchedIn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPunchedIn ? 'Currently Punched In' : 'Ready to Punch In',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPunchedIn
                      ? _punchedInSubtitle(attendance)
                      : 'Tap to start your shift',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildPunchButton(isPunchedIn),
        ],
      ),
    );
  }
}
