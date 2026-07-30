import 'dart:convert';

Getleavetypemodal getleavetypemodalFromJson(String str) =>
    Getleavetypemodal.fromJson(json.decode(str) as Map<String, dynamic>);

String getleavetypemodalToJson(Getleavetypemodal data) =>
    json.encode(data.toJson());

class Getleavetypemodal {
  Getleavetypemodal({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final LeaveTypeData? data;

  factory Getleavetypemodal.fromJson(Map<String, dynamic> json) =>
      Getleavetypemodal(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? LeaveTypeData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class LeaveTypeData {
  LeaveTypeData({this.items});

  final List<LeaveTypeItem>? items;

  factory LeaveTypeData.fromJson(Map<String, dynamic> json) => LeaveTypeData(
        items: json['items'] == null
            ? null
            : List<LeaveTypeItem>.from(
                (json['items'] as List).map(
                  (x) => LeaveTypeItem.fromJson(x as Map<String, dynamic>),
                ),
              ),
      );

  Map<String, dynamic> toJson() => {
        if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
      };
}

class LeaveTypeItem {
  LeaveTypeItem({
    this.value,
    this.label,
  });

  final String? value;
  final String? label;

  factory LeaveTypeItem.fromJson(Map<String, dynamic> json) => LeaveTypeItem(
        value: json['value']?.toString(),
        label: json['label']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
      };
}
