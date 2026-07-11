import 'package:flutter/material.dart';
import 'package:grjoffice_apps/models/pagination_model.dart';

enum ActivityType {
  employee,
  supplier,
  contractor,
  item,
  store,
  purchase,
  attendance,
  expense,
  system,
}

extension ActivityTypeApi on ActivityType {
  String get apiValue => name;

  static ActivityType fromApi(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'employee':
        return ActivityType.employee;
      case 'supplier':
        return ActivityType.supplier;
      case 'contractor':
        return ActivityType.contractor;
      case 'item':
        return ActivityType.item;
      case 'store':
        return ActivityType.store;
      case 'purchase':
        return ActivityType.purchase;
      case 'attendance':
        return ActivityType.attendance;
      case 'expense':
        return ActivityType.expense;
      case 'system':
      default:
        return ActivityType.system;
    }
  }
}

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.performedBy,
    required this.type,
    required this.dateTime,
    this.performedById,
    this.siteId,
    this.site,
    this.subjectType,
    this.subjectId,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String performedBy;
  final int? performedById;
  final ActivityType type;
  final int? siteId;
  final String? site;
  final String? subjectType;
  final int? subjectId;
  final DateTime dateTime;
  final DateTime? createdAt;

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    return ActivityEntry(
      id: (json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      performedBy: json['performed_by']?.toString() ?? '',
      performedById: json['performed_by_id'] as int?,
      type: ActivityTypeApi.fromApi(json['type']?.toString()),
      siteId: json['site_id'] as int?,
      site: json['site']?.toString(),
      subjectType: json['subject_type']?.toString(),
      subjectId: json['subject_id'] as int?,
      dateTime: _parseDate(json['date_time']) ??
          _parseDate(json['created_at']) ??
          DateTime.now(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': int.tryParse(id) ?? id,
        'title': title,
        'description': description,
        'type': type.apiValue,
        'performed_by': performedBy,
        'performed_by_id': performedById,
        'site_id': siteId,
        'site': site,
        'subject_type': subjectType,
        'subject_id': subjectId,
        'date_time': dateTime.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };
}

class ActivitySummary {
  const ActivitySummary({
    this.total = 0,
    this.today = 0,
    this.byType = const {},
  });

  final int total;
  final int today;
  final Map<String, int> byType;

  factory ActivitySummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ActivitySummary();
    final rawByType = json['by_type'];
    final byType = <String, int>{};
    if (rawByType is Map) {
      rawByType.forEach((key, value) {
        if (value is num) byType[key.toString()] = value.toInt();
      });
    }
    return ActivitySummary(
      total: json['total'] as int? ?? 0,
      today: json['today'] as int? ?? 0,
      byType: byType,
    );
  }
}

class ActivitiesListData {
  const ActivitiesListData({
    this.items = const [],
    this.pagination,
    this.summary,
  });

  final List<ActivityEntry> items;
  final PaginationModel? pagination;
  final ActivitySummary? summary;

  factory ActivitiesListData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return ActivitiesListData(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => ActivityEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      pagination: json['pagination'] is Map<String, dynamic>
          ? PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
      summary: json['summary'] is Map<String, dynamic>
          ? ActivitySummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ActivitiesListResponse {
  const ActivitiesListResponse({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final ActivitiesListData? data;

  factory ActivitiesListResponse.fromJson(Map<String, dynamic> json) {
    return ActivitiesListResponse(
      success: json['success'] as bool?,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? ActivitiesListData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String activityTypeLabel(ActivityType type) {
  return switch (type) {
    ActivityType.employee => 'Employee',
    ActivityType.supplier => 'Supplier',
    ActivityType.contractor => 'Contractor',
    ActivityType.item => 'Item',
    ActivityType.store => 'Store',
    ActivityType.purchase => 'Purchase',
    ActivityType.attendance => 'Attendance',
    ActivityType.expense => 'Expense',
    ActivityType.system => 'System',
  };
}

IconData activityTypeIcon(ActivityType type) {
  return switch (type) {
    ActivityType.employee => Icons.badge_outlined,
    ActivityType.supplier => Icons.inventory_2_outlined,
    ActivityType.contractor => Icons.groups_outlined,
    ActivityType.item => Icons.category_outlined,
    ActivityType.store => Icons.storefront_outlined,
    ActivityType.purchase => Icons.shopping_cart_outlined,
    ActivityType.attendance => Icons.how_to_reg_outlined,
    ActivityType.expense => Icons.account_balance_wallet_outlined,
    ActivityType.system => Icons.assessment_outlined,
  };
}

Color activityTypeColor(ActivityType type) {
  return switch (type) {
    ActivityType.employee => const Color(0xFF2563EB),
    ActivityType.supplier => const Color(0xFF7C3AED),
    ActivityType.contractor => const Color(0xFF0891B2),
    ActivityType.item => const Color(0xFF059669),
    ActivityType.store => const Color(0xFF8B1D1D),
    ActivityType.purchase => const Color(0xFFD97706),
    ActivityType.attendance => const Color(0xFF16A34A),
    ActivityType.expense => const Color(0xFFDC2626),
    ActivityType.system => const Color(0xFF64748B),
  };
}
