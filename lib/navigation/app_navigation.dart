import 'package:flutter/material.dart';
import 'package:grjoffice_apps/Itemsscreen/items.dart';
import 'package:grjoffice_apps/main_shell.dart';
import 'package:grjoffice_apps/Purchasescreen/purchases.dart';
import 'package:grjoffice_apps/Storescreens/store.dart';
import 'package:grjoffice_apps/widgets/app_bottom_nav.dart';

/// Switches tab when already inside [MainShell], otherwise opens [MainShell].
void navigateToMainTab(BuildContext context, int index) {
  final shell = AppShellScope.maybeOf(context);
  if (shell != null) {
    shell.shellNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    if (shell.currentIndex != index) {
      shell.switchToTab(index);
    }
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => MainShell(initialIndex: index)),
    (route) => false,
  );
}

/// Pushes a secondary screen above the tab stack while keeping the bottom bar visible.
void pushInShell(BuildContext context, Widget screen) {
  final shell = AppShellScope.maybeOf(context);
  if (shell != null) {
    final nav = shell.shellNavigatorKey.currentState;
    nav?.popUntil((route) => route.isFirst);
    nav?.push(MaterialPageRoute(builder: (_) => screen));
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => MainShell(initialPush: screen)),
    (route) => false,
  );
}

/// Handles [AppDrawer] menu taps consistently while keeping the bottom bar visible.
void navigateFromDrawer(BuildContext context, int drawerIndex) {
  switch (drawerIndex) {
    case 0:
      navigateToMainTab(context, 0);
    case 1:
      navigateToMainTab(context, 1);
    case 3:
      navigateToMainTab(context, 2);
    case 4:
      navigateToMainTab(context, 3);
    case 5:
      pushInShell(context, const ItemsScreen());
    case 6:
      pushInShell(context, const StoreScreen());
    case 9:
      pushInShell(context, const PurchasesScreen());
    default:
      break;
  }
}
