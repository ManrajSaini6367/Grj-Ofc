import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/DayEndReport/activity.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  ActivityType? _typeFilter;
  _DateFilter _dateFilter = _DateFilter.all;

  List<ActivityEntry> _activities = [];
  ActivitySummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActivities());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _loadActivities(showLoader: false);
    });
  }

  String get _apiType => _typeFilter?.apiValue ?? 'all';

  String get _apiPeriod => switch (_dateFilter) {
        _DateFilter.all => 'all',
        _DateFilter.today => 'today',
        _DateFilter.last7 => 'last7',
        _DateFilter.last30 => 'last30',
      };

  Future<void> _loadActivities({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);

    final response = await getActivitiesApi(
      context,
      type: _apiType,
      period: _apiPeriod,
      search: _searchController.text.trim(),
      perPage: 50,
    );
    if (!mounted) return;

    setState(() {
      _activities = response?.data?.items ?? [];
      _summary = response?.data?.summary;
      _isLoading = false;
    });
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  bool get _hasActiveFilters =>
      _typeFilter != null ||
      _dateFilter != _DateFilter.all ||
      _searchController.text.trim().isNotEmpty;

  int get _todayCount => _summary?.today ?? 0;

  int get _totalCount => _summary?.total ?? _activities.length;

  int get _modulesCount {
    final byType = _summary?.byType;
    if (byType != null && byType.isNotEmpty) return byType.length;
    return ActivityType.values.length;
  }

  Future<void> _openActivity(ActivityEntry activity) async {
    final id = int.tryParse(activity.id);
    if (id == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      ),
    );

    final detail = await getActivityApi(context, id);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final item = detail ?? activity;
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final color = activityTypeColor(item.type);
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderGray.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(activityTypeIcon(item.type), color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.headingBlack,
                            ),
                          ),
                          Text(
                            activityTypeLabel(item.type),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow('Performed by', item.performedBy),
                if ((item.site ?? '').isNotEmpty) _detailRow('Site', item.site!),
                _detailRow('Date', _formatDateTime(item.dateTime)),
                if (item.subjectId != null)
                  _detailRow('Reference', '#${item.subjectId}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.headingBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final items = _activities;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(selectedIndex: -1, onItemTap: _onDrawerItemTap),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Activity',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () => _loadActivities(showLoader: false),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildStatsRow(),
                                  const SizedBox(height: 16),
                                  _buildToolbar(),
                                  const SizedBox(height: 12),
                                  _buildFilterChips(),
                                  if (_hasActiveFilters) ...[
                                    const SizedBox(height: 10),
                                    _buildClearFilters(),
                                  ],
                                  const SizedBox(height: 16),
                                  _buildSectionHeader(items.length),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                          if (items.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildActivityCard(
                                    items[index],
                                    index == items.length - 1,
                                  ),
                                  childCount: items.length,
                                ),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard('Today', '$_todayCount', Icons.today_outlined, AppColors.primaryRed),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard('Total', '$_totalCount', Icons.timeline_outlined, const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard('Modules', '$_modulesCount', Icons.apps_rounded, const Color(0xFF059669)),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 14),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _loadActivities(showLoader: false),
        decoration: InputDecoration(
          hintText: 'Search activity by title, user or site...',
          hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
          filled: true,
          fillColor: AppColors.operationsCardBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _dateChip('All', _DateFilter.all),
          const SizedBox(width: 8),
          _dateChip('Today', _DateFilter.today),
          const SizedBox(width: 8),
          _dateChip('7 Days', _DateFilter.last7),
          const SizedBox(width: 8),
          _dateChip('30 Days', _DateFilter.last30),
          const SizedBox(width: 12),
          Container(width: 1, height: 24, color: AppColors.borderGray.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          _typeChip('All Types', null),
          ...ActivityType.values.map(
            (t) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _typeChip(activityTypeLabel(t), t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, _DateFilter value) {
    final selected = _dateFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: selected ? AppColors.primaryRed : AppColors.textDark,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        setState(() => _dateFilter = value);
        _loadActivities();
      },
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryRed,
      backgroundColor: AppColors.cardWhite,
      side: BorderSide(
        color: selected
            ? AppColors.primaryRed.withValues(alpha: 0.4)
            : AppColors.borderGray.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _typeChip(String label, ActivityType? type) {
    final selected = _typeFilter == type;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: selected ? AppColors.primaryRed : AppColors.textDark,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        setState(() => _typeFilter = type);
        _loadActivities();
      },
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryRed,
      backgroundColor: AppColors.cardWhite,
      side: BorderSide(
        color: selected
            ? AppColors.primaryRed.withValues(alpha: 0.4)
            : AppColors.borderGray.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildClearFilters() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          _searchController.clear();
          setState(() {
            _typeFilter = null;
            _dateFilter = _DateFilter.all;
          });
          _loadActivities();
        },
        child: Text(
          'Clear filters',
          style: GoogleFonts.poppins(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryRed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(ActivityEntry activity, bool isLast) {
    final color = activityTypeColor(activity.type);
    final bg = color.withValues(alpha: 0.1);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.borderGray.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openActivity(activity),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.borderGray.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                activityTypeIcon(activity.type),
                                size: 20,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.headingBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activity.description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _metaChip(Icons.person_outline, activity.performedBy),
                            if ((activity.site ?? '').isNotEmpty)
                              _metaChip(Icons.location_on_outlined, activity.site!),
                            _metaChip(Icons.schedule, _formatDateTime(activity.dateTime)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                activityTypeLabel(activity.type),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$min';
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No activity found',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            'Try adjusting search or filters',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }
}

enum _DateFilter { all, today, last7, last30 }
