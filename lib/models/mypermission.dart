import 'dart:convert';

Mypermissionmodaldata myPermissionModalDataFromJson(String str) =>
    Mypermissionmodaldata.fromJson(json.decode(str) as Map<String, dynamic>);

String myPermissionModalDataToJson(Mypermissionmodaldata data) =>
    json.encode(data.toJson());

class Mypermissionmodaldata {
  bool? success;
  String? message;
  MyPermissionData? data;

  Mypermissionmodaldata({
    this.success,
    this.message,
    this.data,
  });

  factory Mypermissionmodaldata.fromJson(Map<String, dynamic> json) =>
      Mypermissionmodaldata(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? MyPermissionData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class MyPermissionData {
  int? userId;
  List<String>? roles;
  List<String>? permissions;
  List<String>? directPermissions;
  List<String>? rolePermissions;

  MyPermissionData({
    this.userId,
    this.roles,
    this.permissions,
    this.directPermissions,
    this.rolePermissions,
  });

  factory MyPermissionData.fromJson(Map<String, dynamic> json) =>
      MyPermissionData(
        userId: _asInt(json['user_id']),
        roles: _asStringList(json['roles']),
        permissions: _asStringList(json['permissions']),
        directPermissions: _asStringList(json['direct_permissions']),
        rolePermissions: _asStringList(json['role_permissions']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'roles': roles,
        'permissions': permissions,
        'direct_permissions': directPermissions,
        'role_permissions': rolePermissions,
      };
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return [];
  return value
      .map((e) => e?.toString().trim() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}
