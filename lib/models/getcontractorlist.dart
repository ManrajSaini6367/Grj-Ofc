class Getcclist {
  Getcclist({
    this.success,
    this.message,
    this.data,
  });

  bool? success;
  String? message;
  GetcclistData? data;

  factory Getcclist.fromJson(Map<String, dynamic> json) {
    return Getcclist(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map
          ? GetcclistData.fromJson(Map<String, dynamic>.from(json['data'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class GetcclistData {
  GetcclistData({
    this.id,
    this.siteId,
    this.name,
    this.works,
    this.status,
    this.site,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  int? siteId;
  String? name;
  List<GetcclistWork>? works;
  String? status;
  GetcclistSite? site;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory GetcclistData.fromJson(Map<String, dynamic> json) {
    final rawWorks = json['works'];
    return GetcclistData(
      id: _toInt(json['id']),
      siteId: _toInt(json['site_id']),
      name: json['name']?.toString(),
      works: rawWorks is List
          ? rawWorks
              .whereType<Map>()
              .map(
                (item) => GetcclistWork.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : null,
      status: json['status']?.toString(),
      site: json['site'] is Map
          ? GetcclistSite.fromJson(Map<String, dynamic>.from(json['site'] as Map))
          : null,
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'site_id': siteId,
        'name': name,
        'status': status,
        if (works != null) 'works': works!.map((w) => w.toJson()).toList(),
        if (site != null) 'site': site!.toJson(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

class GetcclistSite {
  GetcclistSite({
    this.id,
    this.name,
    this.address,
    this.lat,
    this.lng,
    this.loginDistanceKm,
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

  int? id;
  String? name;
  String? address;
  dynamic lat;
  dynamic lng;
  dynamic loginDistanceKm;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? image;
  dynamic shortDescription;
  int? tenderAmount;
  int? emdDeposit;
  DateTime? workStartDate;
  DateTime? workEndDate;

  factory GetcclistSite.fromJson(Map<String, dynamic> json) {
    return GetcclistSite(
      id: _toInt(json['id']),
      name: json['name']?.toString(),
      address: json['address']?.toString(),
      lat: json['lat'],
      lng: json['lng'],
      loginDistanceKm: json['login_distance_km'],
      status: json['status']?.toString(),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
      image: json['image']?.toString(),
      shortDescription: json['short_description'],
      tenderAmount: _toInt(json['tender_amount']),
      emdDeposit: _toInt(json['emd_deposit']),
      workStartDate: _toDate(json['work_start_date']),
      workEndDate: _toDate(json['work_end_date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'login_distance_km': loginDistanceKm,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'image': image,
        'short_description': shortDescription,
        'tender_amount': tenderAmount,
        'emd_deposit': emdDeposit,
        'work_start_date': workStartDate?.toIso8601String(),
        'work_end_date': workEndDate?.toIso8601String(),
      };
}

class GetcclistWork {
  GetcclistWork({
    this.work,
    this.rate,
  });

  String? work;
  double? rate;

  factory GetcclistWork.fromJson(Map<String, dynamic> json) {
    return GetcclistWork(
      work: (json['work'] ?? json['name'] ?? json['title'])?.toString(),
      rate: _toDouble(json['rate'] ?? json['amount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'work': work,
        'rate': rate,
      };
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
