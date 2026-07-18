import 'dart:convert';

Getlabourattendancereport getLabourAttendanceReportFromJson(String str) =>
    Getlabourattendancereport.fromJson(json.decode(str));

String getLabourAttendanceReportToJson(Getlabourattendancereport data) =>
    json.encode(data.toJson());

class Getlabourattendancereport {
  bool? success;
  String? message;
  LabourAttendanceData? data;

  Getlabourattendancereport({
    this.success,
    this.message,
    this.data,
  });

  factory Getlabourattendancereport.fromJson(Map<String, dynamic> json) =>
      Getlabourattendancereport(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? LabourAttendanceData.fromJson(
                json['data'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class LabourAttendanceData {
  int? siteId;
  LabourAttendanceContractor? contractor;
  DateTime? startDate;
  DateTime? endDate;
  List<LabourAttendanceItem>? items;
  Amounts? totals;
  Amounts? rates;
  Amounts? amounts;

  LabourAttendanceData({
    this.siteId,
    this.contractor,
    this.startDate,
    this.endDate,
    this.items,
    this.totals,
    this.rates,
    this.amounts,
  });

  factory LabourAttendanceData.fromJson(Map<String, dynamic> json) =>
      LabourAttendanceData(
        siteId: _asInt(json['site_id']),
        contractor: json['contractor'] is Map<String, dynamic>
            ? LabourAttendanceContractor.fromJson(
                json['contractor'] as Map<String, dynamic>,
              )
            : null,
        startDate: _asDate(json['start_date']),
        endDate: _asDate(json['end_date']),
        items: json['items'] is List
            ? (json['items'] as List)
                .whereType<Map>()
                .map(
                  (x) => LabourAttendanceItem.fromJson(
                    Map<String, dynamic>.from(x),
                  ),
                )
                .toList()
            : [],
        totals: json['totals'] is Map<String, dynamic>
            ? Amounts.fromJson(json['totals'] as Map<String, dynamic>)
            : null,
        rates: json['rates'] is Map<String, dynamic>
            ? Amounts.fromJson(json['rates'] as Map<String, dynamic>)
            : null,
        amounts: json['amounts'] is Map<String, dynamic>
            ? Amounts.fromJson(json['amounts'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'site_id': siteId,
        'contractor': contractor?.toJson(),
        'start_date': _fmtDate(startDate),
        'end_date': _fmtDate(endDate),
        'items': items?.map((x) => x.toJson()).toList(),
        'totals': totals?.toJson(),
        'rates': rates?.toJson(),
        'amounts': amounts?.toJson(),
      };
}

class LabourAttendanceItem {
  DateTime? date;
  double? mason;
  double? beldar;
  double? coolie;
  double? masonOver;
  double? beldarOver;
  double? coolieOver;

  LabourAttendanceItem({
    this.date,
    this.mason,
    this.beldar,
    this.coolie,
    this.masonOver,
    this.beldarOver,
    this.coolieOver,
  });

  factory LabourAttendanceItem.fromJson(Map<String, dynamic> json) =>
      LabourAttendanceItem(
        date: _asDate(json['date'] ?? json['attendance_date']),
        mason: _asDouble(json['mason']),
        beldar: _asDouble(json['beldar']),
        coolie: _asDouble(json['coolie']),
        masonOver: _asDouble(json['mason_over'] ?? json['masonOver']),
        beldarOver: _asDouble(json['beldar_over'] ?? json['beldarOver']),
        coolieOver: _asDouble(json['coolie_over'] ?? json['coolieOver']),
      );

  Map<String, dynamic> toJson() => {
        'date': _fmtDate(date),
        'mason': mason,
        'beldar': beldar,
        'coolie': coolie,
        'mason_over': masonOver,
        'beldar_over': beldarOver,
        'coolie_over': coolieOver,
      };
}

class Amounts {
  double? mason;
  double? beldar;
  double? coolie;
  double? masonOver;
  double? beldarOver;
  double? coolieOver;
  double? grandTotal;

  Amounts({
    this.mason,
    this.beldar,
    this.coolie,
    this.masonOver,
    this.beldarOver,
    this.coolieOver,
    this.grandTotal,
  });

  factory Amounts.fromJson(Map<String, dynamic> json) => Amounts(
        mason: _asDouble(json['mason']),
        beldar: _asDouble(json['beldar']),
        coolie: _asDouble(json['coolie']),
        masonOver: _asDouble(json['mason_over']),
        beldarOver: _asDouble(json['beldar_over']),
        coolieOver: _asDouble(json['coolie_over']),
        grandTotal: _asDouble(json['grand_total']),
      );

  Map<String, dynamic> toJson() => {
        'mason': mason,
        'beldar': beldar,
        'coolie': coolie,
        'mason_over': masonOver,
        'beldar_over': beldarOver,
        'coolie_over': coolieOver,
        'grand_total': grandTotal,
      };
}

class LabourAttendanceContractor {
  int? id;
  String? name;

  LabourAttendanceContractor({
    this.id,
    this.name,
  });

  factory LabourAttendanceContractor.fromJson(Map<String, dynamic> json) =>
      LabourAttendanceContractor(
        id: _asInt(json['id']),
        name: json['name']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String? _fmtDate(DateTime? date) {
  if (date == null) return null;
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
