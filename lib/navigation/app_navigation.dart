import 'package:flutter/material.dart';
import 'package:grjoffice_apps/main_shell.dart';
import 'package:grjoffice_apps/widgets/app_bottom_nav.dart';

/// Switches tab when already inside [MainShell], otherwise opens [MainShell].
void navigateToMainTab(BuildContext context, int index) {
  final shell = AppShellScope.maybeOf(context);
  if (shell != null) {
    shell.switchToTab(index);
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => MainShell(initialIndex: index)),
    (route) => false,
  );
}
