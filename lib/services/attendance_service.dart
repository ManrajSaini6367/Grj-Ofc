import 'package:flutter/foundation.dart';
import 'package:grjoffice_apps/core/app_date_time.dart';
import 'package:grjoffice_apps/models/attendance_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages punch in/out state and working duration with local persistence.
/// Syncs with [TodayAttendanceStatus] from the API when available.
class AttendanceService extends ChangeNotifier {
  AttendanceService._();

  static final AttendanceService instance = AttendanceService._();

  static const _keyPunchedIn = 'attendance_is_punched_in';
  static const _keyPunchInMs = 'attendance_punch_in_ms';
  static const _keyTodayDate = 'attendance_today_date';
  static const _keyTotalMs = 'attendance_total_ms';
  static const _keyLastPunchOutMs = 'attendance_last_punch_out_ms';
  static const _keyLastPunchInMs = 'attendance_last_punch_in_ms';

  bool _isPunchedIn = false;
  bool _canPunchIn = true;
  bool _canPunchOut = false;
  DateTime? _punchInTime;
  DateTime? _punchOutTime;
  Duration _todayTotal = Duration.zero;
  DateTime? _lastPunchOutTime;
  DateTime? _lastPunchInTime;
  Attendance? _todayAttendance;
  String? _todayDate;
  bool _loadedFromApi = false;

  bool get isPunchedIn => _isPunchedIn;
  bool get canPunchIn => _canPunchIn;
  bool get canPunchOut => _canPunchOut;
  DateTime? get punchInTime => _punchInTime;
  DateTime? get punchOutTime => _punchOutTime;
  DateTime? get lastPunchOutTime => _lastPunchOutTime;
  DateTime? get lastPunchInTime => _lastPunchInTime;
  Duration get todayTotal => _todayTotal;
  Attendance? get todayAttendance => _todayAttendance;
  String? get todayDate => _todayDate;
  bool get loadedFromApi => _loadedFromApi;

  Duration get elapsedDuration {
    final now = AppDateTime.now();
    if (!_isPunchedIn || _punchInTime == null) return _todayTotal;
    return _todayTotal + now.difference(_punchInTime!);
  }

  /// Live elapsed time from punch-in moment (ignores previous sessions today).
  Duration get currentSessionDuration {
    if (!_isPunchedIn || _punchInTime == null) return Duration.zero;
    return AppDateTime.now().difference(_punchInTime!);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = AppDateTime.todayKey();
    final storedDate = prefs.getString(_keyTodayDate);

    if (storedDate != todayKey) {
      _todayTotal = Duration.zero;
      _isPunchedIn = false;
      _canPunchIn = true;
      _canPunchOut = false;
      _punchInTime = null;
      _punchOutTime = null;
      _lastPunchOutTime = null;
      _lastPunchInTime = null;
      _todayAttendance = null;
      _todayDate = null;
      _loadedFromApi = false;
      await _save(prefs, todayKey);
      notifyListeners();
      return;
    }

    _todayTotal = Duration(milliseconds: prefs.getInt(_keyTotalMs) ?? 0);
    _isPunchedIn = prefs.getBool(_keyPunchedIn) ?? false;
    _canPunchIn = !_isPunchedIn;
    _canPunchOut = _isPunchedIn;
    final punchInMs = prefs.getInt(_keyPunchInMs);
    _punchInTime =
        punchInMs != null ? AppDateTime.fromEpoch(punchInMs) : null;
    final punchOutMs = prefs.getInt(_keyLastPunchOutMs);
    _lastPunchOutTime =
        punchOutMs != null ? AppDateTime.fromEpoch(punchOutMs) : null;
    _punchOutTime = _lastPunchOutTime;
    final lastPunchInMs = prefs.getInt(_keyLastPunchInMs);
    _lastPunchInTime =
        lastPunchInMs != null ? AppDateTime.fromEpoch(lastPunchInMs) : null;

    if (_isPunchedIn && _punchInTime == null) {
      _isPunchedIn = false;
      _canPunchIn = true;
      _canPunchOut = false;
      await _save(prefs, todayKey);
    }

    notifyListeners();
  }

  /// Applies server "today status" and persists the synced state locally.
  Future<void> applyTodayStatus(TodayAttendanceStatus status) async {
    _loadedFromApi = true;
    _todayDate = status.date;
    _isPunchedIn = status.isPunchedIn;
    _canPunchIn = status.canPunchIn;
    _canPunchOut = status.canPunchOut;
    _todayAttendance = status.attendance;

    final attendance = status.attendance;
    if (attendance != null) {
      _punchInTime = attendance.punchInTime;
      _punchOutTime = attendance.punchOutTime;
      _lastPunchInTime = attendance.punchInTime;
      _lastPunchOutTime = attendance.punchOutTime;

      if (attendance.totalMinutes > 0) {
        _todayTotal = Duration(minutes: attendance.totalMinutes);
      } else if (attendance.punchInTime != null &&
          attendance.punchOutTime != null) {
        _todayTotal =
            attendance.punchOutTime!.difference(attendance.punchInTime!);
      } else if (!_isPunchedIn) {
        // Keep existing total if still punched in and no completed session.
      }
    } else {
      _punchInTime = null;
      _punchOutTime = null;
    }

    if (_isPunchedIn && _punchInTime == null) {
      _punchInTime = AppDateTime.now();
    }

    await _persist();
    notifyListeners();
  }

  Future<void> punchIn() async {
    if (_isPunchedIn) return;

    final now = AppDateTime.now();
    _isPunchedIn = true;
    _canPunchIn = false;
    _canPunchOut = true;
    _punchInTime = now;
    _punchOutTime = null;
    await _persist();
    notifyListeners();
  }

  Future<Duration> punchOut() async {
    if (!_isPunchedIn || _punchInTime == null) return _todayTotal;

    final now = AppDateTime.now();
    _todayTotal += now.difference(_punchInTime!);
    _lastPunchInTime = _punchInTime;
    _lastPunchOutTime = now;
    _punchOutTime = now;
    _isPunchedIn = false;
    _canPunchIn = true;
    _canPunchOut = false;
    _punchInTime = null;
    await _persist();
    notifyListeners();
    return _todayTotal;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs, AppDateTime.todayKey());
  }

  Future<void> _save(SharedPreferences prefs, String todayKey) async {
    await prefs.setString(_keyTodayDate, todayKey);
    await prefs.setBool(_keyPunchedIn, _isPunchedIn);
    await prefs.setInt(_keyTotalMs, _todayTotal.inMilliseconds);

    if (_punchInTime != null) {
      await prefs.setInt(_keyPunchInMs, AppDateTime.toEpoch(_punchInTime!));
    } else {
      await prefs.remove(_keyPunchInMs);
    }

    if (_lastPunchOutTime != null) {
      await prefs.setInt(
        _keyLastPunchOutMs,
        AppDateTime.toEpoch(_lastPunchOutTime!),
      );
    } else {
      await prefs.remove(_keyLastPunchOutMs);
    }

    if (_lastPunchInTime != null) {
      await prefs.setInt(
        _keyLastPunchInMs,
        AppDateTime.toEpoch(_lastPunchInTime!),
      );
    } else {
      await prefs.remove(_keyLastPunchInMs);
    }
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  static String formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String formatTimeWithSeconds(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
  }

  static String formatLiveClock(DateTime time) {
    return formatTimeWithSeconds(time);
  }
}
