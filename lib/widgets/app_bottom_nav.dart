import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/permission_service.dart';

/// Provides tab-switching from child screens inside [MainShell].
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.currentIndex,
    required this.tabVersion,
    required this.switchToTab,
    required this.shellNavigatorKey,
    required super.child,
  });

  final int currentIndex;

  /// Bumps on every bottom-tab tap so the active tab remounts and reloads.
  final int tabVersion;
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
        oldWidget.tabVersion != tabVersion ||
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

  static const _centerButtonSize = 58.0;
  static const _centerLift = 22.0;

  static const _allItems = <_NavItem>[
    _NavItem(
      MainTab.dashboard,
      Icons.grid_view_rounded,
      Icons.grid_view,
      'Dashboard',
      anyOf: [],
    ),
    _NavItem(
      MainTab.chats,
      Icons.chat_bubble_outline_rounded,
      Icons.chat_bubble_rounded,
      'Chats',
      anyOf: [],
    ),
    _NavItem(
      MainTab.purchase,
      Icons.shopping_cart_outlined,
      Icons.shopping_cart,
      'Purchase',
      anyOf: [
        AppPermissions.purchasesView,
        AppPermissions.purchasesCreate,
        AppPermissions.purchasesViewAll,
      ],
      isCenter: true,
    ),
    _NavItem(
      MainTab.store,
      Icons.storefront_outlined,
      Icons.storefront,
      'Store',
      anyOf: [
        AppPermissions.itemsView,
        AppPermissions.itemsCreate,
      ],
    ),
    _NavItem(
      MainTab.profile,
      Icons.person_outline,
      Icons.person,
      'Profile',
      anyOf: [],
    ),
  ];

  /// Whether the given [MainTab] index is allowed for the current user.
  static bool canAccessTab(int tabIndex) {
    final item = _allItems.cast<_NavItem?>().firstWhere(
          (e) => e!.tabIndex == tabIndex,
          orElse: () => null,
        );
    if (item == null) return false;
    if (item.anyOf.isEmpty) return true;
    return PermissionService.instance.canAny(item.anyOf);
  }

  /// First allowed tab (fallback = Dashboard).
  static int firstAllowedTab() {
    for (final item in _allItems) {
      if (item.anyOf.isEmpty ||
          PermissionService.instance.canAny(item.anyOf)) {
        return item.tabIndex;
      }
    }
    return MainTab.dashboard;
  }

  List<_NavItem> get _visibleItems {
    final perms = PermissionService.instance;
    return _allItems.where((item) {
      if (item.anyOf.isEmpty) return true;
      return perms.canAny(item.anyOf);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PermissionService.instance,
      builder: (context, _) {
        final visible = _visibleItems;
        final purchaseVisible =
            visible.any((e) => e.tabIndex == MainTab.purchase);

        if (purchaseVisible) {
          return _buildWithCenterPurchase(context, visible);
        }
        return _buildEqualTabs(context, visible);
      },
    );
  }

  Widget _buildWithCenterPurchase(
    BuildContext context,
    List<_NavItem> visible,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final showLabels = width >= 360;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barHeight = showLabels ? 64.0 : 58.0;
    final sideItems =
        visible.where((e) => e.tabIndex != MainTab.purchase).toList();
    final purchaseItem =
        visible.firstWhere((e) => e.tabIndex == MainTab.purchase);

    // Keep left/right balance: dashboard+chats | purchase | store+profile
    // When some sides are missing, still distribute evenly.
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
              decoration: _barDecoration,
              padding: EdgeInsets.only(
                bottom: bottomInset > 0 ? bottomInset : 8,
                top: 8,
              ),
              child: Row(
                children: [
                  for (final item in sideItems.take((sideItems.length + 1) ~/ 2))
                    Expanded(
                      child: _SideTabButton(
                        item: item,
                        selected: selectedIndex == item.tabIndex,
                        showLabel: showLabels,
                        onTap: () => onTabSelected(item.tabIndex),
                      ),
                    ),
                  const Expanded(child: SizedBox.shrink()),
                  for (final item in sideItems.skip((sideItems.length + 1) ~/ 2))
                    Expanded(
                      child: _SideTabButton(
                        item: item,
                        selected: selectedIndex == item.tabIndex,
                        showLabel: showLabels,
                        onTap: () => onTabSelected(item.tabIndex),
                      ),
                    ),
                ],
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
                onTap: () => onTabSelected(purchaseItem.tabIndex),
                child: _CenterTab(
                  item: purchaseItem,
                  selected: selectedIndex == purchaseItem.tabIndex,
                  showLabel: showLabels,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualTabs(BuildContext context, List<_NavItem> visible) {
    final width = MediaQuery.sizeOf(context).width;
    final showLabels = width >= 360;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barHeight = showLabels ? 64.0 : 58.0;

    return SizedBox(
      height: barHeight + bottomInset,
      child: Container(
        decoration: _barDecoration,
        padding: EdgeInsets.only(
          bottom: bottomInset > 0 ? bottomInset : 8,
          top: 8,
        ),
        child: Row(
          children: [
            for (final item in visible)
              Expanded(
                child: _SideTabButton(
                  item: item,
                  selected: selectedIndex == item.tabIndex,
                  showLabel: showLabels,
                  onTap: () => onTabSelected(item.tabIndex),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static final _barDecoration = BoxDecoration(
    color: AppColors.cardWhite,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, -4),
      ),
    ],
  );
}

class _SideTabButton extends StatelessWidget {
  const _SideTabButton({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _SideTab(
        item: item,
        selected: selected,
        showLabel: showLabel,
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
                color: AppColors.primaryRed
                    .withValues(alpha: selected ? 0.38 : 0.22),
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
              color:
                  selected ? AppColors.primaryRed : AppColors.textSecondary,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}

class _NavItem {
  const _NavItem(
    this.tabIndex,
    this.icon,
    this.activeIcon,
    this.label, {
    required this.anyOf,
    this.isCenter = false,
  });

  final int tabIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Empty = always visible.
  final List<String> anyOf;
  final bool isCenter;
}
