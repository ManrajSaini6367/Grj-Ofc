import 'dart:convert';

Getcontractormodal getcontractormodalFromJson(String str) =>
    Getcontractormodal.fromJson(json.decode(str) as Map<String, dynamic>);

class Getcontractormodal {
  Getcontractormodal({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final ContractorDetailData? data;

  factory Getcontractormodal.fromJson(Map<String, dynamic> json) =>
      Getcontractormodal(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? ContractorDetailData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );
}

class ContractorDetailData {
  ContractorDetailData({
    this.id,
    this.siteId,
    this.name,
    this.mobile,
    this.address,
    this.status,
    this.masonRate,
    this.beldarRate,
    this.coolieRate,
    this.masonOverRate,
    this.beldarOverRate,
    this.coolieOverRate,
    this.createdAt,
    this.updatedAt,
    this.site,
  });

  final int? id;
  final int? siteId;
  final String? name;
  final String? mobile;
  final String? address;
  final String? status;
  final String? masonRate;
  final String? beldarRate;
  final String? coolieRate;
  final String? masonOverRate;
  final String? beldarOverRate;
  final String? coolieOverRate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ContractorSiteInfo? site;

  factory ContractorDetailData.fromJson(Map<String, dynamic> json) =>
      ContractorDetailData(
        id: _parseInt(json['id']),
        siteId: _parseInt(json['site_id']),
        name: json['name']?.toString(),
        mobile: json['mobile']?.toString(),
        address: json['address']?.toString(),
        status: json['status']?.toString(),
        masonRate: json['mason_rate']?.toString(),
        beldarRate: json['beldar_rate']?.toString(),
        coolieRate: json['coolie_rate']?.toString(),
        masonOverRate: json['mason_over_rate']?.toString(),
        beldarOverRate: json['beldar_over_rate']?.toString(),
        coolieOverRate: json['coolie_over_rate']?.toString(),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
        site: json['site'] is Map<String, dynamic>
            ? ContractorSiteInfo.fromJson(json['site'] as Map<String, dynamic>)
            : null,
      );

  bool get isPublished => status == 'published';

  double get masonRateValue => _parseRate(masonRate);
  double get beldarRateValue => _parseRate(beldarRate);
  double get coolieRateValue => _parseRate(coolieRate);
  double get masonOverRateValue => _parseRate(masonOverRate);
  double get beldarOverRateValue => _parseRate(beldarOverRate);
  double get coolieOverRateValue => _parseRate(coolieOverRate);
}

class ContractorSiteInfo {
  ContractorSiteInfo({
    this.id,
    this.name,
    this.address,
  });

  final int? id;
  final String? name;
  final String? address;

  factory ContractorSiteInfo.fromJson(Map<String, dynamic> json) =>
      ContractorSiteInfo(
        id: _parseInt(json['id']),
        name: json['name']?.toString(),
        address: json['address']?.toString(),
      );
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double _parseRate(String? value) {
  if (value == null || value.isEmpty) return 0;
  return double.tryParse(value) ?? 0;
}
