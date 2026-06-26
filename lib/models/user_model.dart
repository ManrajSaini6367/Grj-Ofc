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
  final int status;
  final List<String> roles;
  final String? dateOfJoin;
  final String? dateOfSuspended;
  final bool attendanceAllow;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      siteId: json['site_id'] as int? ?? 0,
      designation: json['designation']?.toString(),
      avatar: json['avatar']?.toString(),
      status: json['status'] as int? ?? 0,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((role) => role.toString())
              .toList() ??
          const [],
      dateOfJoin: json['date_of_join']?.toString(),
      dateOfSuspended: json['date_of_suspended']?.toString(),
      attendanceAllow: json['attendance_allow'] as bool? ?? false,
    );
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
}
