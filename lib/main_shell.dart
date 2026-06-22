import 'package:flutter/material.dart';
import 'package:grjoffice_apps/contractors/contractors.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/employees/employees.dart';
import 'package:grjoffice_apps/homepage/homepage.dart';
import 'package:grjoffice_apps/profilescreen/profilescreen.dart';
import 'package:grjoffice_apps/suppliers/suppliers.dart';
import 'package:grjoffice_apps/widgets/app_bottom_nav.dart';

/// Root shell with a single persistent bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex = widget.initialIndex;

  void _switchTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScope(
      currentIndex: _selectedIndex,
      switchToTab: _switchTab,
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray,
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            HomePage(),
            EmployeesScreen(),
            SuppliersScreen(),
            ContractorsScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          selectedIndex: _selectedIndex,
          onTabSelected: _switchTab,
        ),
        floatingActionButton: _selectedIndex == 0 ? _buildDashboardFab() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildDashboardFab() {
    return Material(
      color: AppColors.primaryRed,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.add, color: AppColors.white, size: 28),
        ),
      ),
    );
  }
}
