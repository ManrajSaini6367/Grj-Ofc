import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/items/items.dart';
import 'package:grjoffice_apps/store/store.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/employees/add_employee_screen.dart';
import 'package:grjoffice_apps/employees/employee.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

enum _SortOption { nameAsc, nameDesc, idAsc }

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _siteFilter;
  EmployeeStatus? _statusFilter;
  _SortOption _sortOption = _SortOption.nameAsc;

  static const _sites = [
    'Skyline B-4',
    'Skyline Main',
    'Skyline B-2',
    'Skyline Towers',
  ];

  @override
  void initState() {
    super.initState();
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

  List<Employee> get _filteredEmployees {
    var list = kMockEmployees.where((employee) {
      if (_siteFilter != null && employee.site != _siteFilter) return false;
      if (_statusFilter != null && employee.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final haystack =
          '${employee.name} ${employee.role} ${employee.id}'.toLowerCase();
      return haystack.contains(_searchQuery);
    }).toList();

    switch (_sortOption) {
      case _SortOption.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _SortOption.nameDesc:
        list.sort((a, b) => b.name.compareTo(a.name));
      case _SortOption.idAsc:
        list.sort((a, b) => a.id.compareTo(b.id));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: 1,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
              color: AppColors.cardWhite,
              child: _buildTopBar(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSearchBar(),
                            const SizedBox(height: 12),
                            _buildFilterSortRow(),
                            const SizedBox(height: 12),
                            _buildCreateEmployeeButton(),
                            const SizedBox(height: 16),
                            ..._filteredEmployees.map(_buildEmployeeCard),
                            if (_filteredEmployees.isEmpty) _buildEmptyState(),
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

  void _onDrawerItemTap(int index) {
    if (index == 0) {
      navigateToMainTab(context, 0);
    } else if (index == 3) {
      navigateToMainTab(context, 2);
    } else if (index == 4) {
      navigateToMainTab(context, 3);
    } else if (index == 5) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ItemsScreen()),
      );
    } else if (index == 6) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StoreScreen()),
      );
    }
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: const AppLogo(size: 38),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Employee List',
            style: GoogleFonts.poppins(
              color: AppColors.headingBlack,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.iconBgGray,
              border: Border.all(color: AppColors.borderGray),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  void _openCreateEmployee() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
    );
  }

  Widget _buildCreateEmployeeButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _openCreateEmployee,
        icon: const Icon(Icons.person_add_outlined, size: 20),
        label: Text(
          'Create Employee',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.poppins(
        color: AppColors.textDark,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Search employees by name, role or ID.',
        hintStyle: GoogleFonts.poppins(
          color: AppColors.inputHint,
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
          size: 22,
        ),
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterSortRow() {
    return Row(
      children: [
        Expanded(child: _buildActionButton(
          icon: Icons.filter_list_rounded,
          label: 'Filter',
          onTap: _showFilterSheet,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton(
          icon: Icons.sort_rounded,
          label: 'Sort',
          onTap: _showSortSheet,
        )),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.borderGray.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.textDark),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(employee),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.name,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.headingBlack,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  employee.role,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(employee.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildMetaRow(
                        icon: Icons.badge_outlined,
                        label: employee.id,
                      ),
                      const SizedBox(height: 6),
                      _buildMetaRow(
                        icon: Icons.apartment_outlined,
                        label: employee.site,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderGray.withValues(alpha: 0.4),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Profile',
                          style: GoogleFonts.poppins(
                            color: AppColors.primaryRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.primaryRed,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showEmployeeMenu(employee),
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Employee employee) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryRed, width: 1.5),
        color: AppColors.primaryRed.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Text(
          employee.initials,
          style: GoogleFonts.poppins(
            color: AppColors.primaryRed,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(EmployeeStatus status) {
    final isActive = status == EmployeeStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: GoogleFonts.poppins(
          color: AppColors.primaryRed,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMetaRow({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No employees found',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingBlack,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SITE',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip('All', _siteFilter == null, () {
                    setState(() => _siteFilter = null);
                    Navigator.pop(context);
                  }),
                  ..._sites.map((site) => _filterChip(site, _siteFilter == site, () {
                    setState(() => _siteFilter = site);
                    Navigator.pop(context);
                  })),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'STATUS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _filterChip('All', _statusFilter == null, () {
                    setState(() => _statusFilter = null);
                    Navigator.pop(context);
                  }),
                  _filterChip('Active', _statusFilter == EmployeeStatus.active, () {
                    setState(() => _statusFilter = EmployeeStatus.active);
                    Navigator.pop(context);
                  }),
                  _filterChip('Inactive', _statusFilter == EmployeeStatus.inactive, () {
                    setState(() => _statusFilter = EmployeeStatus.inactive);
                    Navigator.pop(context);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: selected ? AppColors.primaryRed : AppColors.textDark,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryRed,
      side: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sort by',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingBlack,
                ),
              ),
              const SizedBox(height: 8),
              _sortTile('Name (A–Z)', _SortOption.nameAsc),
              _sortTile('Name (Z–A)', _SortOption.nameDesc),
              _sortTile('Employee ID', _SortOption.idAsc),
            ],
          ),
        );
      },
    );
  }

  Widget _sortTile(String label, _SortOption option) {
    final selected = _sortOption == option;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: selected ? AppColors.primaryRed : AppColors.textDark,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primaryRed, size: 20)
          : null,
      onTap: () {
        setState(() => _sortOption = option);
        Navigator.pop(context);
      },
    );
  }

  void _showEmployeeMenu(Employee employee) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.textDark),
                title: Text('View Profile', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.textDark),
                title: Text('Edit Employee', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEmployeeScreen(employee: employee),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_note_outlined, color: AppColors.textDark),
                title: Text('View Attendance', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
