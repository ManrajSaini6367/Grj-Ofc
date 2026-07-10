enum PurchaseStatus { pending, approved, received, cancelled }

enum WithoutKantaStage { initial, completed }

enum WithKantaStage { initial, processing, completed }

enum DirectPurchaseStage { completed }

enum PurchaseFlowType { withKanta, withoutKanta, direct }

class PurchaseMaterialItem {
  const PurchaseMaterialItem({
    required this.name,
    this.itemId,
    this.qty,
    this.unit = 'NOS',
  });

  final int? itemId;
  final String name;
  final double? qty;
  final String unit;

  String get displayLabel {
    if (qty == null) return name;
    final q = qty! == qty!.roundToDouble() ? qty!.toInt().toString() : qty.toString();
    return '$name — $q $unit';
  }
}

class PurchaseMaterialPayload {
  const PurchaseMaterialPayload({
    required this.itemId,
    required this.qty,
    required this.unit,
  });

  final int itemId;
  final double qty;
  final String unit;
}

class Purchase {
  const Purchase({
    required this.id,
    required this.date,
    required this.challanNo,
    required this.invoiceNo,
    required this.supplierName,
    required this.status,
    required this.flowType,
    this.siteId,
    this.supplierId,
    this.step,
    this.stage,
    this.nextAction,
    this.itemName,
    this.remark,
    this.vehicleNo,
    this.loadingVehicleImage,
    this.loadingVehicleImageAt,
    this.unloadingVehicleImage,
    this.unloadingVehicleImageAt,
    this.kantaSlipImage,
    this.kantaSlipImageAt,
    this.kantaNo,
    this.vehicleAtKantaImage,
    this.vehicleAtKantaImageAt,
    this.materials = const [],
    this.withoutKantaStage,
    this.withKantaStage,
    this.directPurchaseStage,
  });

  final String id;
  final DateTime date;
  final String challanNo;
  final String invoiceNo;
  final String supplierName;
  final PurchaseStatus status;
  final PurchaseFlowType flowType;
  final int? siteId;
  final int? supplierId;
  final int? step;
  final String? stage;
  final String? nextAction;
  final String? itemName;
  final String? remark;
  final String? vehicleNo;
  final String? loadingVehicleImage;
  final DateTime? loadingVehicleImageAt;
  final String? unloadingVehicleImage;
  final DateTime? unloadingVehicleImageAt;
  final String? kantaSlipImage;
  final DateTime? kantaSlipImageAt;
  final String? kantaNo;
  final String? vehicleAtKantaImage;
  final DateTime? vehicleAtKantaImageAt;
  final List<PurchaseMaterialItem> materials;
  final WithoutKantaStage? withoutKantaStage;
  final WithKantaStage? withKantaStage;
  final DirectPurchaseStage? directPurchaseStage;

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _imageValue(Map<String, dynamic>? images, String key, String field) {
    final image = _asMap(images?[key]);
    if (image == null) return null;
    final value = image[field]?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static DateTime? _imageCapturedAt(Map<String, dynamic>? images, String key) {
    final raw = _imageValue(images, key, 'captured_at');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final flowRaw = (json['flow_type'] ?? '').toString().toLowerCase();
    final flowType = switch (flowRaw) {
      'with_kanta' => PurchaseFlowType.withKanta,
      'without_kanta' => PurchaseFlowType.withoutKanta,
      'direct' => PurchaseFlowType.direct,
      _ => PurchaseFlowType.withoutKanta,
    };

    final stageRaw = (json['stage'] ?? json['status'] ?? '').toString().toLowerCase();
    final apiStatus = (json['status'] ?? '').toString().toLowerCase();

    WithoutKantaStage? withoutStage;
    WithKantaStage? withStage;
    DirectPurchaseStage? directStage;

    if (flowType == PurchaseFlowType.withKanta) {
      withStage = switch (stageRaw) {
        'processing' => WithKantaStage.processing,
        'completed' => WithKantaStage.completed,
        _ => WithKantaStage.initial,
      };
    } else if (flowType == PurchaseFlowType.withoutKanta) {
      withoutStage = stageRaw == 'completed'
          ? WithoutKantaStage.completed
          : WithoutKantaStage.initial;
    } else if (stageRaw == 'completed' || apiStatus == 'completed') {
      directStage = DirectPurchaseStage.completed;
    }

    final status = switch (apiStatus) {
      'completed' || 'received' => PurchaseStatus.received,
      'approved' => PurchaseStatus.approved,
      'cancelled' => PurchaseStatus.cancelled,
      _ => PurchaseStatus.pending,
    };

    final materialsJson = json['materials'];
    final materials = <PurchaseMaterialItem>[];
    if (materialsJson is List) {
      for (final row in materialsJson) {
        if (row is! Map) continue;
        final map = Map<String, dynamic>.from(row);
        materials.add(
          PurchaseMaterialItem(
            itemId: int.tryParse(map['item_id']?.toString() ?? ''),
            name: (map['name'] ?? map['item_name'] ?? '').toString(),
            qty: double.tryParse(map['qty']?.toString() ?? ''),
            unit: (map['unit'] ?? 'NOS').toString(),
          ),
        );
      }
    }

    final images = _asMap(json['images']);
    final apiItemName = json['item_name']?.toString().trim();
    final materialsName = materials
        .map((m) => m.name.trim())
        .where((n) => n.isNotEmpty)
        .join(', ');

    final date = DateTime.tryParse(json['date']?.toString() ?? '') ??
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
        DateTime.now();

    return Purchase(
      id: (json['id'] ?? '').toString(),
      siteId: int.tryParse(json['site_id']?.toString() ?? ''),
      supplierId: int.tryParse(json['supplier_id']?.toString() ?? ''),
      date: date,
      challanNo: (json['challan_no'] ?? json['vehicle_no'] ?? '—').toString(),
      invoiceNo: (json['invoice_no'] ?? '—').toString(),
      supplierName: (json['supplier_name'] ?? '—').toString(),
      status: status,
      flowType: flowType,
      step: int.tryParse(json['step']?.toString() ?? ''),
      stage: stageRaw.isEmpty ? null : stageRaw,
      nextAction: json['next_action']?.toString(),
      remark: json['remark']?.toString(),
      vehicleNo: json['vehicle_no']?.toString(),
      kantaNo: json['kanta_no']?.toString(),
      loadingVehicleImage: _imageValue(images, 'loading', 'url') ??
          _imageValue(images, 'loading', 'file'),
      loadingVehicleImageAt: _imageCapturedAt(images, 'loading'),
      unloadingVehicleImage: _imageValue(images, 'unloading', 'url') ??
          _imageValue(images, 'unloading', 'file'),
      unloadingVehicleImageAt: _imageCapturedAt(images, 'unloading'),
      kantaSlipImage: _imageValue(images, 'kanta_slip', 'url') ??
          _imageValue(images, 'kanta_slip', 'file'),
      kantaSlipImageAt: _imageCapturedAt(images, 'kanta_slip'),
      vehicleAtKantaImage: _imageValue(images, 'vehicle_at_kanta', 'url') ??
          _imageValue(images, 'vehicle_at_kanta', 'file'),
      vehicleAtKantaImageAt: _imageCapturedAt(images, 'vehicle_at_kanta'),
      materials: materials,
      itemName: (apiItemName != null && apiItemName.isNotEmpty)
          ? apiItemName
          : (materialsName.isEmpty ? null : materialsName),
      withoutKantaStage: withoutStage,
      withKantaStage: withStage,
      directPurchaseStage: directStage,
    );
  }

  bool get hasKantaSlip => flowType == PurchaseFlowType.withKanta;
  bool get isWithoutKanta => flowType == PurchaseFlowType.withoutKanta;
  bool get isWithKanta => flowType == PurchaseFlowType.withKanta;
  bool get isDirectPurchase => flowType == PurchaseFlowType.direct;

  String get statusLabel => switch (status) {
        PurchaseStatus.pending => 'Pending',
        PurchaseStatus.approved => 'Approved',
        PurchaseStatus.received => 'Received',
        PurchaseStatus.cancelled => 'Cancelled',
      };

  String? get withoutKantaStageLabel => switch (withoutKantaStage) {
        WithoutKantaStage.initial => 'Initial',
        WithoutKantaStage.completed => 'Completed',
        null => null,
      };

  String? get withKantaStageLabel => switch (withKantaStage) {
        WithKantaStage.initial => 'Initial',
        WithKantaStage.processing => 'Processing',
        WithKantaStage.completed => 'Completed',
        null => null,
      };

  String? get directPurchaseStageLabel => switch (directPurchaseStage) {
        DirectPurchaseStage.completed => 'Completed',
        null => null,
      };

  String? get flowStageLabel =>
      withoutKantaStageLabel ?? withKantaStageLabel ?? directPurchaseStageLabel;

  bool get hasFlowStage =>
      withoutKantaStage != null || withKantaStage != null || directPurchaseStage != null;

  String get materialsSummary =>
      materials.isEmpty ? (itemName ?? '—') : materials.map((m) => m.displayLabel).join(', ');

  Purchase copyWith({
    String? id,
    DateTime? date,
    String? challanNo,
    String? invoiceNo,
    String? supplierName,
    PurchaseStatus? status,
    PurchaseFlowType? flowType,
    int? siteId,
    int? supplierId,
    int? step,
    String? stage,
    String? nextAction,
    String? itemName,
    String? remark,
    String? vehicleNo,
    String? loadingVehicleImage,
    DateTime? loadingVehicleImageAt,
    String? unloadingVehicleImage,
    DateTime? unloadingVehicleImageAt,
    String? kantaSlipImage,
    DateTime? kantaSlipImageAt,
    String? kantaNo,
    String? vehicleAtKantaImage,
    DateTime? vehicleAtKantaImageAt,
    List<PurchaseMaterialItem>? materials,
    WithoutKantaStage? withoutKantaStage,
    WithKantaStage? withKantaStage,
    DirectPurchaseStage? directPurchaseStage,
  }) {
    return Purchase(
      id: id ?? this.id,
      date: date ?? this.date,
      challanNo: challanNo ?? this.challanNo,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      supplierName: supplierName ?? this.supplierName,
      status: status ?? this.status,
      flowType: flowType ?? this.flowType,
      siteId: siteId ?? this.siteId,
      supplierId: supplierId ?? this.supplierId,
      step: step ?? this.step,
      stage: stage ?? this.stage,
      nextAction: nextAction ?? this.nextAction,
      itemName: itemName ?? this.itemName,
      remark: remark ?? this.remark,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      loadingVehicleImage: loadingVehicleImage ?? this.loadingVehicleImage,
      loadingVehicleImageAt: loadingVehicleImageAt ?? this.loadingVehicleImageAt,
      unloadingVehicleImage: unloadingVehicleImage ?? this.unloadingVehicleImage,
      unloadingVehicleImageAt: unloadingVehicleImageAt ?? this.unloadingVehicleImageAt,
      kantaSlipImage: kantaSlipImage ?? this.kantaSlipImage,
      kantaSlipImageAt: kantaSlipImageAt ?? this.kantaSlipImageAt,
      kantaNo: kantaNo ?? this.kantaNo,
      vehicleAtKantaImage: vehicleAtKantaImage ?? this.vehicleAtKantaImage,
      vehicleAtKantaImageAt: vehicleAtKantaImageAt ?? this.vehicleAtKantaImageAt,
      materials: materials ?? this.materials,
      withoutKantaStage: withoutKantaStage ?? this.withoutKantaStage,
      withKantaStage: withKantaStage ?? this.withKantaStage,
      directPurchaseStage: directPurchaseStage ?? this.directPurchaseStage,
    );
  }
}

class PurchasesSummary {
  const PurchasesSummary({
    this.total = 0,
    this.initial = 0,
    this.processing = 0,
    this.completed = 0,
  });

  final int total;
  final int initial;
  final int processing;
  final int completed;

  factory PurchasesSummary.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    return PurchasesSummary(
      total: toInt(json['total']),
      initial: toInt(json['initial']),
      processing: toInt(json['processing']),
      completed: toInt(json['completed']),
    );
  }
}

class PurchasesPagination {
  const PurchasesPagination({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 15,
    this.total = 0,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory PurchasesPagination.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    return PurchasesPagination(
      currentPage: toInt(json['current_page']),
      lastPage: toInt(json['last_page']),
      perPage: toInt(json['per_page']),
      total: toInt(json['total']),
    );
  }
}

class PurchasesListData {
  const PurchasesListData({
    this.items = const [],
    this.pagination,
    this.summary,
  });

  final List<Purchase> items;
  final PurchasesPagination? pagination;
  final PurchasesSummary? summary;

  factory PurchasesListData.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return PurchasesListData(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map>()
              .map((e) => Purchase.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      pagination: json['pagination'] is Map
          ? PurchasesPagination.fromJson(
              Map<String, dynamic>.from(json['pagination'] as Map),
            )
          : null,
      summary: json['summary'] is Map
          ? PurchasesSummary.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map),
            )
          : null,
    );
  }
}

class PurchasesListResponse {
  const PurchasesListResponse({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final PurchasesListData? data;

  factory PurchasesListResponse.fromJson(Map<String, dynamic> json) {
    return PurchasesListResponse(
      success: json['success'] as bool?,
      message: json['message']?.toString(),
      data: json['data'] is Map
          ? PurchasesListData.fromJson(
              Map<String, dynamic>.from(json['data'] as Map),
            )
          : null,
    );
  }
}

String formatPurchaseImageDateTime(DateTime dateTime) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '${dateTime.day.toString().padLeft(2, '0')} ${months[dateTime.month - 1]} ${dateTime.year}, $hour:$minute $period';
}

const kPurchaseItemOptions = [
  'Rassi Bundle',
  'Clip',
  'Cement OPC',
  'Sanitary Goods',
  'Petrol',
  'Diesel',
  'TMT bars 12mm',
  'TMT 10 mm',
];

const kKantaSlipOptions = ['Without Kanta', 'With Kanta', 'Other'];

const kMaterialUnits = ['NOS', 'Bag', 'KG', 'MT', 'CUM', 'Litre'];

String get kPurchaseItemOptionsTitle => kPurchaseItemOptions.join(' / ');

final kMockPurchases = [
  Purchase(
    id: 'PUR-5001',
    date: DateTime(2026, 6, 17),
    challanNo: 'MH-14-CD-3310',
    invoiceNo: 'INV-8821',
    supplierName: 'Sharma Building Supplies',
    status: PurchaseStatus.pending,
    flowType: PurchaseFlowType.withKanta,
    vehicleNo: 'MH-14-CD-3310',
    loadingVehicleImage: 'loading_vehicle_3310.jpg',
    loadingVehicleImageAt: DateTime(2026, 6, 17, 9, 15),
    unloadingVehicleImage: 'unloading_vehicle_3310.jpg',
    unloadingVehicleImageAt: DateTime(2026, 6, 17, 11, 40),
    kantaSlipImage: 'kanta_slip_3310.jpg',
    kantaSlipImageAt: DateTime(2026, 6, 17, 12, 5),
    kantaNo: 'KNT-3310',
    vehicleAtKantaImage: 'vehicle_at_kanta_3310.jpg',
    vehicleAtKantaImageAt: DateTime(2026, 6, 17, 12, 20),
    withKantaStage: WithKantaStage.completed,
    materials: const [PurchaseMaterialItem(name: 'Cement OPC', qty: 50, unit: 'NOS')],
    itemName: 'Cement OPC',
  ),
  Purchase(
    id: 'PUR-5002',
    date: DateTime(2026, 6, 16),
    challanNo: 'DL-04-CA-7788',
    invoiceNo: '—',
    supplierName: 'Metro Steel Traders',
    status: PurchaseStatus.pending,
    flowType: PurchaseFlowType.withKanta,
    vehicleNo: 'DL-04-CA-7788',
    loadingVehicleImage: 'loading_vehicle_7788.jpg',
    loadingVehicleImageAt: DateTime(2026, 6, 16, 8, 30),
    withKantaStage: WithKantaStage.initial,
    materials: const [
      PurchaseMaterialItem(name: 'TMT bars 12mm'),
    ],
    itemName: 'TMT bars 12mm',
  ),
  Purchase(
    id: 'PUR-5007',
    date: DateTime(2026, 6, 16),
    challanNo: 'KA-05-EF-9921',
    invoiceNo: '—',
    supplierName: 'Granite World Pvt Ltd',
    status: PurchaseStatus.pending,
    flowType: PurchaseFlowType.withKanta,
    vehicleNo: 'KA-05-EF-9921',
    loadingVehicleImage: 'loading_vehicle_9921.jpg',
    loadingVehicleImageAt: DateTime(2026, 6, 16, 10, 0),
    unloadingVehicleImage: 'unloading_vehicle_9921.jpg',
    unloadingVehicleImageAt: DateTime(2026, 6, 16, 14, 25),
    withKantaStage: WithKantaStage.processing,
    materials: const [PurchaseMaterialItem(name: 'Clip')],
    itemName: 'Clip',
  ),
  Purchase(
    id: 'PUR-5003',
    date: DateTime(2026, 6, 15),
    challanNo: 'MH-12-AB-4521',
    invoiceNo: '—',
    supplierName: 'Rainbow Paints & Hardware',
    status: PurchaseStatus.pending,
    flowType: PurchaseFlowType.withoutKanta,
    vehicleNo: 'MH-12-AB-4521',
    loadingVehicleImage: 'loading_vehicle_4521.jpg',
    loadingVehicleImageAt: DateTime(2026, 6, 15, 7, 45),
    withoutKantaStage: WithoutKantaStage.initial,
    materials: const [
      PurchaseMaterialItem(name: 'Clip'),
      PurchaseMaterialItem(name: 'Sanitary Goods'),
    ],
    itemName: 'Clip, Sanitary Goods',
  ),
  Purchase(
    id: 'PUR-5004',
    date: DateTime(2026, 6, 14),
    challanNo: 'CH-240614-09',
    invoiceNo: 'INV-8790',
    supplierName: 'Granite World Pvt Ltd',
    status: PurchaseStatus.received,
    flowType: PurchaseFlowType.withKanta,
  ),
  Purchase(
    id: 'PUR-5006',
    date: DateTime(2026, 6, 13),
    challanNo: 'GJ-01-XY-8890',
    invoiceNo: 'INV-8765',
    supplierName: 'Sharma Building Supplies',
    status: PurchaseStatus.pending,
    flowType: PurchaseFlowType.withoutKanta,
    vehicleNo: 'GJ-01-XY-8890',
    loadingVehicleImage: 'loading_vehicle_8890.jpg',
    loadingVehicleImageAt: DateTime(2026, 6, 13, 9, 10),
    unloadingVehicleImage: 'unloading_vehicle_8890.jpg',
    unloadingVehicleImageAt: DateTime(2026, 6, 13, 16, 50),
    withoutKantaStage: WithoutKantaStage.completed,
    remark: 'Delivered on time',
    materials: const [
      PurchaseMaterialItem(name: 'Clip', qty: 120, unit: 'NOS'),
      PurchaseMaterialItem(name: 'Sanitary Goods', qty: 45, unit: 'NOS'),
    ],
    itemName: 'Clip, Sanitary Goods',
  ),
  Purchase(
    id: 'PUR-5008',
    date: DateTime(2026, 6, 12),
    challanNo: 'RJ-14-MN-2201',
    invoiceNo: '—',
    supplierName: 'Sankar',
    status: PurchaseStatus.pending,
    flowType: PurchaseFlowType.direct,
    vehicleNo: 'RJ-14-MN-2201',
    loadingVehicleImage: 'vehicle_direct_2201.jpg',
    loadingVehicleImageAt: DateTime(2026, 6, 12, 11, 20),
    directPurchaseStage: DirectPurchaseStage.completed,
    remark: 'Direct entry',
    materials: const [PurchaseMaterialItem(name: 'Clip', qty: 12, unit: 'Ton')],
    itemName: 'Clip',
  ),
];
