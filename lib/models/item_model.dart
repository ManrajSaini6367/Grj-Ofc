import 'package:grjoffice_apps/models/site_model.dart';

class ItemModel {
  const ItemModel({
    required this.id,
    required this.siteId,
    required this.name,
    this.sku,
    required this.unit,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.balance,
    this.purchase,
    this.dayReport,
    this.consumable,
    this.site,
  });

  final int id;
  final int siteId;
  final String name;
  final String? sku;
  final String unit;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? balance;
  final int? purchase;
  final int? dayReport;
  final int? consumable;
  final SiteModel? site;

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    final siteJson = json['site'];
    return ItemModel(
      id: json['id'] as int,
      siteId: json['site_id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString(),
      unit: json['unit']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      balance: json['balance']?.toString(),
      purchase: json['purchase'] as int?,
      dayReport: json['day_report'] as int?,
      consumable: json['consumable'] as int?,
      site: siteJson is Map<String, dynamic>
          ? SiteModel.fromJson(siteJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'name': name,
      'sku': sku,
      'unit': unit,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'balance': balance,
      'purchase': purchase,
      'day_report': dayReport,
      'consumable': consumable,
      if (site != null) 'site': site!.toJson(),
    };
  }

  String get displayName {
    var cleaned = name.trim();
    if (cleaned.length >= 2 &&
        cleaned.startsWith('"') &&
        cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned.replaceAll(r'\"', '"');
  }

  String get label {
    if (unit.isNotEmpty) return '$displayName ($unit)';
    return displayName;
  }
}
