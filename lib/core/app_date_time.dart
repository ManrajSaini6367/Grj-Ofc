import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// India Standard Time (Asia/Kolkata) helpers for attendance.
class AppDateTime {
  AppDateTime._();

  static bool _ready = false;
  static late tz.Location _india;

  static void init() {
    if (_ready) return;
    tz_data.initializeTimeZones();
    _india = tz.getLocation('Asia/Kolkata');
    _ready = true;
  }

  static DateTime now() {
    init();
    final ist = tz.TZDateTime.now(_india);
    return DateTime(
      ist.year,
      ist.month,
      ist.day,
      ist.hour,
      ist.minute,
      ist.second,
      ist.millisecond,
    );
  }

  static DateTime fromEpoch(int epochMs) {
    init();
    final ist = tz.TZDateTime.fromMillisecondsSinceEpoch(_india, epochMs);
    return DateTime(
      ist.year,
      ist.month,
      ist.day,
      ist.hour,
      ist.minute,
      ist.second,
      ist.millisecond,
    );
  }

  static int toEpoch(DateTime dateTime) {
    init();
    final ist = tz.TZDateTime(
      _india,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
    );
    return ist.millisecondsSinceEpoch;
  }

  static String todayKey() {
    final n = now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
