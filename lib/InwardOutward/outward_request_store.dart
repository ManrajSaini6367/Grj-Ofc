import 'package:flutter/material.dart';
import 'package:grjoffice_apps/services/api_auth.dart';

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
    this.fromSiteName = '',
    this.siteName = '',
    this.siteId,
    this.remark = '',
    this.rejectionReason = '',
    this.isIncoming = false,
    this.receiveRequestId,
  });

  final String id;
  final int? itemId;
  final String itemName;
  final double qty;
  final String unit;
  final String toName;
  final String fromSiteName;
  final String siteName;
  final int? siteId;
  final String remark;
  final OutwardRequestStatus status;
  final String rejectionReason;
  final bool isIncoming;
  final int? receiveRequestId;
  final DateTime createdAt;

  String get statusLabel => switch (status) {
        OutwardRequestStatus.pending => 'Pending',
        OutwardRequestStatus.approved => 'Approved',
        OutwardRequestStatus.rejected => 'Rejected',
      };

  int? get actionId =>
      isIncoming ? int.tryParse(id) : receiveRequestId;

  static OutwardRequestStatus _mapSentStatus(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'received' => OutwardRequestStatus.approved,
      'rejected' || 'cancelled' => OutwardRequestStatus.rejected,
      _ => OutwardRequestStatus.pending,
    };
  }

  static OutwardRequestStatus _mapReceiveStatus(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'accepted' => OutwardRequestStatus.approved,
      'rejected' => OutwardRequestStatus.rejected,
      _ => OutwardRequestStatus.pending,
    };
  }

  factory OutwardRequest.fromSentApi(Map<String, dynamic> json) {
    return OutwardRequest(
      id: '${json['id'] ?? ''}',
      itemId: json['item_id'] is int
          ? json['item_id'] as int
          : int.tryParse('${json['item_id'] ?? ''}'),
      itemName: (json['item_name'] ?? '').toString(),
      qty: (json['qty'] is num)
          ? (json['qty'] as num).toDouble()
          : double.tryParse('${json['qty'] ?? ''}') ?? 0,
      unit: (json['unit'] ?? '').toString(),
      siteName: (json['to_site_name'] ?? '').toString(),
      siteId: json['to_site_id'] is int
          ? json['to_site_id'] as int
          : int.tryParse('${json['to_site_id'] ?? ''}'),
      remark: (json['remark'] ?? '').toString(),
      status: _mapSentStatus(json['status']?.toString()),
      receiveRequestId: json['receive_request_id'] is int
          ? json['receive_request_id'] as int
          : int.tryParse('${json['receive_request_id'] ?? ''}'),
      isIncoming: false,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ??
          DateTime.now(),
    );
  }

  factory OutwardRequest.fromReceiveApi(Map<String, dynamic> json) {
    return OutwardRequest(
      id: '${json['id'] ?? ''}',
      itemId: json['item_id'] is int
          ? json['item_id'] as int
          : int.tryParse('${json['item_id'] ?? ''}'),
      itemName: (json['item_name'] ?? '').toString(),
      qty: (json['qty'] is num)
          ? (json['qty'] as num).toDouble()
          : double.tryParse('${json['qty'] ?? ''}') ?? 0,
      unit: (json['unit'] ?? '').toString(),
      fromSiteName: (json['from_site_name'] ?? '').toString(),
      siteName: (json['site_name'] ?? '').toString(),
      siteId: json['site_id'] is int
          ? json['site_id'] as int
          : int.tryParse('${json['site_id'] ?? ''}'),
      remark: (json['remark'] ?? '').toString(),
      rejectionReason: (json['review_note'] ?? '').toString(),
      status: _mapReceiveStatus(json['status']?.toString()),
      isIncoming: true,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ??
          DateTime.now(),
    );
  }
}

class OutwardRequestStore {
  OutwardRequestStore._();

  static Future<List<OutwardRequest>> loadSent(BuildContext context) async {
    final rows = await outboundSiteRequestsApi(context, status: 'all');
    if (rows == null) return const [];
    return rows.map(OutwardRequest.fromSentApi).toList();
  }

  static Future<List<OutwardRequest>> loadIncoming(
    BuildContext context, {
    String? status,
  }) async {
    final rows = await outboundSiteReceiveRequestsApi(
      context,
      status: status ?? 'all',
    );
    if (rows == null) return const [];
    return rows.map(OutwardRequest.fromReceiveApi).toList();
  }

  static Future<bool> createSiteTransfer(
    BuildContext context, {
    required int itemId,
    required double qty,
    required String unit,
    required int toSiteId,
    String remark = '',
  }) async {
    final saved = await createInboundOutboundApi(
      context,
      direction: 'outbound',
      itemId: itemId,
      qty: qty,
      unit: unit,
      remark: remark,
      destinationType: 'different',
      toSiteId: toSiteId,
    );
    return saved != null;
  }

  static Future<bool> acceptIncoming(
    BuildContext context, {
    required int receiveRequestId,
    String? reviewNote,
  }) {
    return acceptOutboundSiteReceiveRequestApi(
      context,
      id: receiveRequestId,
      reviewNote: reviewNote,
    );
  }

  static Future<bool> rejectIncoming(
    BuildContext context, {
    required int receiveRequestId,
    String? reviewNote,
  }) {
    return rejectOutboundSiteReceiveRequestApi(
      context,
      id: receiveRequestId,
      reviewNote: reviewNote,
    );
  }
}
