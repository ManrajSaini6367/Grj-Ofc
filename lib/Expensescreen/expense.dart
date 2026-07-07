enum ExpenseStatus { pending, approved, paid }

enum ExpenseCategory {
  transport,
  labour,
  material,
  utilities,
  miscellaneous,
}

enum ExpensePaymentMode { cash, upi, bank, cheque }

enum ExpenseEntryType { credit, debit }

const kExpenseEntryTypes = ['Credit', 'Debit'];

const kExpenseSources = ['Cash', 'Cheque', 'UPI', 'Bank Transfer'];

class Expense {
  const Expense({
    required this.id,
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
    required this.paidTo,
    required this.paymentMode,
    required this.status,
    this.entryType,
    this.chequeNo,
    this.voucherNo,
    this.remark,
    this.siteName,
  });

  final String id;
  final DateTime date;
  final String title;
  final ExpenseCategory category;
  final double amount;
  final String paidTo;
  final ExpensePaymentMode paymentMode;
  final ExpenseStatus status;
  final ExpenseEntryType? entryType;
  final String? chequeNo;
  final String? voucherNo;
  final String? remark;
  final String? siteName;

  String get statusLabel => switch (status) {
        ExpenseStatus.pending => 'Pending',
        ExpenseStatus.approved => 'Approved',
        ExpenseStatus.paid => 'Paid',
      };

  String get categoryLabel => switch (category) {
        ExpenseCategory.transport => 'Transport',
        ExpenseCategory.labour => 'Labour',
        ExpenseCategory.material => 'Material',
        ExpenseCategory.utilities => 'Utilities',
        ExpenseCategory.miscellaneous => 'Miscellaneous',
      };

  String get paymentModeLabel => switch (paymentMode) {
        ExpensePaymentMode.cash => 'Cash',
        ExpensePaymentMode.upi => 'UPI',
        ExpensePaymentMode.bank => 'Bank Transfer',
        ExpensePaymentMode.cheque => 'Cheque',
      };

  String? get entryTypeLabel => switch (entryType) {
        ExpenseEntryType.credit => 'Credit',
        ExpenseEntryType.debit => 'Debit',
        null => null,
      };
}

String formatExpenseAmount(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '₹$intPart.${parts[1]}';
}

String formatExpenseFormDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
}

ExpensePaymentMode expensePaymentModeFromSource(String source) => switch (source) {
      'Cash' => ExpensePaymentMode.cash,
      'Cheque' => ExpensePaymentMode.cheque,
      'UPI' => ExpensePaymentMode.upi,
      _ => ExpensePaymentMode.bank,
    };

String formatExpenseListDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

const kExpenseCategories = [
  'Transport',
  'Labour',
  'Material',
  'Utilities',
  'Miscellaneous',
];

final kMockExpenses = [
  Expense(
    id: 'EXP-3001',
    date: DateTime(2026, 7, 4),
    title: 'Site logistics transport',
    category: ExpenseCategory.transport,
    amount: 2400,
    paidTo: 'Ramesh Transport',
    paymentMode: ExpensePaymentMode.upi,
    status: ExpenseStatus.paid,
    remark: 'Material delivery to Site A',
    siteName: 'Site A',
  ),
  Expense(
    id: 'EXP-3002',
    date: DateTime(2026, 7, 4),
    title: 'Labour advance payment',
    category: ExpenseCategory.labour,
    amount: 15000,
    paidTo: 'Sunil Contractor',
    paymentMode: ExpensePaymentMode.bank,
    status: ExpenseStatus.approved,
    siteName: 'Site B',
  ),
  Expense(
    id: 'EXP-3003',
    date: DateTime(2026, 7, 3),
    title: 'Hardware purchase',
    category: ExpenseCategory.material,
    amount: 8750,
    paidTo: 'Rainbow Paints & Hardware',
    paymentMode: ExpensePaymentMode.cash,
    status: ExpenseStatus.pending,
    remark: 'Nails, binding wire, gloves',
  ),
  Expense(
    id: 'EXP-3004',
    date: DateTime(2026, 7, 3),
    title: 'Generator diesel',
    category: ExpenseCategory.utilities,
    amount: 5200,
    paidTo: 'HP Petrol Pump',
    paymentMode: ExpensePaymentMode.cash,
    status: ExpenseStatus.paid,
    siteName: 'Site A',
  ),
  Expense(
    id: 'EXP-3005',
    date: DateTime(2026, 7, 2),
    title: 'Office stationery',
    category: ExpenseCategory.miscellaneous,
    amount: 980,
    paidTo: 'City Stationers',
    paymentMode: ExpensePaymentMode.upi,
    status: ExpenseStatus.paid,
  ),
  Expense(
    id: 'EXP-3006',
    date: DateTime(2026, 7, 2),
    title: 'Safety helmets and vests',
    category: ExpenseCategory.material,
    amount: 3450,
    paidTo: 'Sharma Building Supplies',
    paymentMode: ExpensePaymentMode.bank,
    status: ExpenseStatus.paid,
    siteName: 'Site A',
  ),
  Expense(
    id: 'EXP-3007',
    date: DateTime(2026, 7, 1),
    title: 'Water tanker supply',
    category: ExpenseCategory.utilities,
    amount: 1800,
    paidTo: 'Aqua Services',
    paymentMode: ExpensePaymentMode.cash,
    status: ExpenseStatus.paid,
  ),
];
