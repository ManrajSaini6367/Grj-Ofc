import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grjoffice_apps/chatscreen/chatscreen.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchases.dart';
import 'package:grjoffice_apps/dashboardscreen/homepage.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/profilescreen/profilescreen.dart';
import 'package:grjoffice_apps/Storescreens/store.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/attendance_service.dart';
import 'package:grjoffice_apps/services/punch_in_gate.dart';
import 'package:grjoffice_apps/services/user_session.dart';
import 'package:grjoffice_apps/utils/app_helpers.dart';
import 'package:grjoffice_apps/widgets/app_bottom_nav.dart';

/// Root shell with a single persistent bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0, this.initialPush});

  final int initialIndex;
  final Widget? initialPush;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  late int _selectedIndex;
  final List<int> _tabVersions = List<int>.filled(5, 0);
  final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();
  final AttendanceService _attendance = AttendanceService.instance;
  Timer? _permissionPollTimer;

  int get _activeTabVersion => _tabVersions[_selectedIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _selectedIndex = AppBottomNav.canAccessTab(widget.initialIndex)
        ? widget.initialIndex
        : AppBottomNav.firstAllowedTab();

    if (PunchInGate.isRequired && !PunchInGate.canAccessApp) {
      _selectedIndex = MainTab.dashboard;
    }

    PermissionService.instance.addListener(_onPermissionsChanged);
    _attendance.addListener(_onAttendanceChanged);

    // Hydrate session from cache, then sync latest permissions.
    final cached = cachedUser();
    if (cached != null) {
      UserSession.instance.setUser(cached);
    }
    unawaited(PermissionService.instance.refresh());
    _permissionPollTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => unawaited(PermissionService.instance.refreshIfStale()),
    );

    final initialPush = widget.initialPush;
    if (initialPush != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shellNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => initialPush),
        );
      });
    }
  }

  @override
  void dispose() {
    _permissionPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    PermissionService.instance.removeListener(_onPermissionsChanged);
    _attendance.removeListener(_onAttendanceChanged);
    super.dispose();
  }

  void _onAttendanceChanged() {
    if (!mounted) return;
    if (PunchInGate.isRequired && !PunchInGate.canAccessApp) {
      _shellNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      if (_selectedIndex != MainTab.dashboard) {
        _activateTab(MainTab.dashboard, reload: true);
      }
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(PermissionService.instance.refresh());
    }
  }

  void _onPermissionsChanged() {
    if (!mounted) return;
    if (AppBottomNav.canAccessTab(_selectedIndex)) return;
    final fallback = AppBottomNav.firstAllowedTab();
    if (fallback != _selectedIndex) {
      _activateTab(fallback, reload: false);
    }
  }

  void _activateTab(int index, {bool reload = true}) {
    setState(() {
      _selectedIndex = index;
      if (reload) _tabVersions[index]++;
    });
  }

  void _switchTab(int index) {
    if (index != MainTab.dashboard && !PunchInGate.ensureAccess(context)) {
      return;
    }
    if (!AppBottomNav.canAccessTab(index)) {
      message(context, 'You do not have permission to access this');
      return;
    }
    if (_selectedIndex == index) return;
    _activateTab(index);
  }

  void _onTabSelected(int index) {
    if (index != MainTab.dashboard && !PunchInGate.ensureAccess(context)) {
      return;
    }
    if (!AppBottomNav.canAccessTab(index)) {
      message(context, 'You do not have permission to access this');
      return;
    }
    // Soft refresh when switching tabs so role changes apply quickly.
    unawaited(PermissionService.instance.refreshIfStale());
    _shellNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    _activateTab(index);
  }

  Future<void> _handleSystemBack() async {
    final nav = _shellNavigatorKey.currentState;
    if (nav == null) {
      SystemNavigator.pop();
      return;
    }
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
        MainTab.dashboard => const HomePage(),
        MainTab.chats => const ChatScreen(),
        MainTab.purchase => const PurchasesScreen(),
        MainTab.store => const StoreScreen(),
        _ => const ProfileScreen(isActive: true),
      },
    );
  }
}
