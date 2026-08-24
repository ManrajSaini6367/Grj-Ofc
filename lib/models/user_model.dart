class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.siteId,
    this.designation,
    this.avatar,
    required this.status,
    required this.roles,
    this.permissions = const [],
    this.roleId,
    this.dateOfJoin,
    this.dateOfSuspended,
    required this.attendanceAllow,
  });

  final int id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final int siteId;
  final String? designation;
  final String? avatar;
  final String status;
  final List<String> roles;
  final List<String> permissions;
  final int? roleId;
  final String? dateOfJoin;
  final String? dateOfSuspended;
  final bool attendanceAllow;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      siteId: _parseInt(json['site_id']),
      designation: json['designation']?.toString(),
      avatar: json['avatar']?.toString(),
      status: json['status']?.toString() ?? '',
      roles: _parseRoleNames(json['roles']),
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toList() ??
          const [],
      roleId: _parseRoleId(json),
      dateOfJoin: json['date_of_join']?.toString(),
      dateOfSuspended: json['date_of_suspended']?.toString(),
      attendanceAllow: _parseBool(json['attendance_allow']),
    );
  }

  static int _parseInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  static List<String> _parseRoleNames(dynamic roles) {
    if (roles is! List) return const [];
    return roles
        .map((role) {
          if (role is Map) {
            final name = role['name'] ?? role['title'] ?? role['id'];
            return name?.toString().trim() ?? '';
          }
          return role.toString().trim();
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static int? _parseRoleId(Map<String, dynamic> json) {
    final direct = _parseIntOrNull(json['role_id'] ?? json['roleId']);
    if (direct != null && direct > 0) return direct;
    final roles = json['roles'];
    if (roles is List && roles.isNotEmpty) {
      final first = roles.first;
      if (first is Map) {
        return _parseIntOrNull(first['id'] ?? first['role_id']);
      }
      return _parseIntOrNull(first);
    }
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'site_id': siteId,
      'designation': designation,
      'avatar': avatar,
      'status': status,
      'roles': roles,
      'role_id': roleId,
      'permissions': permissions,
      'date_of_join': dateOfJoin,
      'date_of_suspended': dateOfSuspended,
      'attendance_allow': attendanceAllow,
    };
  }

  String get roleLabel {
    if (roles.isEmpty) return 'User';
    final role = roles.first;
    if (role.isEmpty) return 'User';
    return role[0].toUpperCase() + role.substring(1);
  }

  bool get isActiveStatus {
    final normalized = status.trim().toLowerCase();
    return normalized == 'published' ||
        normalized == 'active' ||
        normalized == '1';
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    int? siteId,
    String? designation,
    String? avatar,
    String? status,
    List<String>? roles,
    List<String>? permissions,
    int? roleId,
    String? dateOfJoin,
    String? dateOfSuspended,
    bool? attendanceAllow,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      siteId: siteId ?? this.siteId,
      designation: designation ?? this.designation,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      roleId: roleId ?? this.roleId,
      dateOfJoin: dateOfJoin ?? this.dateOfJoin,
      dateOfSuspended: dateOfSuspended ?? this.dateOfSuspended,
      attendanceAllow: attendanceAllow ?? this.attendanceAllow,
    );
  }
}
