import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/activities/activity.dart';
import 'package:grjoffice_apps/contractors/contractors.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/employees/employees.dart';
import 'package:grjoffice_apps/homepage/homepage.dart';
import 'package:grjoffice_apps/items/items.dart';
import 'package:grjoffice_apps/profilescreen/profilescreen.dart';
import 'package:grjoffice_apps/store/store.dart';
import 'package:grjoffice_apps/suppliers/suppliers.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ActivityType? _typeFilter;
  _DateFilter _dateFilter = _DateFilter.all;

  late List<ActivityEntry> _activities;

  @override
  void initState() {
    super.initState();
    _activities = List<ActivityEntry>.from(kMockActivities);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  List<ActivityEntry> get _filteredActivities {
    return _activities.where((a) {
      if (_typeFilter != null && a.type != _typeFilter) return false;
      if (!_matchesDateFilter(a.dateTime)) return false;
      if (_searchQuery.isNotEmpty) {
        final haystack = '${a.title} ${a.description} ${a.performedBy} ${a.site ?? ''} ${activityTypeLabel(a.type)}'
            .toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  bool _matchesDateFilter(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final actDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    switch (_dateFilter) {
      case _DateFilter.all:
        return true;
      case _DateFilter.today:
        return actDate == today;
      case _DateFilter.last7:
        return !actDate.isBefore(today.subtract(const Duration(days: 6)));
      case _DateFilter.last30:
        return !actDate.isBefore(today.subtract(const Duration(days: 29)));
    }
  }

  bool get _hasActiveFilters => _typeFilter != null || _dateFilter != _DateFilter.all;

  int get _todayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _activities.where((a) {
      final d = DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
      return d == today;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final items = _filteredActivities;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(selectedIndex: 0, onItemTap: _onDrawerItemTap),
      endDrawer: const AppEndDrawer(),
      body: Column(
        children: [
          _buildHeroHeader(hPad),
          Expanded(
            child: CustomScrollView(
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
                      ],
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildActivityCard(items[index], index == items.length - 1),
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(double hPad) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B1D1D), Color(0xFF5C1212)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x338B1D1D), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _headerIconButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                  const Spacer(),
                  const AppLogo(size: 34),
                  const Spacer(),
                  _headerIconButton(Icons.menu_rounded, () => _scaffoldKey.currentState?.openDrawer()),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.history_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity Feed',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Activity List',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
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
                  _heroChip('${_activities.length} total'),
                  _heroChip('$_todayCount today'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 40, height: 40, child: Icon(icon, color: Colors.white, size: 18)),
      ),
    );
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
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
          child: _statCard('This Week', '${_countLastDays(7)}', Icons.date_range_outlined, const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard('Modules', '${ActivityType.values.length}', Icons.apps_rounded, const Color(0xFF059669)),
        ),
      ],
    );
  }

  int _countLastDays(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    return _activities.where((a) => !a.dateTime.isBefore(start)).length;
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
          ...ActivityType.values.map((t) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _typeChip(activityTypeLabel(t), t),
              )),
        ],
      ),
    );
  }

  Widget _dateChip(String label, _DateFilter value) {
    final selected = _dateFilter == value;
    return FilterChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: selected ? AppColors.primaryRed : AppColors.textDark)),
      selected: selected,
      onSelected: (_) => setState(() => _dateFilter = value),
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryRed,
      backgroundColor: AppColors.cardWhite,
      side: BorderSide(color: selected ? AppColors.primaryRed.withValues(alpha: 0.4) : AppColors.borderGray.withValues(alpha: 0.5)),
    );
  }

  Widget _typeChip(String label, ActivityType? type) {
    final selected = _typeFilter == type;
    return FilterChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: selected ? AppColors.primaryRed : AppColors.textDark)),
      selected: selected,
      onSelected: (_) => setState(() => _typeFilter = type),
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryRed,
      backgroundColor: AppColors.cardWhite,
      side: BorderSide(color: selected ? AppColors.primaryRed.withValues(alpha: 0.4) : AppColors.borderGray.withValues(alpha: 0.5)),
    );
  }

  Widget _buildClearFilters() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => setState(() {
          _typeFilter = null;
          _dateFilter = _DateFilter.all;
        }),
        child: Text('Clear filters', style: GoogleFonts.poppins(color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Text('Recent Activity', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryRed)),
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
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.borderGray.withValues(alpha: 0.4)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
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
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                          child: Icon(activityTypeIcon(activity.type), size: 20, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.title,
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.headingBlack),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activity.description,
                                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
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
                        if (activity.site != null) _metaChip(Icons.location_on_outlined, activity.site!),
                        _metaChip(Icons.schedule, _formatDateTime(activity.dateTime)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            activityTypeLabel(activity.type),
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                          ),
                        ),
                      ],
                    ),
                  ],
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
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
          Icon(Icons.history_toggle_off, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('No activity found', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          Text('Try adjusting search or filters', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _onDrawerItemTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EmployeesScreen()));
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SuppliersScreen()));
    } else if (index == 4) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ContractorsScreen()));
    } else if (index == 5) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ItemsScreen()));
    } else if (index == 6) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StoreScreen()));
    }
  }

  Widget _buildBottomNav() {
    const items = [
      _NavItem(Icons.grid_view_rounded, 'Dashboard'),
      _NavItem(Icons.badge_outlined, 'Employees'),
      _NavItem(Icons.inventory_2_outlined, 'Supplier'),
      _NavItem(Icons.engineering_outlined, 'Contractor'),
      _NavItem(Icons.person_outline, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  if (index == 0) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  } else if (index == 1) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const EmployeesScreen()));
                  } else if (index == 2) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SuppliersScreen()));
                  } else if (index == 3) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ContractorsScreen()));
                  } else if (index == 4) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 22, color: AppColors.textSecondary),
                    const SizedBox(height: 4),
                    Text(item.label, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

enum _DateFilter { all, today, last7, last30 }

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
