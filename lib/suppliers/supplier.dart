enum SupplierStatus { published, unpublished }

class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.mobile,
    required this.materials,
    required this.gstNo,
    required this.panNo,
    required this.address,
    this.status = SupplierStatus.published,
  });

  final String id;
  final String name;
  final String mobile;
  final List<String> materials;
  final String gstNo;
  final String panNo;
  final String address;
  final SupplierStatus status;
}

const kAvailableMaterials = [
  'Cement',
  'Steel Rods',
  'Sand',
  'Bricks',
  'Paint',
  'Plywood',
  'Aggregate',
  'Tiles',
  'Electrical Wire',
  'PVC Pipes',
  'Glass',
  'Aluminium Sections',
  'Waterproofing Compound',
  'Ready Mix Concrete',
  'Granite Slabs',
];

const kMockSuppliers = [
  Supplier(
    id: 'SUP-1001',
    name: 'Sharma Building Supplies',
    mobile: '+91 98765 43210',
    materials: ['Cement', 'Sand', 'Bricks'],
    gstNo: '27AABCS1429B1Z5',
    panNo: 'AABCS1429B',
    address: 'Plot 12, Industrial Area, Phase 2, Pune',
  ),
  Supplier(
    id: 'SUP-1002',
    name: 'Metro Steel Traders',
    mobile: '+91 91234 56789',
    materials: ['Steel Rods', 'Aluminium Sections'],
    gstNo: '29AACCM1234A1Z8',
    panNo: 'AACCM1234A',
    address: '45, MIDC Road, Nashik',
    status: SupplierStatus.unpublished,
  ),
  Supplier(
    id: 'SUP-1003',
    name: 'Rainbow Paints & Hardware',
    mobile: '+91 99887 76655',
    materials: ['Paint', 'Electrical Wire', 'PVC Pipes'],
    gstNo: '07AAACR5678C1Z2',
    panNo: 'AAACR5678C',
    address: 'Shop 8, Market Complex, Delhi',
  ),
  Supplier(
    id: 'SUP-1004',
    name: 'Granite World Pvt Ltd',
    mobile: '+91 98123 45678',
    materials: ['Granite Slabs', 'Tiles'],
    gstNo: '33AABCG9012D1Z6',
    panNo: 'AABCG9012D',
    address: 'Survey No. 88, Hosur Road, Bengaluru',
  ),
];
