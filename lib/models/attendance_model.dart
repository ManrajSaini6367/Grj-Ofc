
enum AttendanceStatus {
  present,
  absent,
  leave,
}

class Attendance {
  final String id;
  final String employeeName;
  final String? employeeAvatarUrl;
  final DateTime date;
  final DateTime? punchInTime;
  final DateTime? punchOutTime;
  final AttendanceStatus status;

  Attendance({
    required this.id,
    required this.employeeName,
    this.employeeAvatarUrl,
    required this.date,
    this.punchInTime,
    this.punchOutTime,
    required this.status,
  });

  String get totalHours {
    if (punchInTime == null || punchOutTime == null) return '0h 0m';
    final duration = punchOutTime!.difference(punchInTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

// Mock data
final List<Attendance> kMockAttendances = [
  Attendance(
    id: '1',
    employeeName: 'Abhishek Dadhich',
    employeeAvatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop',
    date: DateTime.now(),
    punchInTime: DateTime.now().subtract(const Duration(hours: 8, minutes: 15)),
    punchOutTime: DateTime.now().subtract(const Duration(minutes: 5)),
    status: AttendanceStatus.present,
  ),
  Attendance(
    id: '2',
    employeeName: 'Rahul Sharma',
    employeeAvatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100&h=100&fit=crop',
    date: DateTime.now(),
    punchInTime: null,
    punchOutTime: null,
    status: AttendanceStatus.absent,
  ),
  Attendance(
    id: '3',
    employeeName: 'Pooja Singh',
    employeeAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',
    date: DateTime.now(),
    punchInTime: DateTime.now().subtract(const Duration(hours: 9)),
    punchOutTime: DateTime.now().subtract(const Duration(hours: 1)),
    status: AttendanceStatus.present,
  ),
  Attendance(
    id: '4',
    employeeName: 'Ashish Kumar',
    employeeAvatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
    date: DateTime.now(),
    punchInTime: null,
    punchOutTime: null,
    status: AttendanceStatus.leave,
  ),
  Attendance(
    id: '5',
    employeeName: 'Neha Verma',
    employeeAvatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop',
    date: DateTime.now(),
    punchInTime: DateTime.now().subtract(const Duration(hours: 4)),
    punchOutTime: null, // Still working
    status: AttendanceStatus.present,
  ),
  Attendance(
    id: '6',
    employeeName: 'Karan Patel',
    employeeAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop',
    date: DateTime.now(),
    punchInTime: DateTime.now().subtract(const Duration(hours: 7, minutes: 45)),
    punchOutTime: DateTime.now().subtract(const Duration(hours: 0, minutes: 30)),
    status: AttendanceStatus.present,
  ),
  Attendance(
    id: '7',
    employeeName: 'Vikram Singh',
    employeeAvatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&h=100&fit=crop',
    date: DateTime.now(),
    punchInTime: null,
    punchOutTime: null,
    status: AttendanceStatus.absent,
  ),
];
