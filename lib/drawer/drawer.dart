import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/loginpage/loginpage.dart';

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
    _DrawerMenuItem(Icons.badge_outlined, 'Employees'),
    _DrawerMenuItem(Icons.event_note_outlined, 'Day End Report'),
    _DrawerMenuItem(Icons.inventory_2_outlined, 'Supplier'),
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
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.82;

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
                      onItemTap?.call(index);
                      Navigator.of(context).pop();
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryRed, width: 2),
              color: AppColors.cardWhite,
            ),
            child: Center(
              child: Text(
                'GRJ',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryRed,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
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
                      'Gulshan Rai Jain',
                      style: GoogleFonts.poppins(
                        color: AppColors.headingBlack,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Director',
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
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
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
