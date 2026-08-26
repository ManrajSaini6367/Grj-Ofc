class SiteModel {
  const SiteModel({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.image,
    this.shortDescription,
    this.tenderAmount,
    this.emdDeposit,
    this.workStartDate,
    this.workEndDate,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  final int id;
  final String name;
  final String address;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? image;
  final String? shortDescription;
  final num? tenderAmount;
  final num? emdDeposit;
  final String? workStartDate;
  final String? workEndDate;
  final double? latitude;
  final double? longitude;
  /// Allowed punch-in radius in kilometers (`login_distance_km` from the site API).
  final double? radiusKm;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasPunchRadius => radiusKm != null && radiusKm! > 0;

  double? get radiusMeters =>
      !hasPunchRadius ? null : radiusKm! * 1000;

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      image: json['image']?.toString(),
      shortDescription: json['short_description']?.toString(),
      tenderAmount: json['tender_amount'] as num?,
      emdDeposit: json['emd_deposit'] as num?,
      workStartDate: json['work_start_date']?.toString(),
      workEndDate: json['work_end_date']?.toString(),
      latitude: _parseDouble(_firstValue(json, const ['lat', 'latitude'])),
      longitude: _parseDouble(_firstValue(json, const ['lng', 'longitude'])),
      radiusKm: _parseDouble(
        _firstValue(json, const [
          'login_distance_km',
          'radius_km',
          'radiusKm',
        ]),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'image': image,
      'short_description': shortDescription,
      'tender_amount': tenderAmount,
      'emd_deposit': emdDeposit,
      'work_start_date': workStartDate,
      'work_end_date': workEndDate,
      'lat': latitude,
      'lng': longitude,
      'login_distance_km': radiusKm,
    };
  }

  static dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (!json.containsKey(key)) continue;
      final value = json[key];
      if (value != null) return value;
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty || text == 'null') return null;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(text);
    if (parsed == null || parsed.isNaN) return null;
    return parsed;
  }
}
