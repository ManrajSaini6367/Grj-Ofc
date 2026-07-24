import 'dart:convert';

Getsupplierlistdata getsupplierlistdataFromJson(String str) =>
    Getsupplierlistdata.fromJson(json.decode(str) as Map<String, dynamic>);

String getsupplierlistdataToJson(Getsupplierlistdata data) =>
    json.encode(data.toJson());

class Getsupplierlistdata {
  Getsupplierlistdata({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final SupplierListData? data;

  factory Getsupplierlistdata.fromJson(Map<String, dynamic> json) =>
      Getsupplierlistdata(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? SupplierListData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class SupplierListData {
  SupplierListData({
    this.items,
    this.pagination,
  });

  final List<SupplierListItem>? items;
  final SupplierListPagination? pagination;

  factory SupplierListData.fromJson(Map<String, dynamic> json) =>
      SupplierListData(
        items: json['items'] == null
            ? null
            : List<SupplierListItem>.from(
                (json['items'] as List).map(
                  (x) => SupplierListItem.fromJson(x as Map<String, dynamic>),
                ),
              ),
        pagination: json['pagination'] is Map<String, dynamic>
            ? SupplierListPagination.fromJson(
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

class SupplierListItem {
  SupplierListItem({
    this.id,
    this.siteId,
    this.name,
    this.mobile,
    this.address,
    this.gstNo,
    this.panNo,
    this.status,
    this.itemIds,
    this.items,
    this.site,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? siteId;
  final String? name;
  final String? mobile;
  final String? address;
  final String? gstNo;
  final String? panNo;
  final String? status;
  final List<int>? itemIds;
  final List<SupplierListMaterial>? items;
  final SupplierListSite? site;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SupplierListItem.fromJson(Map<String, dynamic> json) =>
      SupplierListItem(
        id: json['id'] as int?,
        siteId: json['site_id'] as int?,
        name: json['name']?.toString(),
        mobile: json['mobile']?.toString(),
        address: json['address']?.toString(),
        gstNo: json['gst_no']?.toString(),
        panNo: json['pan_no']?.toString(),
        status: json['status']?.toString(),
        itemIds: json['item_ids'] == null
            ? null
            : List<int>.from(
                (json['item_ids'] as List).map((x) => x as int),
              ),
        items: json['items'] == null
            ? null
            : List<SupplierListMaterial>.from(
                (json['items'] as List).map(
                  (x) =>
                      SupplierListMaterial.fromJson(x as Map<String, dynamic>),
                ),
              ),
        site: json['site'] is Map<String, dynamic>
            ? SupplierListSite.fromJson(json['site'] as Map<String, dynamic>)
            : null,
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'site_id': siteId,
        'name': name,
        'mobile': mobile,
        'address': address,
        'gst_no': gstNo,
        'pan_no': panNo,
        'status': status,
        if (itemIds != null) 'item_ids': itemIds,
        if (items != null) 'items': items!.map((x) => x.toJson()).toList(),
        if (site != null) 'site': site!.toJson(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class SupplierListMaterial {
  SupplierListMaterial({
    this.id,
    this.name,
    this.unit,
  });

  final int? id;
  final String? name;
  final String? unit;

  factory SupplierListMaterial.fromJson(Map<String, dynamic> json) =>
      SupplierListMaterial(
        id: json['id'] as int?,
        name: json['name']?.toString(),
        unit: json['unit']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
      };
}

class SupplierListSite {
  SupplierListSite({
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

  factory SupplierListSite.fromJson(Map<String, dynamic> json) =>
      SupplierListSite(
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

class SupplierListPagination {
  SupplierListPagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  factory SupplierListPagination.fromJson(Map<String, dynamic> json) =>
      SupplierListPagination(
        currentPage: _asInt(json['current_page']),
        lastPage: _asInt(json['last_page']),
        perPage: _asInt(json['per_page']),
        total: _asInt(json['total']),
      );

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
      };
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
