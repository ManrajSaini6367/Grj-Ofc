import 'package:flutter/material.dart';
import 'package:grjoffice_apps/chatscreen/chatscreen.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchases.dart';
import 'package:grjoffice_apps/dashboardscreen/homepage.dart';
import 'package:grjoffice_apps/profilescreen/profilescreen.dart';
import 'package:grjoffice_apps/Storescreens/store.dart';
import 'package:grjoffice_apps/widgets/app_bottom_nav.dart';

/// Root shell with a single persistent bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0, this.initialPush});

  final int initialIndex;
  final Widget? initialPush;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex = widget.initialIndex;
  final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();
  late final NavigatorObserver _shellRouteObserver = _ShellRouteObserver(() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  });

  bool get _showDashboardFab {
    if (_selectedIndex != 0) return false;
    final nav = _shellNavigatorKey.currentState;
    return nav == null || !nav.canPop();
  }

  @override
  void initState() {
    super.initState();
    final initialPush = widget.initialPush;
    if (initialPush != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shellNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => initialPush),
        );
      });
    }
  }

  void _switchTab(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _onTabSelected(int index) {
    _shellNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    _switchTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScope(
      currentIndex: _selectedIndex,
      switchToTab: _switchTab,
      shellNavigatorKey: _shellNavigatorKey,
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray,
        body: Navigator(
          key: _shellNavigatorKey,
          observers: [_shellRouteObserver],
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const _ShellTabStack(),
            );
          },
        ),
        bottomNavigationBar: AppBottomNav(
          selectedIndex: _selectedIndex,
          onTabSelected: _onTabSelected,
        ),
        floatingActionButton: _showDashboardFab ? _buildDashboardFab() : null,
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

class _ShellRouteObserver extends NavigatorObserver {
  _ShellRouteObserver(this.onChanged);

  final VoidCallback onChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => onChanged();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => onChanged();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => onChanged();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => onChanged();
}

class _ShellTabStack extends StatelessWidget {
  const _ShellTabStack();

  @override
  Widget build(BuildContext context) {
    final index = AppShellScope.of(context).currentIndex;
    return IndexedStack(
      index: index,
      sizing: StackFit.expand,
      children: [
        const HomePage(),
        const ChatScreen(),
        const PurchasesScreen(),
        const StoreScreen(),
        ProfileScreen(isActive: index == 4),
      ],
    );
  }
}
