import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:grjoffice_apps/core/safe_change_notifier.dart';
import 'package:permission_handler/permission_handler.dart';

/// Watches real internet reachability and blocks the app when offline.
class ConnectivityService extends SafeChangeNotifier
    with WidgetsBindingObserver {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  static const _settingsChannel = MethodChannel('grjoffice_apps/settings');

  bool _started = false;
  bool _online = true;
  bool _checked = false;

  bool get isOnline => _online;
  bool get hasChecked => _checked;
  bool get isOffline => _checked && !_online;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(checkNow());
    Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(checkNow()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(checkNow());
    }
  }

  Future<bool> checkNow() async {
    final reachable = await _lookupInternet();
    final changed = !_checked || _online != reachable;
    _checked = true;
    _online = reachable;
    if (changed) notifyListeners();
    return _online;
  }

  Future<void> waitUntilOnline() async {
    if (_checked && _online) return;
    await checkNow();
    if (_online) return;

    final done = Completer<void>();
    void listener() {
      if (_online && !done.isCompleted) done.complete();
    }

    addListener(listener);
    try {
      if (_online) return;
      await done.future;
    } finally {
      removeListener(listener);
    }
  }

  Future<void> openInternetSettings() async {
    if (Platform.isAndroid) {
      try {
        await _settingsChannel.invokeMethod<void>('openWirelessSettings');
        return;
      } catch (_) {}
    }
    await openAppSettings();
  }

  Future<void> closeApp() async {
    await SystemNavigator.pop();
    if (Platform.isIOS) {
      exit(0);
    }
  }

  Future<bool> _lookupInternet() async {
    for (final host in const ['one.one.one.one', 'dns.google']) {
      try {
        final result = await InternetAddress.lookup(host).timeout(
          const Duration(seconds: 4),
        );
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }
}
