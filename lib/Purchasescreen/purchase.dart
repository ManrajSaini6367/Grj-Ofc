enum PurchaseStatus { pending, approved, received, cancelled }

class Purchase {
  const Purchase({
    required this.id,
    required this.date,
    required this.challanNo,
    required this.invoiceNo,
    required this.supplierName,
    required this.status,
    required this.hasKantaSlip,
    this.remark,
  });

  final String id;
  final DateTime date;
  final String challanNo;
  final String invoiceNo;
  final String supplierName;
  final PurchaseStatus status;
  final bool hasKantaSlip;
  final String? remark;

  String get statusLabel => switch (status) {
        PurchaseStatus.pending => 'Pending',
        PurchaseStatus.approved => 'Approved',
        PurchaseStatus.received => 'Received',
        PurchaseStatus.cancelled => 'Cancelled',
      };
}

final kMockPurchases = [
  Purchase(
    id: 'PUR-5001',
    date: DateTime(2026, 6, 17),
    challanNo: 'CH-240617-01',
    invoiceNo: 'INV-8821',
    supplierName: 'Sharma Building Supplies',
    status: PurchaseStatus.received,
    hasKantaSlip: true,
    remark: 'Cement delivery — Site A',
  ),
  Purchase(
    id: 'PUR-5002',
    date: DateTime(2026, 6, 16),
    challanNo: 'CH-240616-04',
    invoiceNo: 'INV-8815',
    supplierName: 'Metro Steel Traders',
    status: PurchaseStatus.approved,
    hasKantaSlip: true,
    remark: 'TMT rods 12mm',
  ),
  Purchase(
    id: 'PUR-5003',
    date: DateTime(2026, 6, 15),
    challanNo: 'CH-240615-02',
    invoiceNo: '—',
    supplierName: 'Rainbow Paints & Hardware',
    status: PurchaseStatus.pending,
    hasKantaSlip: false,
    remark: 'Paint & electrical wire',
  ),
  Purchase(
    id: 'PUR-5004',
    date: DateTime(2026, 6, 14),
    challanNo: 'CH-240614-09',
    invoiceNo: 'INV-8790',
    supplierName: 'Granite World Pvt Ltd',
    status: PurchaseStatus.received,
    hasKantaSlip: true,
  ),
  Purchase(
    id: 'PUR-5005',
    date: DateTime(2026, 6, 12),
    challanNo: 'CH-240612-01',
    invoiceNo: 'INV-8772',
    supplierName: 'Sharma Building Supplies',
    status: PurchaseStatus.cancelled,
    hasKantaSlip: false,
    remark: 'Order cancelled — duplicate entry',
  ),
];
