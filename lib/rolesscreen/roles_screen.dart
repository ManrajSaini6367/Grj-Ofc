import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
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

  List<_RoleItem> get _filtered {
    if (_query.isEmpty) return _kRoles;
    return _kRoles
        .where((r) =>
            r.name.toLowerCase().contains(_query) ||
            r.description.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final roles = _filtered;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.roles,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Roles',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search roles...',
                  hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.cardWhite,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: roles.isEmpty
                  ? Center(
                      child: Text(
                        'No roles found',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 20),
                      itemCount: roles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _roleCard(roles[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(_RoleItem role) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primaryRed, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                      ),
                    ),
                    Text(
                      '${role.usersCount} users',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: role.isActive
                      ? const Color(0xFF059669).withValues(alpha: 0.12)
                      : AppColors.textSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role.isActive ? 'Active' : 'Inactive',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: role.isActive ? const Color(0xFF059669) : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            role.description,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: role.permissions.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.operationsCardBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textDark),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RoleItem {
  const _RoleItem({
    required this.name,
    required this.description,
    required this.usersCount,
    required this.permissions,
    this.isActive = true,
  });

  final String name;
  final String description;
  final int usersCount;
  final List<String> permissions;
  final bool isActive;
}

const _kRoles = [
  _RoleItem(
    name: 'Admin',
    description: 'Full access to all modules, settings, and user management.',
    usersCount: 3,
    permissions: ['Users', 'Sites', 'Purchases', 'Reports', 'Roles'],
  ),
  _RoleItem(
    name: 'Site Manager',
    description: 'Manage site operations, attendance, store, and day-end reports.',
    usersCount: 8,
    permissions: ['Attendance', 'Store', 'Tasks', 'Day End Report'],
  ),
  _RoleItem(
    name: 'Purchase Officer',
    description: 'Create and track purchase requests and supplier coordination.',
    usersCount: 5,
    permissions: ['Purchases', 'Suppliers', 'Items'],
  ),
  _RoleItem(
    name: 'Accountant',
    description: 'View expenses and financial summaries for assigned sites.',
    usersCount: 4,
    permissions: ['Expenses', 'Reports'],
  ),
  _RoleItem(
    name: 'Viewer',
    description: 'Read-only access to dashboards and published reports.',
    usersCount: 12,
    permissions: ['Dashboard', 'Reports'],
    isActive: false,
  ),
];
