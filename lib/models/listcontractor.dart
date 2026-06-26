import 'dart:convert';

Contractorlistdatamodal contractorlistdatamodalFromJson(String str) =>
    Contractorlistdatamodal.fromJson(json.decode(str) as Map<String, dynamic>);

String contractorlistdatamodalToJson(Contractorlistdatamodal data) =>
    json.encode(data.toJson());

class Contractorlistdatamodal {
  Contractorlistdatamodal({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final ContractorListData? data;

  factory Contractorlistdatamodal.fromJson(Map<String, dynamic> json) =>
      Contractorlistdatamodal(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? ContractorListData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class ContractorListData {
  ContractorListData({
    this.items,
    this.pagination,
  });

  final List<ContractorListItem>? items;
  final ContractorListPagination? pagination;

  factory ContractorListData.fromJson(Map<String, dynamic> json) =>
      ContractorListData(
        items: json['items'] == null
            ? null
            : List<ContractorListItem>.from(
                (json['items'] as List).map(
                  (x) => ContractorListItem.fromJson(x as Map<String, dynamic>),
                ),
              ),
        pagination: json['pagination'] is Map<String, dynamic>
            ? ContractorListPagination.fromJson(
                json['pagination'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (items != null)
          'items': items!.map((x) => x.toJson()).toList(),
        if (pagination != null) 'pagination': pagination!.toJson(),
      };
}

class ContractorListItem {
  ContractorListItem({
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
  final dynamic masonRate;
  final dynamic beldarRate;
  final dynamic coolieRate;
  final dynamic masonOverRate;
  final dynamic beldarOverRate;
  final dynamic coolieOverRate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ContractorListSite? site;

  factory ContractorListItem.fromJson(Map<String, dynamic> json) =>
      ContractorListItem(
        id: json['id'] as int?,
        siteId: json['site_id'] as int?,
        name: json['name']?.toString(),
        mobile: json['mobile']?.toString(),
        address: json['address']?.toString(),
        status: json['status']?.toString(),
        masonRate: json['mason_rate'],
        beldarRate: json['beldar_rate'],
        coolieRate: json['coolie_rate'],
        masonOverRate: json['mason_over_rate'],
        beldarOverRate: json['beldar_over_rate'],
        coolieOverRate: json['coolie_over_rate'],
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
        site: json['site'] is Map<String, dynamic>
            ? ContractorListSite.fromJson(json['site'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'site_id': siteId,
        'name': name,
        'mobile': mobile,
        'address': address,
        'status': status,
        'mason_rate': masonRate,
        'beldar_rate': beldarRate,
        'coolie_rate': coolieRate,
        'mason_over_rate': masonOverRate,
        'beldar_over_rate': beldarOverRate,
        'coolie_over_rate': coolieOverRate,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (site != null) 'site': site!.toJson(),
      };
}

class ContractorListSite {
  ContractorListSite({
    this.id,
    this.name,
    this.address,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.image,
    this.shortDescription,
    this.tenderAmount,
    this.emdDeposit,
    this.workStartDate,
    this.workEndDate,
  });

  final int? id;
  final String? name;
  final String? address;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? image;
  final dynamic shortDescription;
  final int? tenderAmount;
  final int? emdDeposit;
  final DateTime? workStartDate;
  final DateTime? workEndDate;

  factory ContractorListSite.fromJson(Map<String, dynamic> json) =>
      ContractorListSite(
        id: json['id'] as int?,
        name: json['name']?.toString(),
        address: json['address']?.toString(),
        status: json['status']?.toString(),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
        image: json['image']?.toString(),
        shortDescription: json['short_description'],
        tenderAmount: json['tender_amount'] as int?,
        emdDeposit: json['emd_deposit'] as int?,
        workStartDate: _parseDate(json['work_start_date']),
        workEndDate: _parseDate(json['work_end_date']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'status': status,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        'image': image,
        'short_description': shortDescription,
        'tender_amount': tenderAmount,
        'emd_deposit': emdDeposit,
        if (workStartDate != null)
          'work_start_date':
              '${workStartDate!.year.toString().padLeft(4, '0')}-${workStartDate!.month.toString().padLeft(2, '0')}-${workStartDate!.day.toString().padLeft(2, '0')}',
        if (workEndDate != null)
          'work_end_date':
              '${workEndDate!.year.toString().padLeft(4, '0')}-${workEndDate!.month.toString().padLeft(2, '0')}-${workEndDate!.day.toString().padLeft(2, '0')}',
      };
}

class ContractorListPagination {
  ContractorListPagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  factory ContractorListPagination.fromJson(Map<String, dynamic> json) =>
      ContractorListPagination(
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

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

double _parseRateValue(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

extension ContractorListItemMapper on ContractorListItem {
  double get masonRateValue => _parseRateValue(masonRate);
  double get beldarRateValue => _parseRateValue(beldarRate);
  double get coolieRateValue => _parseRateValue(coolieRate);
  double get masonOverRateValue => _parseRateValue(masonOverRate);
  double get beldarOverRateValue => _parseRateValue(beldarOverRate);
  double get coolieOverRateValue => _parseRateValue(coolieOverRate);
}
