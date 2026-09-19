import 'package:grjoffice_apps/models/attendance_model.dart';
import 'package:grjoffice_apps/models/my_attendance_calendar.dart';

class Getcalendermodal {
  const Getcalendermodal({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final CalendarData? data;

  factory Getcalendermodal.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return Getcalendermodal(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: rawData is Map
          ? CalendarData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  MyAttendanceCalendarData? toMyAttendanceCalendarData() {
    final payload = data;
    if (payload == null) return null;

    final monthKey = payload.month?.trim().isNotEmpty == true
        ? payload.month!.trim()
        : MyAttendanceCalendarData.dateKey(DateTime.now()).substring(0, 7);

    final joinDate = payload.dateOfJoin;
    final suspendedDate = payload.dateOfSuspended;

    final days = <String, MyAttendanceDay>{};
    for (final day in payload.days ?? const <CalendarDay>[]) {
      final mapped = day.toMyAttendanceDay();
      if (mapped == null) continue;
      // Before join / after suspension: keep empty (no absent/holiday marker).
      if (joinDate != null && mapped.date.isBefore(joinDate)) continue;
      if (suspendedDate != null && mapped.date.isAfter(suspendedDate)) {
        continue;
      }
      days[MyAttendanceCalendarData.dateKey(mapped.date)] = mapped;
    }

    final summary = payload.summary;
    return MyAttendanceCalendarData(
      monthKey: monthKey,
      summary: MyAttendanceMonthSummary(
        presentDays: summary?.presentDays ?? 0,
        leaveDays: summary?.leaveDays ?? 0,
        holidayDays: summary?.holidayDays ?? 0,
        totalHoursLabel: summary?.totalHours?.trim().isNotEmpty == true
            ? summary!.totalHours!.trim()
            : '0:00',
      ),
      days: days,
    );
  }
}

class CalendarData {
  const CalendarData({
    this.siteId,
    this.userId,
    this.month,
    this.dateOfJoin,
    this.dateOfSuspended,
    this.summary,
    this.days,
  });

  final int? siteId;
  final int? userId;
  final String? month;
  final DateTime? dateOfJoin;
  final DateTime? dateOfSuspended;
  final CalendarSummary? summary;
  final List<CalendarDay>? days;

  factory CalendarData.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    return CalendarData(
      siteId: _toInt(json['site_id']),
      userId: _toInt(json['user_id']),
      month: json['month']?.toString(),
      dateOfJoin: _parseDateOnly(json['date_of_join']),
      dateOfSuspended: _parseDateOnly(json['date_of_suspended']),
      summary: json['summary'] is Map
          ? CalendarSummary.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map),
            )
          : null,
      days: rawDays is List
          ? rawDays
              .whereType<Map>()
              .map(
                (item) => CalendarDay.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class CalendarDay {
  const CalendarDay({
    this.date,
    this.status,
    this.isHoliday,
    this.hasRecord,
    this.activities,
  });

  final DateTime? date;
  final CalendarDayStatus? status;
  final bool? isHoliday;
  final bool? hasRecord;
  final List<CalendarActivity>? activities;

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    final parsedDate = DateTime.tryParse(json['date']?.toString() ?? '');
    return CalendarDay(
      date: parsedDate == null
          ? null
          : DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      status: CalendarDayStatus.fromApi(json['status']?.toString()),
      isHoliday: json['is_holiday'] == true,
      hasRecord: json['has_record'] == true,
      activities: _parseActivities(json['activities']),
    );
  }

  MyAttendanceDay? toMyAttendanceDay() {
    final dayDate = date;
    if (dayDate == null) return null;

    // Empty / not applicable days must not render as absent or holiday.
    if (status == CalendarDayStatus.notApplicable ||
        status == CalendarDayStatus.empty) {
      return null;
    }

    final holiday = isHoliday == true || status == CalendarDayStatus.holiday;
    final attendanceStatus = _toAttendanceStatus(status, holiday: holiday);
    final activityItems = (activities ?? const <CalendarActivity>[])
        .where((item) {
          final lower = (item.title ?? '').toLowerCase();
          return !lower.contains('punch in') && !lower.contains('punch out');
        })
        .map(
          (item) => MyAttendanceActivity(
            title: item.title?.trim().isNotEmpty == true
                ? item.title!.trim()
                : 'Activity',
            subtitle: item.subtitle,
            timeLabel: item.time,
          ),
        )
        .toList();

    final recorded = hasRecord == true || activityItems.isNotEmpty;
    if (!recorded && !holiday) {
      return null;
    }

    return MyAttendanceDay(
      date: dayDate,
      status: attendanceStatus,
      hasRecord: recorded || holiday,
      isHoliday: holiday,
      activities: activityItems,
    );
  }

  static List<CalendarActivity>? _parseActivities(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => CalendarActivity.fromJson(
            Map<String, dynamic>.from(item),
          ),  
        )
        .toList();
  }
}

class CalendarActivity {
  const CalendarActivity({
    this.title,
    this.time,
    this.subtitle,
  });

  final String? title;
  final String? time;
  final String? subtitle;

  factory CalendarActivity.fromJson(Map<String, dynamic> json) {
    return CalendarActivity(
      title: json['title']?.toString(),
      time: json['time']?.toString(),
      subtitle: json['subtitle']?.toString(),
    );
  }
}

enum CalendarDayStatus {
  present,
  absent,
  leave,
  holiday,
  notApplicable,
  empty;

  static CalendarDayStatus? fromApi(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return switch (raw.trim().toLowerCase()) {
      'present' => CalendarDayStatus.present,
      'leave' => CalendarDayStatus.leave,
      'holiday' => CalendarDayStatus.holiday,
      'absent' => CalendarDayStatus.absent,
      'not_applicable' || 'n/a' || 'na' => CalendarDayStatus.notApplicable,
      'empty' || 'upcoming' || 'none' => CalendarDayStatus.empty,
      _ => CalendarDayStatus.absent,
    };
  }
}

class CalendarSummary {
  const CalendarSummary({
    this.presentDays,
    this.leaveDays,
    this.holidayDays,
    this.totalHours,
  });

  final int? presentDays;
  final int? leaveDays;
  final int? holidayDays;
  final String? totalHours;

  factory CalendarSummary.fromJson(Map<String, dynamic> json) {
    return CalendarSummary(
      presentDays: _toInt(json['present_days'] ?? json['present']),
      leaveDays: _toInt(json['leave_days'] ?? json['leave']),
      holidayDays: _toInt(json['holiday_days'] ?? json['holiday']),
      totalHours: json['total_hours']?.toString(),
    );
  }
}

AttendanceStatus _toAttendanceStatus(
  CalendarDayStatus? status, {
  required bool holiday,
}) {
  if (holiday) return AttendanceStatus.present;
  return switch (status) {
    CalendarDayStatus.present => AttendanceStatus.present,
    CalendarDayStatus.leave => AttendanceStatus.leave,
    CalendarDayStatus.holiday => AttendanceStatus.present,
    CalendarDayStatus.absent => AttendanceStatus.absent,
    CalendarDayStatus.notApplicable ||
    CalendarDayStatus.empty ||
    null =>
      AttendanceStatus.absent,
  };
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _parseDateOnly(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}
