import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
