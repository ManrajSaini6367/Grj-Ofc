enum AttendanceStatus {
  present,
  absent,
  leave,
}

class Attendance {
  const Attendance({
    required this.id,
    required this.employeeName,
    required this.date,
    required this.status,
    this.siteId,
    this.siteName,
    this.userId,
    this.employeeAvatarUrl,
    this.punchInTime,
    this.punchOutTime,
    this.punchInTimeLabel,
    this.punchOutTimeLabel,
    this.attendanceCode,
    this.isPunchedIn = false,
    this.totalMinutes = 0,
    this.totalHoursLabel,
    this.employerImage,
  });

  final String id;
  final int? siteId;
  final String? siteName;
  final int? userId;
  final String employeeName;
  final String? employeeAvatarUrl;
  final DateTime date;
  final DateTime? punchInTime;
  final DateTime? punchOutTime;
  final String? punchInTimeLabel;
  final String? punchOutTimeLabel;
  final AttendanceStatus status;
  final String? attendanceCode;
  final bool isPunchedIn;
  final int totalMinutes;
  final String? totalHoursLabel;
  final String? employerImage;

  String get totalHours {
    if (totalHoursLabel != null && totalHoursLabel!.trim().isNotEmpty) {
      return totalHoursLabel!;
    }
    if (punchInTime == null || punchOutTime == null) return '0h 0m';
    final duration = punchOutTime!.difference(punchInTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] ?? '').toString().toLowerCase();
    final status = switch (statusRaw) {
      'present' => AttendanceStatus.present,
      'leave' => AttendanceStatus.leave,
      _ => AttendanceStatus.absent,
    };

    return Attendance(
      id: (json['id'] ?? '').toString(),
      siteId: int.tryParse(json['site_id']?.toString() ?? ''),
      siteName: json['site_name']?.toString(),
      userId: int.tryParse(json['user_id']?.toString() ?? ''),
      employeeName: (json['employee_name'] ?? '—').toString(),
      employeeAvatarUrl: json['employee_avatar_url']?.toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      punchInTime: DateTime.tryParse(json['punch_in']?.toString() ?? ''),
      punchOutTime: DateTime.tryParse(json['punch_out']?.toString() ?? ''),
      punchInTimeLabel: json['punch_in_time']?.toString(),
      punchOutTimeLabel: json['punch_out_time']?.toString(),
      status: status,
      attendanceCode: json['attendance_code']?.toString(),
      isPunchedIn: json['is_punched_in'] == true,
      totalMinutes: int.tryParse(json['total_minutes']?.toString() ?? '') ?? 0,
      totalHoursLabel: json['total_hours']?.toString(),
      employerImage: json['employer_image']?.toString(),
    );
  }
}

class AttendancesSummary {
  const AttendancesSummary({
    this.total = 0,
    this.present = 0,
    this.absent = 0,
    this.leave = 0,
    this.punchedIn = 0,
  });

  final int total;
  final int present;
  final int absent;
  final int leave;
  final int punchedIn;

  factory AttendancesSummary.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    return AttendancesSummary(
      total: toInt(json['total']),
      present: toInt(json['present']),
      absent: toInt(json['absent']),
      leave: toInt(json['leave']),
      punchedIn: toInt(json['punched_in']),
    );
  }
}

class AttendancesPagination {
  const AttendancesPagination({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 50,
    this.total = 0,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory AttendancesPagination.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    return AttendancesPagination(
      currentPage: toInt(json['current_page']),
      lastPage: toInt(json['last_page']),
      perPage: toInt(json['per_page']),
      total: toInt(json['total']),
    );
  }
}

class AttendancesListData {
  const AttendancesListData({
    this.date,
    this.items = const [],
    this.pagination,
    this.summary,
  });

  final String? date;
  final List<Attendance> items;
  final AttendancesPagination? pagination;
  final AttendancesSummary? summary;

  factory AttendancesListData.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return AttendancesListData(
      date: json['date']?.toString(),
      items: itemsJson is List
          ? itemsJson
              .whereType<Map>()
              .map((e) => Attendance.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      pagination: json['pagination'] is Map
          ? AttendancesPagination.fromJson(
              Map<String, dynamic>.from(json['pagination'] as Map),
            )
          : null,
      summary: json['summary'] is Map
          ? AttendancesSummary.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map),
            )
          : null,
    );
  }
}

class AttendancesListResponse {
  const AttendancesListResponse({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final AttendancesListData? data;

  factory AttendancesListResponse.fromJson(Map<String, dynamic> json) {
    return AttendancesListResponse(
      success: json['success'] as bool?,
      message: json['message']?.toString(),
      data: json['data'] is Map
          ? AttendancesListData.fromJson(
              Map<String, dynamic>.from(json['data'] as Map),
            )
          : null,
    );
  }
}

class TodayAttendanceStatus {
  const TodayAttendanceStatus({
    required this.date,
    required this.isPunchedIn,
    required this.canPunchIn,
    required this.canPunchOut,
    this.attendance,
  });

  final String date;
  final bool isPunchedIn;
  final bool canPunchIn;
  final bool canPunchOut;
  final Attendance? attendance;

  factory TodayAttendanceStatus.fromJson(Map<String, dynamic> json) {
    final attendanceJson = json['attendance'];
    return TodayAttendanceStatus(
      date: (json['date'] ?? '').toString(),
      isPunchedIn: json['is_punched_in'] == true,
      canPunchIn: json['can_punch_in'] == true,
      canPunchOut: json['can_punch_out'] == true,
      attendance: attendanceJson is Map
          ? Attendance.fromJson(Map<String, dynamic>.from(attendanceJson))
          : null,
    );
  }
}

class PunchActionResult {
  const PunchActionResult({
    required this.isPunchedIn,
    this.attendance,
    this.latitude,
    this.longitude,
    this.message,
  });

  final bool isPunchedIn;
  final Attendance? attendance;
  final String? latitude;
  final String? longitude;
  final String? message;

  factory PunchActionResult.fromJson(Map<String, dynamic> json) {
    final attendanceJson = json['attendance'];
    final locationJson = json['location'];
    Map<String, dynamic>? location;
    if (locationJson is Map) {
      location = Map<String, dynamic>.from(locationJson);
    }

    return PunchActionResult(
      isPunchedIn: json['is_punched_in'] == true,
      attendance: attendanceJson is Map
          ? Attendance.fromJson(Map<String, dynamic>.from(attendanceJson))
          : null,
      latitude: location?['latitude']?.toString(),
      longitude: location?['longitude']?.toString(),
    );
  }

  TodayAttendanceStatus toTodayStatus() {
    final attendance = this.attendance;
    return TodayAttendanceStatus(
      date: attendance != null
          ? '${attendance.date.year.toString().padLeft(4, '0')}-'
              '${attendance.date.month.toString().padLeft(2, '0')}-'
              '${attendance.date.day.toString().padLeft(2, '0')}'
          : '',
      isPunchedIn: isPunchedIn,
      canPunchIn: !isPunchedIn,
      canPunchOut: isPunchedIn,
      attendance: attendance,
    );
  }
}

