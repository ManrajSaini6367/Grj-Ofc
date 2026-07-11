import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final List<int> _tabVersions = List<int>.filled(5, 0);
  final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  int get _activeTabVersion => _tabVersions[_selectedIndex];

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

  void _activateTab(int index, {bool reload = true}) {
    setState(() {
      _selectedIndex = index;
      if (reload) _tabVersions[index]++;
    });
  }

  void _switchTab(int index) {
    if (_selectedIndex == index) return;
    _activateTab(index);
  }

  void _onTabSelected(int index) {
    _shellNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    _activateTab(index);
  }

  Future<void> _handleSystemBack() async {
    final nav = _shellNavigatorKey.currentState;
    if (nav == null) {
      SystemNavigator.pop();
      return;
    }
    // Shell has a pushed screen — maybePop respects that screen's PopScope
    // (e.g. Add Purchase step back) and will not exit the app.
    if (nav.canPop()) {
      await nav.maybePop();
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScope(
      currentIndex: _selectedIndex,
      tabVersion: _activeTabVersion,
      switchToTab: _switchTab,
      shellNavigatorKey: _shellNavigatorKey,
      child: PopScope(
        // Always intercept; live nav.canPop() is checked in _handleSystemBack.
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleSystemBack();
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundGray,
          body: Navigator(
            key: _shellNavigatorKey,
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
        ),
      ),
    );
  }
}

class _ShellTabStack extends StatelessWidget {
  const _ShellTabStack();

  @override
  Widget build(BuildContext context) {
    final scope = AppShellScope.of(context);
    final index = scope.currentIndex;

    return KeyedSubtree(
      key: ValueKey('shell-tab-$index-${scope.tabVersion}'),
      child: switch (index) {
        0 => const HomePage(),
        1 => const ChatScreen(),
        2 => const PurchasesScreen(),
        3 => const StoreScreen(),
        _ => const ProfileScreen(isActive: true),
      },
    );
  }
}
