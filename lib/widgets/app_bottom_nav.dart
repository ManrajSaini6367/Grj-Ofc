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

  static const centerIndex = 2;
  static const _centerButtonSize = 58.0;
  static const _centerLift = 22.0;

  static const _items = <_NavItem>[
    _NavItem(Icons.grid_view_rounded, Icons.grid_view, 'Dashboard'),
    _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chats'),
    _NavItem(Icons.shopping_cart_outlined, Icons.shopping_cart, 'Purchase'),
    _NavItem(Icons.storefront_outlined, Icons.storefront, 'Store'),
    _NavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showLabels = width >= 360;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barHeight = showLabels ? 64.0 : 58.0;

    return SizedBox(
      height: barHeight + _centerLift + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: barHeight + bottomInset,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 8, top: 8),
              child: Row(
                children: List.generate(_items.length, (index) {
                  if (index == centerIndex) {
                    return const Expanded(child: SizedBox.shrink());
                  }

                  final item = _items[index];
                  final selected = selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTabSelected(index),
                      child: _SideTab(
                        item: item,
                        selected: selected,
                        showLabel: showLabels,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + (showLabels ? 10 : 14),
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTabSelected(centerIndex),
                child: _CenterTab(
                  item: _items[centerIndex],
                  selected: selectedIndex == centerIndex,
                  showLabel: showLabels,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideTab extends StatelessWidget {
  const _SideTab({
    required this.item,
    required this.selected,
    required this.showLabel,
  });

  final _NavItem item;
  final bool selected;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryRed : AppColors.textSecondary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 42,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryRed.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            selected ? item.activeIcon : item.icon,
            size: 22,
            color: color,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}

class _CenterTab extends StatelessWidget {
  const _CenterTab({
    required this.item,
    required this.selected,
    required this.showLabel,
  });

  final _NavItem item;
  final bool selected;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppBottomNav._centerButtonSize,
          height: AppBottomNav._centerButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFC62828),
                AppColors.primaryRed,
              ],
            ),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.primaryRed.withValues(alpha: selected ? 0.38 : 0.22),
                blurRadius: selected ? 16 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            selected ? item.activeIcon : item.icon,
            size: 26,
            color: Colors.white,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primaryRed : AppColors.textSecondary,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
