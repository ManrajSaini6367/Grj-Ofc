import 'dart:convert';

import 'package:grjoffice_apps/core/preference.dart';

enum OutwardRequestStatus { pending, approved, rejected }

class OutwardRequest {
  const OutwardRequest({
    required this.id,
    required this.itemName,
    required this.qty,
    required this.unit,
    required this.createdAt,
    required this.status,
    this.itemId,
    this.toName = '',
    this.siteName = '',
    this.siteId,
    this.remark = '',
    this.rejectionReason = '',
    this.isIncoming = false,
  });

  final String id;
  final int? itemId;
  final String itemName;
  final double qty;
  final String unit;
  final String toName;
  final String siteName;
  final int? siteId;
  final String remark;
  final OutwardRequestStatus status;
  final String rejectionReason;
  /// When true, this request appears on Receive Request screen.
  final bool isIncoming;
  final DateTime createdAt;

  String get statusLabel => switch (status) {
        OutwardRequestStatus.pending => 'Pending',
        OutwardRequestStatus.approved => 'Approved',
        OutwardRequestStatus.rejected => 'Rejected',
      };

  OutwardRequest copyWith({
    OutwardRequestStatus? status,
    String? rejectionReason,
  }) {
    return OutwardRequest(
      id: id,
      itemId: itemId,
      itemName: itemName,
      qty: qty,
      unit: unit,
      toName: toName,
      siteName: siteName,
      siteId: siteId,
      remark: remark,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isIncoming: isIncoming,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'item_name': itemName,
        'qty': qty,
        'unit': unit,
        'to_name': toName,
        'site_name': siteName,
        'site_id': siteId,
        'remark': remark,
        'status': status.name,
        'rejection_reason': rejectionReason,
        'is_incoming': isIncoming,
        'created_at': createdAt.toIso8601String(),
      };

  factory OutwardRequest.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] ?? 'pending').toString().toLowerCase();
    final status = switch (statusRaw) {
      'approved' => OutwardRequestStatus.approved,
      'rejected' => OutwardRequestStatus.rejected,
      _ => OutwardRequestStatus.pending,
    };

    return OutwardRequest(
      id: (json['id'] ?? '').toString(),
      itemId: json['item_id'] is int
          ? json['item_id'] as int
          : int.tryParse('${json['item_id'] ?? ''}'),
      itemName: (json['item_name'] ?? '').toString(),
      qty: (json['qty'] is num)
          ? (json['qty'] as num).toDouble()
          : double.tryParse('${json['qty'] ?? ''}') ?? 0,
      unit: (json['unit'] ?? '').toString(),
      toName: (json['to_name'] ?? '').toString(),
      siteName: (json['site_name'] ?? '').toString(),
      siteId: json['site_id'] is int
          ? json['site_id'] as int
          : int.tryParse('${json['site_id'] ?? ''}'),
      remark: (json['remark'] ?? '').toString(),
      status: status,
      rejectionReason: (json['rejection_reason'] ?? '').toString(),
      isIncoming: json['is_incoming'] == true,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ??
          DateTime.now(),
    );
  }
}

/// Local store for UI testing — replace with API later.
class OutwardRequestStore {
  OutwardRequestStore._();

  static const _key = 'outward_requests_v2';
  static const _seededKey = 'outward_requests_seeded_v2';

  static List<OutwardRequest> get _sampleData {
    final now = DateTime.now();
    return [
      OutwardRequest(
        id: 'req_1',
        itemName: 'Cement',
        qty: 10,
        unit: 'Bag',
        toName: 'Ramesh',
        siteName: 'Site A',
        remark: 'Urgent',
        status: OutwardRequestStatus.pending,
        isIncoming: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      OutwardRequest(
        id: 'req_2',
        itemName: 'TMT Bar',
        qty: 5,
        unit: 'Ton',
        toName: 'Suresh',
        siteName: 'Site B',
        status: OutwardRequestStatus.approved,
        isIncoming: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      OutwardRequest(
        id: 'req_3',
        itemName: 'Sand',
        qty: 20,
        unit: 'CUM',
        toName: 'Amit',
        siteName: 'Site C',
        status: OutwardRequestStatus.rejected,
        rejectionReason: 'Stock low',
        isIncoming: false,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      OutwardRequest(
        id: 'recv_1',
        itemName: 'Cement',
        qty: 8,
        unit: 'Bag',
        toName: 'Vikram',
        siteName: 'Site D',
        remark: 'Need today',
        status: OutwardRequestStatus.pending,
        isIncoming: true,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      OutwardRequest(
        id: 'recv_2',
        itemName: 'Bricks',
        qty: 1000,
        unit: 'NOS',
        toName: 'Karan',
        siteName: 'Site E',
        status: OutwardRequestStatus.pending,
        isIncoming: true,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      OutwardRequest(
        id: 'recv_3',
        itemName: 'Diesel',
        qty: 50,
        unit: 'Litre',
        toName: 'Neha',
        siteName: 'Site F',
        status: OutwardRequestStatus.approved,
        isIncoming: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static Future<void> ensureSampleData() async {
    final already = Preference.pref.getBool(_seededKey) ?? false;
    final raw = Preference.pref.getString(_key);
    if (already && raw != null && raw.trim().isNotEmpty) return;
    await _save(List<OutwardRequest>.from(_sampleData));
    await Preference.pref.setBool(_seededKey, true);
  }

  static Future<List<OutwardRequest>> loadAll() async {
    await ensureSampleData();
    final raw = Preference.pref.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      return List<OutwardRequest>.from(_sampleData);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return List<OutwardRequest>.from(_sampleData);
      final items = decoded
          .whereType<Map>()
          .map((e) => OutwardRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return List<OutwardRequest>.from(_sampleData);
    }
  }

  static Future<List<OutwardRequest>> loadSent() async {
    final all = await loadAll();
    return all.where((r) => !r.isIncoming).toList();
  }

  static Future<List<OutwardRequest>> loadIncoming() async {
    final all = await loadAll();
    return all.where((r) => r.isIncoming).toList();
  }

  static Future<void> _save(List<OutwardRequest> items) async {
    await Preference.pref.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> add(OutwardRequest request) async {
    final all = await loadAll();
    await _save(<OutwardRequest>[request, ...all]);
  }

  /// Creates a sent request and a mirrored incoming request for Receive screen UI.
  static Future<void> createRequest(OutwardRequest sent) async {
    final incoming = OutwardRequest(
      id: '${sent.id}_in',
      itemId: sent.itemId,
      itemName: sent.itemName,
      qty: sent.qty,
      unit: sent.unit,
      toName: sent.toName,
      siteName: sent.siteName,
      siteId: sent.siteId,
      remark: sent.remark,
      status: OutwardRequestStatus.pending,
      isIncoming: true,
      createdAt: sent.createdAt,
    );
    final all = await loadAll();
    await _save(<OutwardRequest>[sent, incoming, ...all]);
  }

  static Future<OutwardRequest?> updateStatus({
    required String id,
    required OutwardRequestStatus status,
    String rejectionReason = '',
  }) async {
    final all = await loadAll();
    final index = all.indexWhere((r) => r.id == id);
    if (index < 0) return null;

    final updated = all[index].copyWith(
      status: status,
      rejectionReason: rejectionReason,
    );
    all[index] = updated;

    // Keep mirrored pair in sync when possible.
    final pairId = id.endsWith('_in') ? id.replaceAll('_in', '') : '${id}_in';
    final pairIndex = all.indexWhere((r) => r.id == pairId);
    if (pairIndex >= 0) {
      all[pairIndex] = all[pairIndex].copyWith(
        status: status,
        rejectionReason: rejectionReason,
      );
    }

    await _save(all);
    return updated;
  }
}
