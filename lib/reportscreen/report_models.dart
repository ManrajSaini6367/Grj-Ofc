import 'package:flutter/material.dart';
import 'package:grjoffice_apps/models/getreportmodal.dart';

/// Report card shown on the list screen.
class ReportListItem {
  const ReportListItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.accentColor = const Color(0xFFF59E0B),
    this.path,
    this.excelUrl,
    this.requiredParams = const [],
    this.itemId,
    this.itemName,
    this.unit,
  });

  final String id;
  final String title;
  final String subtitle;
  final ReportType type;
  final Color accentColor;
  final String? path;
  final String? excelUrl;
  final List<String> requiredParams;
  final int? itemId;
  final String? itemName;
  final String? unit;

  bool get hasExcelUrl => excelUrl != null && excelUrl!.trim().isNotEmpty;

  factory ReportListItem.fromApiItem(ReportMenuItem item) {
    final key = item.key?.trim() ?? '';
    final uniqueId = key == 'item' && item.itemId != null
        ? 'item_${item.itemId}'
        : (key.isNotEmpty ? key : 'report_${item.itemId ?? item.title}');
    return ReportListItem(
      id: uniqueId,
      title: item.title?.trim().isNotEmpty == true ? item.title!.trim() : 'Report',
      subtitle: item.subtitle?.trim().isNotEmpty == true
          ? item.subtitle!.trim()
          : (item.itemName?.trim().isNotEmpty == true
              ? item.itemName!.trim().toUpperCase()
              : 'REPORT'),
      type: _typeFromKey(
        key,
        item.itemId,
        title: item.title,
        path: item.path,
      ),
      accentColor: _accentForKey(key, title: item.title),
      path: item.path,
      excelUrl: item.excelUrl,
      requiredParams: item.requiredParams ?? const [],
      itemId: item.itemId,
      itemName: item.itemName,
      unit: item.unit,
    );
  }

  bool get opensLabourAttendanceScreen => _matchesLabourAttendance(id, title, path);

  bool get opensDayEndReportScreen => type == ReportType.dayReport ||
      _matchesDayReport(id, title, path);

  /// API endpoint from reports list (`path` field).
  String get resolvedPath {
    final raw = path?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return '';
  }

  /// Loads immediately on open when only [site_id] (and optional [item_id]) are needed.
  bool get canAutoLoadFromApi {
    if (resolvedPath.isEmpty) return false;
    for (final key in requiredParams) {
      switch (key) {
        case 'item_id':
          if (itemId == null) return false;
          continue;
        default:
          return false;
      }
    }
    return true;
  }
}

bool _matchesLabourAttendance(String id, String title, String? path) {
  final haystack = '$id $title ${path ?? ''}'.toLowerCase().replaceAll('-', '_');
  return haystack.contains('labour') && haystack.contains('attendance');
}

bool _matchesDayReport(String id, String title, String? path) {
  final haystack = '$id $title ${path ?? ''}'.toLowerCase().replaceAll('-', '_');
  return haystack.contains('day') && haystack.contains('report');
}

enum ReportType {
  labourAttendance,
  challan,
  expenses,
  dayReport,
  itemReport,
  employerAttendance,
  unknown,
}

ReportType _typeFromKey(
  String key,
  int? itemId, {
  String? title,
  String? path,
}) {
  if (_matchesLabourAttendance(key, title ?? '', path)) {
    return ReportType.labourAttendance;
  }
  if (_matchesDayReport(key, title ?? '', path)) {
    return ReportType.dayReport;
  }

  final normalized = key.toLowerCase().replaceAll('-', '_');
  if (normalized.contains('chalan') || normalized.contains('challan')) {
    return ReportType.challan;
  }
  if (normalized.contains('expense')) {
    return ReportType.expenses;
  }
  if (normalized.contains('employer')) {
    return ReportType.employerAttendance;
  }
  if (itemId != null || normalized.contains('item')) {
    return ReportType.itemReport;
  }
  return ReportType.unknown;
}

Color _accentForKey(String key, {String? title}) {
  final normalized = '${key}_${title ?? ''}'.toLowerCase();
  if (normalized.contains('labour')) return const Color(0xFFF59E0B);
  if (normalized.contains('chalan') || normalized.contains('challan')) {
    return const Color(0xFFEF4444);
  }
  if (normalized.contains('expense')) return const Color(0xFF22C55E);
  if (normalized.contains('day')) return const Color(0xFF2563EB);
  if (normalized.contains('employer')) return const Color(0xFF8B5CF6);
  return const Color(0xFFF59E0B);
}

List<ReportListItem> reportItemsFromApi(List<ReportMenuItem> items) {
  return items.map(ReportListItem.fromApiItem).toList();
}
