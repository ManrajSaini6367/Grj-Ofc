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

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] as int,
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
    };
  }
}
