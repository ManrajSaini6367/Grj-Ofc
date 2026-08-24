import 'package:grjoffice_apps/models/getlistnotificationmodal.dart';

class Getnotificationmodaldata {
  Getnotificationmodaldata({
    this.success,
    this.message,
    this.data,
  });

  bool? success;
  String? message;
  NotificationListItem? data;

  factory Getnotificationmodaldata.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is Map) {
      return Getnotificationmodaldata(
        success: json['success'] == true,
        message: json['message']?.toString(),
        data: NotificationListItem.fromJson(Map<String, dynamic>.from(rawData)),
      );
    }
    return Getnotificationmodaldata(
      success: json['success'] == true || json['id'] != null,
      message: json['message']?.toString(),
      data: json['id'] != null ? NotificationListItem.fromJson(json) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}
