import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
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

class AppBottomNav extends StatefulWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static const convexCenterIndex = 2;

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> with SingleTickerProviderStateMixin {
  static const _tabCount = 5;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: widget.selectedIndex.clamp(0, _tabCount - 1),
    );
  }

  @override
  void didUpdateWidget(covariant AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        _tabController.index != widget.selectedIndex) {
      _tabController.animateTo(widget.selectedIndex.clamp(0, _tabCount - 1));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TabItem> _tabItems(double width) {
    final showLabels = width >= 400;
    String label(String text) => showLabels ? text : '';

    return [
      TabItem(
        icon: Icons.grid_view_rounded,
        activeIcon: Icons.grid_view,
        title: label('Dashboard'),
      ),
      TabItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        title: label('Chats'),
      ),
      TabItem(
        icon: Icons.shopping_cart_outlined,
        activeIcon: Icons.shopping_cart,
        title: label('Purchase'),
      ),
      TabItem(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        title: label('Store'),
      ),
      TabItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        title: label('Profile'),
      ),
    ];
  }

  _BarMetrics _metrics(double width) {
    if (width < 340) {
      return const _BarMetrics(
        height: 62,
        curveSize: 74,
        top: -30,
        cornerRadius: 22,
      );
    }
    if (width < 600) {
      return const _BarMetrics(
        height: 66,
        curveSize: 82,
        top: -32,
        cornerRadius: 24,
      );
    }
    return const _BarMetrics(
      height: 70,
      curveSize: 88,
      top: -34,
      cornerRadius: 26,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final metrics = _metrics(width);

    return ConvexAppBar(
      style: TabStyle.fixedCircle,
      items: _tabItems(width),
      controller: _tabController,
      disableDefaultTabController: true,
      chipBuilder: _PremiumNavChipBuilder(showLabels: width >= 400),
      onTap: widget.onTabSelected,
      backgroundColor: AppColors.cardWhite,
      color: AppColors.textSecondary,
      activeColor: AppColors.primaryRed,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF5F6F8),
        ],
      ),
      shadowColor: Colors.black.withValues(alpha: 0.14),
      elevation: 10,
      cornerRadius: metrics.cornerRadius,
      height: metrics.height,
      curveSize: metrics.curveSize,
      top: metrics.top,
      curve: Curves.easeOutCubic,
    );
  }
}

class _PremiumNavChipBuilder extends ChipBuilder {
  _PremiumNavChipBuilder({required this.showLabels});

  final bool showLabels;

  @override
  Widget build(BuildContext context, Widget child, int index, bool active) {
    if (index == AppBottomNav.convexCenterIndex) {
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: active ? 0.32 : 0.12),
              blurRadius: active ? 16 : 10,
              offset: Offset(0, active ? 6 : 4),
            ),
          ],
        ),
        child: child,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : 48,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: active ? 10 : 6,
                vertical: showLabels ? 2 : 0,
              ),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primaryRed.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _BarMetrics {
  const _BarMetrics({
    required this.height,
    required this.curveSize,
    required this.top,
    required this.cornerRadius,
  });

  final double height;
  final double curveSize;
  final double top;
  final double cornerRadius;
}
