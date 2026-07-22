// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

Getchatlistmodaldata getchatlistmodaldata(String str) =>
    Getchatlistmodaldata.fromJson(json.decode(str) as Map<String, dynamic>);

String getchatlistmodaldataToJson(Getchatlistmodaldata data) =>
    json.encode(data.toJson());

class Getchatlistmodaldata {
  bool? success;
  String? message;
  Data? data;

  Getchatlistmodaldata({
    this.success,
    this.message,
    this.data,
  });

  factory Getchatlistmodaldata.fromJson(Map<String, dynamic> json) =>
      Getchatlistmodaldata(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? Data.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class Data {
  List<Item>? items;
  Pagination? pagination;

  Data({
    this.items,
    this.pagination,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        items: json['items'] is List
            ? (json['items'] as List)
                .whereType<Map>()
                .map((x) => Item.fromJson(Map<String, dynamic>.from(x)))
                .toList()
            : const [],
        pagination: json['pagination'] is Map<String, dynamic>
            ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'items': items?.map((x) => x.toJson()).toList(),
        'pagination': pagination?.toJson(),
      };
}

class Item {
  int? id;
  String? name;
  String? avatarUrl;
  bool? isOnline;
  dynamic lastSeen;

  Item({
    this.id,
    this.name,
    this.avatarUrl,
    this.isOnline,
    this.lastSeen,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse('${json['id']}'),
        name: json['name']?.toString(),
        avatarUrl: json['avatar_url']?.toString(),
        isOnline: json['is_online'] == true || json['is_online'] == 1,
        lastSeen: json['last_seen'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        'is_online': isOnline,
        'last_seen': lastSeen,
      };
}

class Pagination {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  int? from;
  int? to;
  dynamic prevPageUrl;
  dynamic nextPageUrl;

  Pagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
    this.prevPageUrl,
    this.nextPageUrl,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        currentPage: _asInt(json['current_page']),
        lastPage: _asInt(json['last_page']),
        perPage: _asInt(json['per_page']),
        total: _asInt(json['total']),
        from: _asInt(json['from']),
        to: _asInt(json['to']),
        prevPageUrl: json['prev_page_url'],
        nextPageUrl: json['next_page_url'],
      );

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
  if (value is int) return value;
  return int.tryParse('$value');
}
