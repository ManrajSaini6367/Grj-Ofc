import 'dart:convert';

import 'package:grjoffice_apps/Itemsscreen/item.dart';

Itemhistorydata itemhistorydataFromJson(String str) =>
    Itemhistorydata.fromJson(json.decode(str) as Map<String, dynamic>);

String itemhistorydataToJson(Itemhistorydata data) => json.encode(data.toJson());

class Itemhistorydata {
  Itemhistorydata({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final ItemHistoryListData? data;

  factory Itemhistorydata.fromJson(Map<String, dynamic> json) => Itemhistorydata(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? ItemHistoryListData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class ItemHistoryListData {
  ItemHistoryListData({
    this.items,
    this.pagination,
    this.item,
  });

  final List<ItemHistoryRecord>? items;
  final ItemHistoryPagination? pagination;
  final ItemHistoryItemInfo? item;

  factory ItemHistoryListData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['histories'] ?? json['transactions'];
    return ItemHistoryListData(
      items: rawItems is! List
          ? null
          : List<ItemHistoryRecord>.from(
              rawItems.whereType<Map>().map(
                    (x) => ItemHistoryRecord.fromJson(
                      Map<String, dynamic>.from(x),
                    ),
                  ),
            ),
      pagination: json['pagination'] is Map<String, dynamic>
          ? ItemHistoryPagination.fromJson(
              json['pagination'] as Map<String, dynamic>,
            )
          : null,
      item: json['item'] is Map<String, dynamic>
          ? ItemHistoryItemInfo.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (items != null) 'items': items!.map((x) => x.toJson()).toList(),
        if (pagination != null) 'pagination': pagination!.toJson(),
        if (item != null) 'item': item!.toJson(),
      };
}

class ItemHistoryRecord {
  ItemHistoryRecord({
    this.id,
    this.qty,
    this.unit,
    this.type,
    this.issueTo,
    this.remark,
    this.createdAt,
  });

  final int? id;
  final double? qty;
  final String? unit;
  final String? type;
  final String? issueTo;
  final String? remark;
  final DateTime? createdAt;

  factory ItemHistoryRecord.fromJson(Map<String, dynamic> json) =>
      ItemHistoryRecord(
        id: json['id'] as int?,
        qty: _parseQty(json['qty'] ?? json['quantity']),
        unit: json['unit']?.toString(),
        type: json['type']?.toString(),
        issueTo: json['issue_to']?.toString(),
        remark: json['remark']?.toString(),
        createdAt: _parseDate(json['created_at'] ?? json['date']),
      );

  ItemTransaction toTransaction({required String fallbackUnit}) {
    final typeValue = type?.toLowerCase().trim() ?? '';
    final isDebit = typeValue == 'debit' ||
        typeValue == 'out' ||
        typeValue == 'issue' ||
        typeValue == 'issued';
    return ItemTransaction(
      qty: qty ?? 0,
      unit: (unit != null && unit!.isNotEmpty) ? unit! : fallbackUnit,
      type: isDebit ? ItemTransactionType.debit : ItemTransactionType.credit,
      issueTo: issueTo?.isNotEmpty == true ? issueTo : null,
      remark: remark?.isNotEmpty == true ? remark : null,
      dateTime: createdAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'qty': qty,
        'unit': unit,
        'type': type,
        'issue_to': issueTo,
        'remark': remark,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

class ItemHistoryItemInfo {
  ItemHistoryItemInfo({
    this.id,
    this.name,
    this.sku,
    this.unit,
    this.balance,
  });

  final int? id;
  final String? name;
  final String? sku;
  final String? unit;
  final String? balance;

  factory ItemHistoryItemInfo.fromJson(Map<String, dynamic> json) =>
      ItemHistoryItemInfo(
        id: json['id'] as int?,
        name: json['name']?.toString(),
        sku: json['sku']?.toString(),
        unit: json['unit']?.toString(),
        balance: json['balance']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'unit': unit,
        'balance': balance,
      };
}

class ItemHistoryPagination {
  ItemHistoryPagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  factory ItemHistoryPagination.fromJson(Map<String, dynamic> json) =>
      ItemHistoryPagination(
        currentPage: json['current_page'] as int?,
        lastPage: json['last_page'] as int?,
        perPage: json['per_page'] as int?,
        total: json['total'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
      };
}

double? _parseQty(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
