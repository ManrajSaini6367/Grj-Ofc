import 'package:grjoffice_apps/models/attendance_model.dart';
import 'package:flutter/material.dart';

class MyAttendanceActivity {
  const MyAttendanceActivity({
    required this.title,
    this.subtitle,
    this.timeLabel,
  });

  final String title;
  final String? subtitle;
  final String? timeLabel;

  factory MyAttendanceActivity.fromJson(Map<String, dynamic> json) {
    return MyAttendanceActivity(
      title: (json['title'] ?? json['action'] ?? json['type'] ?? 'Activity')
          .toString(),
      subtitle: json['subtitle']?.toString() ?? json['description']?.toString(),
      timeLabel: json['time']?.toString() ??
          json['time_label']?.toString() ??
          json['created_at']?.toString(),
    );
  }
}

class MyAttendanceDay {
  const MyAttendanceDay({
    required this.date,
    required this.status,
    this.hasRecord = false,
    this.isHoliday = false,
    this.attendance,
    this.activities = const [],
  });

  final DateTime date;
  final AttendanceStatus status;
  final bool hasRecord;
  final bool isHoliday;
  final Attendance? attendance;
  final List<MyAttendanceActivity> activities;

  bool get showMarker => hasRecord;

  bool get canOpen => hasRecord;

  Color get markerColor {
    if (isHoliday) return const Color(0xFF2563EB);
    return switch (status) {
      AttendanceStatus.present => const Color(0xFF4CAF50),
      AttendanceStatus.leave => const Color(0xFFF59E0B),
      AttendanceStatus.absent => const Color(0xFFE53935),
    };
  }

  String get statusTitle {
    if (isHoliday) return 'Holiday';
    return switch (status) {
      AttendanceStatus.present => 'Present Day',
      AttendanceStatus.leave => 'Leave Day',
      AttendanceStatus.absent => 'Absent Day',
    };
  }
}

class MyAttendanceMonthSummary {
  const MyAttendanceMonthSummary({
    this.presentDays = 0,
    this.leaveDays = 0,
    this.holidayDays = 0,
    this.totalHoursLabel = '0:00',
    this.totalMinutes = 0,
  });

  final int presentDays;
  final int leaveDays;
  final int holidayDays;
  final String totalHoursLabel;
  final int totalMinutes;

  factory MyAttendanceMonthSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MyAttendanceMonthSummary();
    int toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    final hours = json['total_hours']?.toString() ??
        json['total_hours_label']?.toString() ??
        json['hours']?.toString();
    return MyAttendanceMonthSummary(
      presentDays: toInt(json['present'] ?? json['present_days']),
      leaveDays: toInt(json['leave'] ?? json['leave_days']),
      holidayDays: toInt(json['holiday'] ?? json['holiday_days']),
      totalHoursLabel: (hours != null && hours.trim().isNotEmpty)
          ? hours.trim()
          : _formatMinutes(toInt(json['total_minutes'])),
      totalMinutes: toInt(json['total_minutes']),
    );
  }

  static String _formatMinutes(int minutes) {
    if (minutes <= 0) return '0:00';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '$h:${m.toString().padLeft(2, '0')}';
  }
}

class MyAttendanceCalendarData {
  const MyAttendanceCalendarData({
    required this.monthKey,
    required this.summary,
    required this.days,
  });

  final String monthKey;
  final MyAttendanceMonthSummary summary;
  final Map<String, MyAttendanceDay> days;

  MyAttendanceDay? dayFor(DateTime date) {
    final key = dateKey(date);
    return days[key];
  }

  static String dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

/// Merges live today punch status with calendar data so dashboard + attendance stay in sync.
MyAttendanceDay mergeTodayWithLiveStatus({
  required DateTime today,
  required TodayAttendanceStatus liveStatus,
  MyAttendanceDay? calendarDay,
}) {
  final dayDate = DateTime(today.year, today.month, today.day);

  if (calendarDay?.isHoliday == true) return calendarDay!;
  if (calendarDay?.status == AttendanceStatus.leave) return calendarDay!;

  final attendance = liveStatus.attendance;

  List<MyAttendanceActivity> nonPunchActivities() {
    return (calendarDay?.activities ?? const [])
        .where((a) => !_isPunchActivityTitle(a.title))
        .toList();
  }

  if (liveStatus.isPunchedIn || attendance != null) {
    return MyAttendanceDay(
      date: dayDate,
      status: attendance?.status ?? AttendanceStatus.present,
      hasRecord: true,
      attendance: attendance,
      activities: nonPunchActivities(),
    );
  }

  if (calendarDay != null &&
      calendarDay.hasRecord &&
      calendarDay.status == AttendanceStatus.present) {
    return MyAttendanceDay(
      date: dayDate,
      status: AttendanceStatus.absent,
      hasRecord: false,
      activities: const [],
    );
  }

  return calendarDay ??
      MyAttendanceDay(
        date: dayDate,
        status: AttendanceStatus.absent,
        hasRecord: false,
        activities: const [],
      );
}

bool _isPunchActivityTitle(String title) {
  final lower = title.toLowerCase();
  return lower.contains('punch in') ||
      lower.contains('punch out') ||
      lower.contains('checked in') ||
      lower.contains('checked out');
}
