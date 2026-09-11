import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/services/user_session.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.selectedIndex = 0, this.onItemTap});

  final int selectedIndex;
  final ValueChanged<int>? onItemTap;

  /// Each item keeps a fixed [DrawerIndex] so navigation stays correct
  /// even when some rows are hidden by RBAC.
  static const _menuItems = <_DrawerMenuItem>[
    _DrawerMenuItem(
      DrawerIndex.dashboard,
      Icons.grid_view_rounded,
      'Dashboard',
      // Always visible when logged in.
      anyOf: [],
    ),
    _DrawerMenuItem(
      DrawerIndex.employees,
      Icons.badge_outlined,
      'Employee List',
      anyOf: [AppPermissions.usersView, AppPermissions.usersCreate],
    ),
    _DrawerMenuItem(
      DrawerIndex.dayEndReport,
      Icons.event_note_outlined,
      'Day End Report',
      anyOf: [AppPermissions.viewDayReport],
    ),
    _DrawerMenuItem(
      DrawerIndex.suppliers,
      Icons.inventory_2_outlined,
      'Supplier List',
      anyOf: [AppPermissions.suppliersView],
    ),
    _DrawerMenuItem(
      DrawerIndex.labourContractors,
      Icons.groups_outlined,
      'Amani Labour',
      anyOf: [AppPermissions.contractorsView],
    ),
    _DrawerMenuItem(
      DrawerIndex.originalContractors,
      Icons.engineering_outlined,
      'Peti Contractor',
      anyOf: [],
    ),
    _DrawerMenuItem(
      DrawerIndex.items,
      Icons.category_outlined,
      'Items',
      anyOf: [AppPermissions.itemsView],
    ),
    _DrawerMenuItem(
      DrawerIndex.store,
      Icons.storefront_outlined,
      'Store',
      anyOf: [AppPermissions.itemsView],
    ),
    _DrawerMenuItem(
      DrawerIndex.inwardOutward,
      Icons.swap_horiz_outlined,
      'Inward / Outward',
      anyOf: [AppPermissions.itemsView],
    ),
    _DrawerMenuItem(
      DrawerIndex.outwardRequests,
      Icons.assignment_turned_in_outlined,
      'Outward Requests',
      anyOf: [AppPermissions.itemsView],
    ),
    _DrawerMenuItem(
      DrawerIndex.expenses,
      Icons.account_balance_wallet_outlined,
      'Expenses',
      anyOf: [AppPermissions.expensesCreate, AppPermissions.expensesReport],
    ),
    _DrawerMenuItem(
      DrawerIndex.tasks,
      Icons.task_alt_outlined,
      'Task',
      anyOf: [
        AppPermissions.tasks1View,
        AppPermissions.tasksCreate,
        AppPermissions.tasks1Create,
        AppPermissions.tasksUpdate,
      ],
    ),
    _DrawerMenuItem(
      DrawerIndex.purchase,
      Icons.shopping_cart_outlined,
      'Purchase',
      anyOf: [
        AppPermissions.purchasesView,
        AppPermissions.purchasesCreate,
        AppPermissions.purchasesViewAll,
      ],
    ),
    _DrawerMenuItem(
      DrawerIndex.myAttendance,
      Icons.calendar_month_outlined,
      'Attendance',
      anyOf: [],
    ),
    _DrawerMenuItem(
      DrawerIndex.employeeAttendances,
      Icons.how_to_reg_outlined,
      'Employee Attendances',
      anyOf: [
        AppPermissions.employerAttendancesView,
        AppPermissions.employerAttendancesCreate,
        AppPermissions.viewAttendances,
      ],
    ),
    _DrawerMenuItem(
      DrawerIndex.payout,
      Icons.payments_outlined,
      'Payout',
      anyOf: [
        AppPermissions.payoutsView,
        AppPermissions.payoutsCreate,
        AppPermissions.usersView,
        AppPermissions.usersCreate,
      ],
    ),
    _DrawerMenuItem(
      DrawerIndex.contractorAttendances,
      Icons.people_outline,
      'Contractor Attendances',
      anyOf: [
        AppPermissions.labourAttendancesView,
        AppPermissions.labourAttendancesCreate,
        AppPermissions.labourAttendancesReport,
      ],
    ),
    // _DrawerMenuItem(
    //   DrawerIndex.roles,
    //   Icons.admin_panel_settings_outlined,
    //   'Roles',
    //   anyOf: [
    //     AppPermissions.usersView,
    //     AppPermissions.usersCreate,
    //     AppPermissions.usersBlock,
    //   ],
    // ),
    _DrawerMenuItem(
      DrawerIndex.report,
      Icons.assessment_outlined,
      'Report',
      anyOf: [
        AppPermissions.viewMainReport,
        AppPermissions.viewMainExcelReport,
        AppPermissions.viewChallanReport,
        AppPermissions.expensesReport,
        AppPermissions.viewDayReport,
        AppPermissions.labourAttendancesReport,
        AppPermissions.employerAttendancesReport,
      ],
    ),
    _DrawerMenuItem(
      DrawerIndex.leave,
      Icons.event_available_outlined,
      'Leave',
      anyOf: [],
    ),
    _DrawerMenuItem(
      DrawerIndex.leaveRequests,
      Icons.assignment_outlined,
      'Leave Requests',
      anyOf: [],
    ),
    // _DrawerMenuItem(
    //   DrawerIndex.kycVerification,
    //   Icons.verified_user_outlined,
    //   'KYC Verification',
    //   anyOf: [],
    // ),
    // _DrawerMenuItem(
    //   DrawerIndex.kycRequests,
    //   Icons.assignment_turned_in_outlined,
    //   'KYC Requests',
    //   anyOf: [],
    // ),
    _DrawerMenuItem(
      DrawerIndex.employeeKyc,
      Icons.badge_outlined,
      'Employee KYC',
      anyOf: [],
    ),
    _DrawerMenuItem(
      DrawerIndex.employeeKycRequests,
      Icons.fact_check_outlined,
      'Employee KYC Requests',
      anyOf: [],
    ),
  ];

  List<_DrawerMenuItem> get _visibleItems {
    final perms = PermissionService.instance;
    return _menuItems.where((item) {
      if (item.anyOf.isEmpty) return true;
      return perms.canAny(item.anyOf);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = (screenWidth * 0.72).clamp(240.0, 300.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: AppColors.cardWhite,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            PermissionService.instance,
            UserSession.instance,
          ]),
          builder: (context, _) {
            final visible = _visibleItems;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Divider(
                  height: 1,
                  color: AppColors.borderGray.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      final isSelected = selectedIndex == item.drawerIndex;
                      return _buildMenuItem(
                        context: context,
                        item: item,
                        isSelected: isSelected,
                        onTap: () {
                          Navigator.of(context).pop();
                          onItemTap?.call(item.drawerIndex);
                        },
                      );
                    },
                  ),
                ),
                _buildFooter(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const AppLogo(size: 36, showBorder: true),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Back Office Portal',
              style: GoogleFonts.poppins(
                color: AppColors.headingBlack,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required _DrawerMenuItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8, bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(24),
          ),
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryRed.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: isSelected
                        ? AppColors.primaryRed
                        : AppColors.headingBlack,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        color: isSelected
                            ? AppColors.primaryRed
                            : AppColors.headingBlack,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isSelected
                        ? AppColors.primaryRed
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final user = UserSession.instance.user ?? cachedUser();
    final name = user?.name ?? Preference.pref.getString('name') ?? 'User';
    final department = user?.designation?.trim().isNotEmpty == true
        ? user!.designation!.trim()
        : (user?.roleLabel ?? 'User');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.iconBgGray,
                child: Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: AppColors.headingBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      department,
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              Navigator.of(context).pop();
              await logoutApi(context);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: AppColors.primaryRed,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Sign Out',
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryRed,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem {
  const _DrawerMenuItem(
    this.drawerIndex,
    this.icon,
    this.title, {
    required this.anyOf,
  });

  final int drawerIndex;
  final IconData icon;
  final String title;

  /// Empty = always show. Otherwise user must have at least one.
  final List<String> anyOf;
}
