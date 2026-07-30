import 'dart:convert';

Getshowleavemodal getshowleavemodalFromJson(String str) =>
    Getshowleavemodal.fromJson(json.decode(str) as Map<String, dynamic>);

String getshowleavemodalToJson(Getshowleavemodal data) =>
    json.encode(data.toJson());

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class Getshowleavemodal {
  Getshowleavemodal({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final ShowLeaveData? data;

  factory Getshowleavemodal.fromJson(Map<String, dynamic> json) =>
      Getshowleavemodal(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? ShowLeaveData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class ShowLeaveData {
  ShowLeaveData({
    this.id,
    this.userId,
    this.siteId,
    this.fromDate,
    this.toDate,
    this.durationDays,
    this.type,
    this.typeLabel,
    this.description,
    this.status,
    this.employeeName,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.reviewNote,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final int? userId;
  final int? siteId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int? durationDays;
  final String? type;
  final String? typeLabel;
  final String? description;
  final String? status;
  final String? employeeName;
  final dynamic reviewedBy;
  final dynamic reviewedByName;
  final dynamic reviewedAt;
  final dynamic reviewNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ShowLeaveData.fromJson(Map<String, dynamic> json) => ShowLeaveData(
        id: json['id']?.toString(),
        userId: _parseInt(json['user_id']),
        siteId: _parseInt(json['site_id']),
        fromDate: _parseDate(json['from_date'] ?? json['fromDate']),
        toDate: _parseDate(json['to_date'] ?? json['toDate']),
        durationDays: _parseInt(json['duration_days'] ?? json['durationDays']),
        type: json['type']?.toString(),
        typeLabel: json['type_label']?.toString(),
        description: json['description']?.toString(),
        status: json['status']?.toString(),
        employeeName:
            (json['employee_name'] ?? json['employeeName'])?.toString(),
        reviewedBy: json['reviewed_by'],
        reviewedByName: json['reviewed_by_name'],
        reviewedAt: json['reviewed_at'],
        reviewNote: json['review_note'],
        createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
        updatedAt: _parseDate(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'site_id': siteId,
        'from_date': fromDate?.toIso8601String(),
        'to_date': toDate?.toIso8601String(),
        'duration_days': durationDays,
        'type': type,
        'type_label': typeLabel,
        'description': description,
        'status': status,
        'employee_name': employeeName,
        'reviewed_by': reviewedBy,
        'reviewed_by_name': reviewedByName,
        'reviewed_at': reviewedAt,
        'review_note': reviewNote,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
