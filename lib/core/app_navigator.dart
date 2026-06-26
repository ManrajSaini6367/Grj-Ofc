import 'package:flutter/material.dart';

/// Root navigator key — use for navigation after drawer/dialog closes.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void navigateToScreenAndClearStack(Widget screen) {
  appNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => screen),
    (route) => false,
  );
}
