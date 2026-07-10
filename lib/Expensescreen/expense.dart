import 'package:grjoffice_apps/models/pagination_model.dart';

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
    this.challanNo,
    this.remark,
    this.detail,
    this.siteId,
    this.siteName,
    this.source,
    this.balanceAmount,
    this.updatedAt,
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
  final String? challanNo;
  final String? remark;
  final String? detail;
  final int? siteId;
  final String? siteName;
  final String? source;
  final double? balanceAmount;
  final DateTime? updatedAt;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: (json['id'] ?? '').toString(),
      date: _parseDateTime(json['created_at']) ?? DateTime.now(),
      title: json['title']?.toString() ?? json['detail']?.toString() ?? '',
      category: _categoryFromApi(json['category']?.toString()),
      amount: _toDouble(json['amount']),
      paidTo: json['paid_to']?.toString() ?? '—',
      paymentMode: _paymentModeFromApi(
        json['payment_mode']?.toString() ?? json['source']?.toString(),
      ),
      status: _statusFromApi(json['status']?.toString()),
      entryType: _entryTypeFromApi(
        json['entry_type']?.toString() ?? json['type']?.toString(),
      ),
      chequeNo: json['cheque_no']?.toString(),
      voucherNo: json['voucher_no']?.toString(),
      challanNo: json['challan_no']?.toString(),
      remark: json['remark']?.toString(),
      detail: json['detail']?.toString(),
      siteId: json['site_id'] as int?,
      siteName: json['site_name']?.toString(),
      source: json['source']?.toString(),
      balanceAmount: json['balance_amount'] == null
          ? null
          : _toDouble(json['balance_amount']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? id,
      'site_id': siteId,
      'site_name': siteName,
      'title': title,
      'detail': detail ?? title,
      'category': category.name,
      'amount': amount,
      'paid_to': paidTo,
      'payment_mode': paymentMode.name,
      'source': source ?? paymentMode.name,
      'status': status.name,
      'entry_type': entryType?.name,
      'type': entryType?.name,
      'cheque_no': chequeNo,
      'voucher_no': voucherNo,
      'challan_no': challanNo,
      'remark': remark,
      'balance_amount': balanceAmount,
      'created_at': date.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

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

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static ExpenseCategory _categoryFromApi(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'transport':
        return ExpenseCategory.transport;
      case 'labour':
        return ExpenseCategory.labour;
      case 'material':
        return ExpenseCategory.material;
      case 'utilities':
        return ExpenseCategory.utilities;
      case 'miscellaneous':
      default:
        return ExpenseCategory.miscellaneous;
    }
  }

  static ExpensePaymentMode _paymentModeFromApi(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'cash':
        return ExpensePaymentMode.cash;
      case 'upi':
        return ExpensePaymentMode.upi;
      case 'cheque':
        return ExpensePaymentMode.cheque;
      case 'bank':
      case 'bank_transfer':
      case 'bank transfer':
      default:
        return ExpensePaymentMode.bank;
    }
  }

  static ExpenseStatus _statusFromApi(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'pending':
        return ExpenseStatus.pending;
      case 'approved':
        return ExpenseStatus.approved;
      case 'paid':
      default:
        return ExpenseStatus.paid;
    }
  }

  static ExpenseEntryType? _entryTypeFromApi(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'credit':
        return ExpenseEntryType.credit;
      case 'debit':
        return ExpenseEntryType.debit;
      default:
        return null;
    }
  }
}

class ExpensesListData {
  const ExpensesListData({
    required this.items,
    this.pagination,
    this.totalAmount = 0,
  });

  final List<Expense> items;
  final PaginationModel? pagination;
  final double totalAmount;

  factory ExpensesListData.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return ExpensesListData(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(Expense.fromJson)
              .toList()
          : const <Expense>[],
      pagination: json['pagination'] is Map<String, dynamic>
          ? PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
      totalAmount: Expense._toDouble(json['total_amount']),
    );
  }
}

class ExpensesListResponse {
  const ExpensesListResponse({
    required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String? message;
  final ExpensesListData? data;

  factory ExpensesListResponse.fromJson(Map<String, dynamic> json) {
    return ExpensesListResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? ExpensesListData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
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
