import 'dart:convert';

import 'package:grjoffice_apps/models/getemployeemodal.dart';

Viewemployeeprofile viewemployeeprofileFromJson(String str) =>
    Viewemployeeprofile.fromJson(json.decode(str) as Map<String, dynamic>);

class Viewemployeeprofile {
  Viewemployeeprofile({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final EmployeeListItem? data;

  factory Viewemployeeprofile.fromJson(Map<String, dynamic> json) =>
      Viewemployeeprofile(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? EmployeeListItem.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );
}
