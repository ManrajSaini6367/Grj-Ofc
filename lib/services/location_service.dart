import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocationAccessStatus {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationAccessResult {
  const LocationAccessResult(this.status, this.message);

  final LocationAccessStatus status;
  final String message;

  bool get isReady => status == LocationAccessStatus.ready;
}

/// Handles location permissions and background position tracking via geolocator.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  static const _keyPermissionRequested = 'location_permission_requested';
  static const _keyLastLat = 'location_last_lat';
  static const _keyLastLng = 'location_last_lng';

  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;
  bool _isTracking = false;

  Position? get lastPosition => _lastPosition;
  bool get isTracking => _isTracking;

  Future<bool> initialize() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final prefs = await SharedPreferences.getInstance();
    final hasRequested = prefs.getBool(_keyPermissionRequested) ?? false;

    if (!hasRequested) {
      await prefs.setBool(_keyPermissionRequested, true);
    }

    return _ensurePermissions(requestBackground: true);
  }

  Future<bool> _ensurePermissions({required bool requestBackground}) async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    if (requestBackground && !kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.whileInUse) {
          permission = await Geolocator.requestPermission();
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (permission == LocationPermission.whileInUse) {
          permission = await Geolocator.requestPermission();
        }
      }
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  LocationSettings _buildSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'GRJ Office is tracking your work location.',
          notificationTitle: 'Background Location',
          enableWakeLock: false,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 25,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    final granted = await _ensurePermissions(requestBackground: true);
    if (!granted) return;

    await _positionSub?.cancel();
    try {
      _positionSub = Geolocator.getPositionStream(locationSettings: _buildSettings()).listen(
        _onPosition,
        onError: (error) {
          debugPrint('[LocationService] Position stream error: $error');
        },
      );
      _isTracking = true;
      debugPrint('[LocationService] Background tracking started.');
    } catch (e) {
      debugPrint('[LocationService] Failed to start tracking: $e');
      _isTracking = false;
      await _positionSub?.cancel();
      _positionSub = null;
    }
  }

  Future<void> stopTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _isTracking = false;
    debugPrint('[LocationService] Background tracking stopped.');
  }

  /// Checks GPS services and requests foreground location permission.
  /// Does not request background permission (used for Punch In validation).
  Future<LocationAccessResult> prepareForForegroundUse() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationAccessResult(
        LocationAccessStatus.serviceDisabled,
        'Location services are turned off. Please enable GPS to punch in.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationAccessResult(
        LocationAccessStatus.permissionDenied,
        'Location permission is required to punch in.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationAccessResult(
        LocationAccessStatus.permissionDeniedForever,
        'Location permission is permanently denied. Enable it in Settings to punch in.',
      );
    }

    return const LocationAccessResult(
      LocationAccessStatus.ready,
      'Location access granted.',
    );
  }

  /// Fetches a GPS fix suitable for geofence checks.
  /// Prefers a recent accurate reading and waits briefly for a better fix
  /// when the first reading is too coarse.
  Future<Position?> getAccurateCurrentLocation({
    String reason = 'location check',
    Duration timeout = const Duration(seconds: 20),
    double desiredAccuracyMeters = 50,
    double maxAccuracyMeters = 120,
  }) async {
    final granted = await _ensurePermissions(requestBackground: false);
    if (!granted) {
      debugPrint('[LocationService] $reason — permission denied.');
      return null;
    }

    final deadline = DateTime.now().add(timeout);
    Position? best = _usableCachedPosition(
      maxAge: const Duration(seconds: 20),
      maxAccuracyMeters: maxAccuracyMeters,
    );

    try {
      final firstAttempt = timeout > const Duration(seconds: 12)
          ? const Duration(seconds: 12)
          : timeout;
      final current = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: firstAttempt,
        ),
      );
      best = _betterPosition(best, current);
    } catch (e) {
      debugPrint('[LocationService] $reason — getCurrentPosition failed: $e');
    }

    if (best != null && best.accuracy <= desiredAccuracyMeters) {
      await _savePosition(best);
      _logPosition(reason, best);
      return best;
    }

    final remaining = deadline.difference(DateTime.now());
    if (remaining > const Duration(milliseconds: 400)) {
      best = await _waitForBetterFix(
        currentBest: best,
        timeout: remaining,
        desiredAccuracyMeters: desiredAccuracyMeters,
      );
    }

    if (best == null || best.accuracy > maxAccuracyMeters) {
      debugPrint(
        '[LocationService] $reason — GPS accuracy too low '
        '(${best?.accuracy.toStringAsFixed(1) ?? 'n/a'} m).',
      );
      return null;
    }

    await _savePosition(best);
    _logPosition(reason, best);
    return best;
  }

  Position? _usableCachedPosition({
    required Duration maxAge,
    required double maxAccuracyMeters,
  }) {
    final last = _lastPosition;
    if (last == null) return null;
    final age = DateTime.now().difference(last.timestamp);
    if (age > maxAge) return null;
    if (last.accuracy > maxAccuracyMeters) return null;
    return last;
  }

  Future<Position?> _waitForBetterFix({
    required Position? currentBest,
    required Duration timeout,
    required double desiredAccuracyMeters,
  }) async {
    Position? best = currentBest;
    final completer = Completer<Position?>();
    StreamSubscription<Position>? sub;
    Timer? timer;

    void finish() {
      if (!completer.isCompleted) completer.complete(best);
    }

    timer = Timer(timeout, finish);
    try {
      sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).listen(
        (position) {
          best = _betterPosition(best, position);
          if (best != null && best!.accuracy <= desiredAccuracyMeters) {
            finish();
          }
        },
        onError: (error) {
          debugPrint('[LocationService] accuracy stream error: $error');
          finish();
        },
      );
      return await completer.future;
    } finally {
      timer.cancel();
      await sub?.cancel();
    }
  }

  Position? _betterPosition(Position? current, Position candidate) {
    if (current == null) return candidate;
    if (candidate.accuracy < current.accuracy) return candidate;
    return current;
  }

  /// Fetches the user's current GPS position once (used at punch in/out).
  Future<Position?> getCurrentLocation({String reason = 'location check'}) async {
    final granted = await _ensurePermissions(requestBackground: false);
    if (!granted) {
      debugPrint('[LocationService] $reason — permission denied.');
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _savePosition(position);
      _logPosition(reason, position);
      return position;
    } catch (e) {
      debugPrint('[LocationService] $reason — failed to get location: $e');
      return null;
    }
  }

  void _logPosition(String reason, Position position) {
    debugPrint(
      '[LocationService] $reason\n'
      '  Latitude  : ${position.latitude}\n'
      '  Longitude : ${position.longitude}\n'
      '  Accuracy  : ${position.accuracy.toStringAsFixed(1)} m\n'
      '  Altitude  : ${position.altitude.toStringAsFixed(1)} m\n'
      '  Speed     : ${position.speed.toStringAsFixed(1)} m/s\n'
      '  Time      : ${position.timestamp}\n'
      '  Maps URL  : https://www.google.com/maps?q=${position.latitude},${position.longitude}',
    );
  }

  Future<void> _savePosition(Position position) async {
    _lastPosition = position;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLastLat, position.latitude);
    await prefs.setDouble(_keyLastLng, position.longitude);
  }

  Future<void> _onPosition(Position position) async {
    await _savePosition(position);
    _logPosition('live tracking update', position);
  }

  Future<void> dispose() async {
    await stopTracking();
  }
}
