import 'package:geolocator/geolocator.dart';

class PunchInLocationCheck {
  const PunchInLocationCheck({
    required this.allowed,
    required this.distanceMeters,
    this.message,
  });

  final bool allowed;
  final double distanceMeters;
  final String? message;

  double get distanceKm => distanceMeters / 1000;
}

/// Distance check between the user's GPS position and the selected site.
class PunchInLocationValidator {
  PunchInLocationValidator._();

  /// GPS readings coarser than this are treated as unreliable for Punch In.
  static double maxAcceptableAccuracyMeters(double radiusMeters) {
    final scaled = radiusMeters * 0.2;
    if (scaled < 40) return 40.0;
    if (scaled > 120) return 120.0;
    return scaled;
  }

  static PunchInLocationCheck validate({
    required double userLatitude,
    required double userLongitude,
    required double allowedLatitude,
    required double allowedLongitude,
    required double radiusKm,
  }) {
    final distanceMeters = Geolocator.distanceBetween(
      allowedLatitude,
      allowedLongitude,
      userLatitude,
      userLongitude,
    );
    final radiusMeters = radiusKm * 1000;

    if (distanceMeters <= radiusMeters) {
      return PunchInLocationCheck(
        allowed: true,
        distanceMeters: distanceMeters,
      );
    }

    return PunchInLocationCheck(
      allowed: false,
      distanceMeters: distanceMeters,
      message: 'You are outside that location.',
    );
  }
}
