import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    this.selectedIndex = 0,
    this.onItemTap,
  });

  final int selectedIndex;
  final ValueChanged<int>? onItemTap;

  static const _menuItems = [
    _DrawerMenuItem(Icons.grid_view_rounded, 'Dashboard'),
    _DrawerMenuItem(Icons.badge_outlined, 'Employee List'),
    _DrawerMenuItem(Icons.event_note_outlined, 'Day End Report'),
    _DrawerMenuItem(Icons.inventory_2_outlined, 'Supplier List'),
    _DrawerMenuItem(Icons.groups_outlined, 'Labour Contractor'),
    _DrawerMenuItem(Icons.category_outlined, 'Items'),
    _DrawerMenuItem(Icons.storefront_outlined, 'Store'),
    _DrawerMenuItem(Icons.account_balance_wallet_outlined, 'Expenses'),
    _DrawerMenuItem(Icons.task_alt_outlined, 'Task'),
    _DrawerMenuItem(Icons.shopping_cart_outlined, 'Purchase'),
    _DrawerMenuItem(Icons.how_to_reg_outlined, 'Employee Attendances'),
    _DrawerMenuItem(Icons.people_outline, 'Contractor Attendances'),
    _DrawerMenuItem(Icons.admin_panel_settings_outlined, 'Roles'),
    _DrawerMenuItem(Icons.assessment_outlined, 'Report'),
  ];

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Divider(height: 1, color: AppColors.borderGray.withValues(alpha: 0.5)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isSelected = selectedIndex == index;
                  return _buildMenuItem(
                    context: context,
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                      Navigator.of(context).pop();
                      onItemTap?.call(index);
                    },
                  );
                },
              ),
            ),
            _buildFooter(context),
          ],
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
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryRed.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: isSelected ? AppColors.primaryRed : AppColors.headingBlack,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        color: isSelected ? AppColors.primaryRed : AppColors.headingBlack,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isSelected ? AppColors.primaryRed : AppColors.textSecondary,
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
    final user = cachedUser();
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
                child: Icon(Icons.person, color: AppColors.textSecondary, size: 26),
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
                  Icon(Icons.logout_rounded, color: AppColors.primaryRed, size: 22),
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
  const _DrawerMenuItem(this.icon, this.title);

  final IconData icon;
  final String title;
}
