import 'package:grjoffice_apps/models/mykycdatamodal.dart';

class Getmyemployeekycrequest {
  Getmyemployeekycrequest({
    this.success,
    this.message,
    this.data,
  });

  bool? success;
  String? message;
  GetMyEmployeeKycRequest? data;

  factory Getmyemployeekycrequest.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return Getmyemployeekycrequest(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: rawData is Map
          ? GetMyEmployeeKycRequest.fromJson(
              Map<String, dynamic>.from(rawData),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class GetMyEmployeeKycRequest {
  GetMyEmployeeKycRequest({
    this.items,
    this.pagination,
  });

  List<MyKycModalData>? items;
  GetEmployeeKycPagination? pagination;

  factory GetMyEmployeeKycRequest.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return GetMyEmployeeKycRequest(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => MyKycModalData.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
      pagination: json['pagination'] is Map
          ? GetEmployeeKycPagination.fromJson(
              Map<String, dynamic>.from(json['pagination'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (items != null)
          'items': items!.map((item) => item.toJson()).toList(),
        if (pagination != null) 'pagination': pagination!.toJson(),
      };
}

class GetEmployeeKycPagination {
  GetEmployeeKycPagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
    this.prevPageUrl,
    this.nextPageUrl,
  });

  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  dynamic from;
  dynamic to;
  dynamic prevPageUrl;
  dynamic nextPageUrl;

  factory GetEmployeeKycPagination.fromJson(Map<String, dynamic> json) {
    return GetEmployeeKycPagination(
      currentPage: _asInt(json['current_page'] ?? json['currentPage']),
      lastPage: _asInt(json['last_page'] ?? json['lastPage']),
      perPage: _asInt(json['per_page'] ?? json['perPage']),
      total: _asInt(json['total']),
      from: json['from'],
      to: json['to'],
      prevPageUrl: json['prev_page_url'] ?? json['prevPageUrl'],
      nextPageUrl: json['next_page_url'] ?? json['nextPageUrl'],
    );
  }

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

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
