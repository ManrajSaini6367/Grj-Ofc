enum PurchaseStatus { pending, approved, received, cancelled }

enum WithoutKantaStage { initial, completed }

enum WithKantaStage { initial, processing, completed }

enum DirectPurchaseStage { completed }

enum PurchaseFlowType { withKanta, withoutKanta, direct }

class PurchaseMaterialItem {
  const PurchaseMaterialItem({
    required this.name,
    this.qty,
    this.unit = 'NOS',
  });

  final String name;
  final double? qty;
  final String unit;

  String get displayLabel {
    if (qty == null) return name;
    final q = qty! == qty!.roundToDouble() ? qty!.toInt().toString() : qty.toString();
    return '$name — $q $unit';
  }
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
