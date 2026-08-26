import 'dart:convert';

import 'package:grjoffice_apps/core/preference.dart';

enum InwardOutwardType { inward, outward }

class InwardOutwardRecord {
  const InwardOutwardRecord({
    required this.id,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.qty,
    required this.unit,
    required this.contractorId,
    required this.contractorName,
    required this.createdAt,
    this.siteId,
    this.siteName,
    this.remark = '',
  });

  final String id;
  final InwardOutwardType type;
  final int? itemId;
  final String itemName;
  final double qty;
  final String unit;
  final int? contractorId;
  final String contractorName;
  final int? siteId;
  final String? siteName;
  final String remark;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type == InwardOutwardType.outward ? 'outward' : 'inward',
        'item_id': itemId,
        'item_name': itemName,
        'qty': qty,
        'unit': unit,
        'contractor_id': contractorId,
        'contractor_name': contractorName,
        'site_id': siteId,
        'site_name': siteName,
        'remark': remark,
        'created_at': createdAt.toIso8601String(),
      };

  factory InwardOutwardRecord.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] ?? json['direction'] ?? 'inward')
        .toString()
        .toLowerCase();
    final isOut = typeRaw == 'outward' || typeRaw == 'outbound';
    return InwardOutwardRecord(
      id: (json['id'] ?? '').toString(),
      type: isOut ? InwardOutwardType.outward : InwardOutwardType.inward,
      itemId: json['item_id'] is int
          ? json['item_id'] as int
          : int.tryParse('${json['item_id'] ?? ''}'),
      itemName: (json['item_name'] ?? '').toString(),
      qty: (json['qty'] is num)
          ? (json['qty'] as num).toDouble()
          : double.tryParse('${json['qty'] ?? ''}') ?? 0,
      unit: (json['unit'] ?? '').toString(),
      contractorId: json['contractor_id'] is int
          ? json['contractor_id'] as int
          : int.tryParse('${json['contractor_id'] ?? ''}'),
      contractorName: (json['contractor_name'] ?? '').toString(),
      siteId: () {
        final to = json['to_site_id'];
        if (to == null || '$to' == '' || '$to' == 'null') return null;
        return to is int ? to : int.tryParse('$to');
      }(),
      siteName: json['to_site_name']?.toString(),
      remark: (json['remark'] ?? json['description'] ?? '').toString(),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ??
          DateTime.now(),
    );
  }

  factory InwardOutwardRecord.fromApi(
    Map<String, dynamic> json, {
    required String direction,
  }) {
    final mapped = Map<String, dynamic>.from(json);
    mapped['direction'] = mapped['direction'] ?? direction;
    return InwardOutwardRecord.fromJson(mapped);
  }
}

class InwardOutwardStore {
  InwardOutwardStore._();

  static const _key = 'inward_outward_records_v1';

  static Future<List<InwardOutwardRecord>> loadAll() async {
    final raw = Preference.pref.getString(_key);
    if (raw == null || raw.trim().isEmpty) return <InwardOutwardRecord>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <InwardOutwardRecord>[];
      final items = decoded
          .whereType<Map>()
          .map((e) => InwardOutwardRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return <InwardOutwardRecord>[];
    }
  }

  static Future<List<InwardOutwardRecord>> loadByType(
    InwardOutwardType type,
  ) async {
    final all = await loadAll();
    return all.where((r) => r.type == type).toList();
  }

  static Future<void> add(InwardOutwardRecord record) async {
    final all = await loadAll();
    final next = <InwardOutwardRecord>[record, ...all];
    await Preference.pref.setString(
      _key,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }
}
