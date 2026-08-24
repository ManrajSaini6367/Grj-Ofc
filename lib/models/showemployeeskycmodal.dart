import 'package:grjoffice_apps/models/mykycdatamodal.dart';

class Showemployyeskycmodal {
  Showemployyeskycmodal({
    this.success,
    this.message,
    this.data,
  });

  bool? success;
  String? message;
  MyKycModalData? data;

  factory Showemployyeskycmodal.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is Map) {
      return Showemployyeskycmodal(
        success: json['success'] == true,
        message: json['message']?.toString(),
        data: MyKycModalData.fromJson(Map<String, dynamic>.from(rawData)),
      );
    }
    return Showemployyeskycmodal(
      success: json['success'] == true || json['id'] != null,
      message: json['message']?.toString(),
      data: MyKycModalData.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}
