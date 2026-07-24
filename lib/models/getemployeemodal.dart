import 'dart:convert';

Getemployeesmodal getemployeesmodalFromJson(String str) =>
    Getemployeesmodal.fromJson(json.decode(str) as Map<String, dynamic>);

String getemployeesmodalToJson(Getemployeesmodal data) => json.encode(data.toJson());

class Getemployeesmodal {
  Getemployeesmodal({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final EmployeeListData? data;

  factory Getemployeesmodal.fromJson(Map<String, dynamic> json) =>
      Getemployeesmodal(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? EmployeeListData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class EmployeeListData {
  EmployeeListData({
    this.items,
    this.pagination,
  });

  final List<EmployeeListItem>? items;
  final EmployeeListPagination? pagination;

  factory EmployeeListData.fromJson(Map<String, dynamic> json) =>
      EmployeeListData(
        items: json['items'] == null
            ? null
            : List<EmployeeListItem>.from(
                (json['items'] as List).whereType<Map>().map(
                      (x) => EmployeeListItem.fromJson(
                        Map<String, dynamic>.from(x),
                      ),
                    ),
              ),
        pagination: json['pagination'] is Map<String, dynamic>
            ? EmployeeListPagination.fromJson(
                json['pagination'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (items != null) 'items': items!.map((x) => x.toJson()).toList(),
        if (pagination != null) 'pagination': pagination!.toJson(),
      };
}

class EmployeeListItem {
  EmployeeListItem({
    this.id,
    this.name,
    this.firstName,
    this.lastName,
    this.email,
    this.mobile,
    this.username,
    this.siteId,
    this.designation,
    this.status,
    this.roles,
    this.dateOfJoin,
    this.dateOfSuspended,
    this.attendanceAllow,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobile;
  final String? username;
  final int? siteId;
  final String? designation;
  final String? status;
  final List<dynamic>? roles;
  final DateTime? dateOfJoin;
  final String? dateOfSuspended;
  final bool? attendanceAllow;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EmployeeListItem.fromJson(Map<String, dynamic> json) =>
      EmployeeListItem(
        id: _parseInt(json['id']),
        name: json['name']?.toString(),
        firstName: json['first_name']?.toString(),
        lastName: json['last_name']?.toString(),
        email: json['email']?.toString(),
        mobile: json['mobile']?.toString(),
        username: json['username']?.toString(),
        siteId: _parseInt(json['site_id']),
        designation: json['designation']?.toString(),
        status: json['status']?.toString(),
        roles: json['roles'] is List ? List<dynamic>.from(json['roles'] as List) : null,
        dateOfJoin: _parseDate(json['date_of_join']),
        dateOfSuspended: json['date_of_suspended']?.toString(),
        attendanceAllow: _parseBool(json['attendance_allow']),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
      );

  bool get isActiveStatus {
    final value = status?.toLowerCase().trim();
    if (value == null || value.isEmpty) return true;
    if (value == 'published' || value == 'active' || value == '1') return true;
    if (value == 'unpublished' || value == 'inactive' || value == '0') return false;
    return int.tryParse(value) == 1;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'mobile': mobile,
        'username': username,
        'site_id': siteId,
        'designation': designation,
        'status': status,
        if (roles != null) 'roles': roles,
        if (dateOfJoin != null)
          'date_of_join':
              '${dateOfJoin!.year.toString().padLeft(4, '0')}-${dateOfJoin!.month.toString().padLeft(2, '0')}-${dateOfJoin!.day.toString().padLeft(2, '0')}',
        'date_of_suspended': dateOfSuspended,
        'attendance_allow': attendanceAllow,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class EmployeeListPagination {
  EmployeeListPagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  factory EmployeeListPagination.fromJson(Map<String, dynamic> json) =>
      EmployeeListPagination(
        currentPage: _parseInt(json['current_page']),
        lastPage: _parseInt(json['last_page']),
        perPage: _parseInt(json['per_page']),
        total: _parseInt(json['total']),
      );

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
      };
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value == 1;
  return value.toString() == '1' || value.toString().toLowerCase() == 'true';
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
