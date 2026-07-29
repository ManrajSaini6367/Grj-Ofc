enum LeaveType {
  casual('Casual Leave'),
  sick('Sick Leave'),
  function('Function Leave');

  const LeaveType(this.label);
  final String label;
}

enum LeaveStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const LeaveStatus(this.label);
  final String label;
}

class LeaveRequest {
  LeaveRequest({
    required this.id,
    required this.fromDate,
    required this.toDate,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.durationDays = 1,
    this.employeeName = 'Employee',
  });

  final String id;
  final DateTime fromDate;
  final DateTime toDate;
  final LeaveType type;
  final String description;
  LeaveStatus status;
  final DateTime createdAt;
  final int durationDays;
  final String employeeName;

  LeaveRequest copyWith({
    LeaveStatus? status,
    String? employeeName,
  }) {
    return LeaveRequest(
      id: id,
      fromDate: fromDate,
      toDate: toDate,
      type: type,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      durationDays: durationDays,
      employeeName: employeeName ?? this.employeeName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        'type': type.name,
        'description': description,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'durationDays': durationDays,
        'employeeName': employeeName,
      };

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      fromDate: DateTime.tryParse('${json['fromDate']}') ?? DateTime.now(),
      toDate: DateTime.tryParse('${json['toDate']}') ?? DateTime.now(),
      type: LeaveType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LeaveType.casual,
      ),
      description: json['description']?.toString() ?? '',
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeaveStatus.pending,
      ),
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      durationDays: json['durationDays'] is int
          ? json['durationDays'] as int
          : int.tryParse('${json['durationDays']}') ?? 1,
      employeeName: (json['employeeName']?.toString().trim().isNotEmpty == true)
          ? json['employeeName'].toString().trim()
          : 'Employee',
    );
  }
}
