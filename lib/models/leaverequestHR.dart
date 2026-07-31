import 'dart:convert';

Leaverequesthr leaverequesthrFromJson(String str) =>
    Leaverequesthr.fromJson(json.decode(str) as Map<String, dynamic>);

String leaverequesthrToJson(Leaverequesthr data) =>
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

class Leaverequesthr {
  Leaverequesthr({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final HrLeaveRequestData? data;

  factory Leaverequesthr.fromJson(Map<String, dynamic> json) =>
      Leaverequesthr(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? HrLeaveRequestData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class HrLeaveRequestData {
  HrLeaveRequestData({
    this.items,
    this.pagination,
  });

  final List<HrLeaveRequestItem>? items;
  final HrLeaveRequestPagination? pagination;

  factory HrLeaveRequestData.fromJson(Map<String, dynamic> json) =>
      HrLeaveRequestData(
        items: json['items'] == null
            ? null
            : List<HrLeaveRequestItem>.from(
                (json['items'] as List).map(
                  (x) =>
                      HrLeaveRequestItem.fromJson(x as Map<String, dynamic>),
                ),
              ),
        pagination: json['pagination'] is Map<String, dynamic>
            ? HrLeaveRequestPagination.fromJson(
                json['pagination'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
        if (pagination != null) 'pagination': pagination!.toJson(),
      };
}

class HrLeaveRequestItem {
  HrLeaveRequestItem({
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

  factory HrLeaveRequestItem.fromJson(Map<String, dynamic> json) =>
      HrLeaveRequestItem(
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

class HrLeaveRequestPagination {
  HrLeaveRequestPagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
    this.prevPageUrl,
    this.nextPageUrl,
  });

  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;
  final int? from;
  final int? to;
  final dynamic prevPageUrl;
  final dynamic nextPageUrl;

  factory HrLeaveRequestPagination.fromJson(Map<String, dynamic> json) =>
      HrLeaveRequestPagination(
        currentPage: _parseInt(json['current_page']),
        lastPage: _parseInt(json['last_page']),
        perPage: _parseInt(json['per_page']),
        total: _parseInt(json['total']),
        from: _parseInt(json['from']),
        to: _parseInt(json['to']),
        prevPageUrl: json['prev_page_url'],
        nextPageUrl: json['next_page_url'],
      );

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
        'from': from,
        'to': to,
        'prev_page_url': prevPageUrl,
        'next_page_url': nextPageUrl,
      };
}
