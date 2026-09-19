import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// India Standard Time (Asia/Kolkata) helpers for attendance.
class AppDateTime {
  AppDateTime._();

  static bool _ready = false;
  static late tz.Location _india;

  /// Display format: `10 Sep 2026`
  static final DateFormat _displayFmt = DateFormat('dd MMM yyyy');

  /// Compact display format: `10 Sep`
  static final DateFormat _displayShortFmt = DateFormat('dd MMM');

  /// API / payload format: `2026-09-10`
  static final DateFormat _apiFmt = DateFormat('yyyy-MM-dd');

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

  /// e.g. `10 Sep 2026`
  static String formatDisplay(DateTime? date, {String fallback = '-'}) {
    if (date == null) return fallback;
    return _displayFmt.format(date);
  }

  /// e.g. `10 Sep`
  static String formatDisplayShort(DateTime? date, {String fallback = '-'}) {
    if (date == null) return fallback;
    return _displayShortFmt.format(date);
  }

  /// e.g. `2026-09-10` for API bodies
  static String formatApi(DateTime date) => _apiFmt.format(date);

  static DateTime? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }
}
