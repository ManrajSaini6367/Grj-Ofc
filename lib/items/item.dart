enum ItemStatus { published, unpublished }

enum ItemTransactionType { credit, debit }

class ItemTransaction {
  const ItemTransaction({
    required this.qty,
    required this.unit,
    required this.type,
    this.issueTo,
    this.remark,
    required this.dateTime,
  });

  final double qty;
  final String unit;
  final ItemTransactionType type;
  final String? issueTo;
  final String? remark;
  final DateTime dateTime;

  String get typeLabel => type == ItemTransactionType.credit ? 'credit' : 'debit';
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    this.status = ItemStatus.published,
    this.directPurchase = false,
    this.dayReport = false,
    this.consumable = true,
    this.balance = 0,
    this.imageAsset,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String sku;
  final String unit;
  final ItemStatus status;
  final bool directPurchase;
  final bool dayReport;
  final bool consumable;
  final int balance;
  final String? imageAsset;
  final String? imageUrl;
}

const kAvailableUnits = [
  'Bag',
  'KG',
  'MT',
  'Nos',
  'Sq.Ft',
  'CUM',
  'Litre',
  'Box',
  'Roll',
  'Set',
];

const kMockItems = [
  InventoryItem(
    id: 'ITM-3001',
    name: 'OPC Cement 53 Grade',
    sku: 'CEM-OPC-53',
    unit: 'Bag',
    directPurchase: true,
    dayReport: true,
    consumable: true,
    imageUrl: 'https://images.unsplash.com/photo-1589939705382-41e2e66c2ab0?w=600&q=80',
  ),
  InventoryItem(
    id: 'ITM-3002',
    name: 'TMT Steel 12mm',
    sku: 'STL-TMT-12',
    unit: 'MT',
    status: ItemStatus.unpublished,
    directPurchase: false,
    dayReport: true,
    consumable: true,
    imageUrl: 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?w=600&q=80',
  ),
  InventoryItem(
    id: 'ITM-3003',
    name: 'River Sand',
    sku: 'SND-RVR-01',
    unit: 'CUM',
    directPurchase: true,
    dayReport: false,
    consumable: true,
    imageUrl: 'https://images.unsplash.com/photo-1618220313342-dbf3d4629d24?w=600&q=80',
  ),
  InventoryItem(
    id: 'ITM-3004',
    name: 'Safety Helmet',
    sku: 'PPE-HEL-01',
    unit: 'Nos',
    directPurchase: false,
    dayReport: false,
    consumable: false,
    imageUrl: 'https://images.unsplash.com/photo-1575905255778-2a6c338b6420?w=600&q=80',
  ),
  InventoryItem(
    id: 'ITM-3005',
    name: 'RASSI BUNDLE',
    sku: 'RAS-BND-01',
    unit: 'Nos',
    directPurchase: true,
    dayReport: true,
    consumable: true,
    imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
  ),
];

List<ItemTransaction> getItemTransactions(String itemId) {
  final unit = kMockItems.firstWhere((i) => i.id == itemId, orElse: () => kMockItems.first).unit;

  if (itemId == 'ITM-3004') {
    return [
      ItemTransaction(qty: 20, unit: unit, type: ItemTransactionType.credit, dateTime: DateTime(2026, 6, 10, 9, 30, 0)),
      ItemTransaction(qty: 5, unit: unit, type: ItemTransactionType.debit, issueTo: 'Site A', remark: 'Issued to workers', dateTime: DateTime(2026, 6, 12, 11, 15, 22)),
      ItemTransaction(qty: 3, unit: unit, type: ItemTransactionType.debit, issueTo: 'Used', remark: 'Damaged', dateTime: DateTime(2026, 6, 15, 14, 40, 10)),
    ];
  }

  if (itemId == 'ITM-3005') {
    return [
      ItemTransaction(qty: 10, unit: unit, type: ItemTransactionType.credit, dateTime: DateTime(2026, 6, 8, 10, 0, 0)),
      ItemTransaction(qty: 2, unit: unit, type: ItemTransactionType.debit, issueTo: 'Used', remark: 'Site work', dateTime: DateTime(2026, 6, 12, 15, 30, 0)),
      ItemTransaction(qty: 4, unit: unit, type: ItemTransactionType.debit, issueTo: 'Used', remark: 'Binding', dateTime: DateTime(2026, 6, 15, 11, 20, 0)),
    ];
  }

  return [
    ItemTransaction(qty: 10, unit: unit, type: ItemTransactionType.credit, dateTime: DateTime(2026, 6, 17, 12, 52, 22)),
    ItemTransaction(qty: 5, unit: unit, type: ItemTransactionType.debit, issueTo: 'Used', remark: 'Bike', dateTime: DateTime(2026, 6, 17, 11, 59, 31)),
    ItemTransaction(qty: 5, unit: unit, type: ItemTransactionType.debit, issueTo: 'Used', remark: 'Bike', dateTime: DateTime(2026, 6, 14, 11, 39, 37)),
    ItemTransaction(qty: 10, unit: unit, type: ItemTransactionType.credit, dateTime: DateTime(2026, 6, 11, 10, 17, 36)),
  ];
}

double getItemStockBalance(String itemId) {
  return getItemTransactions(itemId).fold<double>(0, (sum, tx) {
    if (tx.type == ItemTransactionType.credit) return sum + tx.qty;
    return sum - tx.qty;
  });
}

String formatStoreQty(double qty) {
  return qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(1);
}

String formatStoreUnit(String unit) => unit.toUpperCase();
