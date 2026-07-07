import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

/// Provides tab-switching from child screens inside [MainShell].
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.currentIndex,
    required this.switchToTab,
    required this.shellNavigatorKey,
    required super.child,
  });

  final int currentIndex;
  final ValueChanged<int> switchToTab;
  final GlobalKey<NavigatorState> shellNavigatorKey;

  static AppShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  static AppShellScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'AppShellScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) {
    return oldWidget.currentIndex != currentIndex ||
        oldWidget.shellNavigatorKey != shellNavigatorKey;
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static const items = [
    _NavItem(Icons.grid_view_rounded, 'Dashboard'),
    _NavItem(Icons.chat_bubble_outline_rounded, 'Chats'),
    _NavItem(Icons.shopping_cart_outlined, 'Purchase'),
    _NavItem(Icons.storefront_outlined, 'Store'),
    _NavItem(Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(top: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex >= 0 && selectedIndex == index;
              return GestureDetector(
                onTap: () {
                  if (index != selectedIndex) onTabSelected(index);
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryRed : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: isSelected ? AppColors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        color: isSelected ? AppColors.primaryRed : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
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

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
