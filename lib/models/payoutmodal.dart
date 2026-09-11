import 'package:grjoffice_apps/payoutscreen/salary_calculator.dart';

class PayoutRegisterResponse {
  const PayoutRegisterResponse({this.success, this.message, this.data});

  final bool? success;
  final String? message;
  final PayoutRegisterData? data;

  factory PayoutRegisterResponse.fromJson(Map<String, dynamic> json) {
    return PayoutRegisterResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map
          ? PayoutRegisterData.fromJson(Map<String, dynamic>.from(json['data']))
          : null,
    );
  }
}

class PayoutRegisterData {
  const PayoutRegisterData({
    this.month,
    this.siteId,
    this.siteName,
    this.summary,
    this.items = const [],
  });

  final String? month;
  final int? siteId;
  final String? siteName;
  final PayoutSummary? summary;
  final List<PayoutRow> items;

  factory PayoutRegisterData.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return PayoutRegisterData(
      month: json['month']?.toString(),
      siteId: _toInt(json['site_id']),
      siteName: json['site_name']?.toString(),
      summary: json['summary'] is Map
          ? PayoutSummary.fromJson(Map<String, dynamic>.from(json['summary']))
          : null,
      items: raw is List
          ? raw
                .whereType<Map>()
                .map((row) => PayoutRow.fromJson(Map<String, dynamic>.from(row)))
                .toList()
          : const [],
    );
  }
}

class PayoutSummary {
  const PayoutSummary({
    this.employees = 0,
    this.salaryCount = 0,
    this.totalGross = 0,
    this.totalDeduction = 0,
    this.totalNet = 0,
  });

  final int employees;
  final int salaryCount;
  final double totalGross;
  final double totalDeduction;
  final double totalNet;

  factory PayoutSummary.fromJson(Map<String, dynamic> json) {
    return PayoutSummary(
      employees: _toInt(json['employees']) ?? 0,
      salaryCount: _toInt(json['salary_count']) ?? 0,
      totalGross: _toDouble(json['total_gross']) ?? 0,
      totalDeduction: _toDouble(json['total_deduction']) ?? 0,
      totalNet: _toDouble(json['total_net']) ?? 0,
    );
  }
}

class PayoutSheetResponse {
  const PayoutSheetResponse({this.success, this.message, this.data});

  final bool? success;
  final String? message;
  final PayoutSheetData? data;

  factory PayoutSheetResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    Map<String, dynamic>? payload;
    if (raw is Map) {
      payload = Map<String, dynamic>.from(raw);
      if (payload['sheet'] is Map && payload['employee'] is Map) {
        // GET /payouts/sheet
      } else if (payload['sheet'] is Map) {
        final nested = payload['sheet'];
        if (nested is Map) payload = Map<String, dynamic>.from(nested);
      }
    }
    return PayoutSheetResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: payload == null ? null : PayoutSheetData.fromJson(payload),
    );
  }
}

class PayoutSheetData {
  const PayoutSheetData({
    required this.employee,
    this.attendance,
    this.sheet,
    this.saved = false,
    this.salaryId,
  });

  final PayoutRow employee;
  final PayoutRow? attendance;
  final SalarySheet? sheet;
  final bool saved;
  final int? salaryId;

  factory PayoutSheetData.fromJson(Map<String, dynamic> json) {
    final employeeJson = json['employee'] is Map
        ? Map<String, dynamic>.from(json['employee'])
        : json;
    final attendanceJson = json['attendance'] is Map
        ? Map<String, dynamic>.from(json['attendance'])
        : const <String, dynamic>{};
    return PayoutSheetData(
      employee: PayoutRow.fromJson({...attendanceJson, ...employeeJson}),
      attendance: attendanceJson.isEmpty
          ? null
          : PayoutRow.fromJson(attendanceJson),
      sheet: json['sheet'] is Map
          ? SalarySheet.fromJson(Map<String, dynamic>.from(json['sheet']))
          : null,
      saved: json['saved'] == true,
      salaryId: _toInt(json['salary_id']),
    );
  }
}

class SalarySheet {
  const SalarySheet({
    this.monthDays,
    this.actualDays,
    this.paidLeave,
    this.previousLeaves,
    this.payableDays,
    this.balanceLeave,
    this.absentDays,
    this.monthlyPackage,
    this.basicPercent,
    this.pfApplicable,
    this.esiApplicable,
    this.otherDeduction,
    this.accommodationPaidBy,
    this.foodPaidBy,
    this.foodAmount,
    this.leavesRemark,
    this.remarks,
    this.earnedBasic,
    this.earnedHra,
    this.earnedGross,
    this.pf,
    this.esi,
    this.totalDeduction,
    this.netPayable,
  });

  final int? monthDays;
  final double? actualDays;
  final double? paidLeave;
  final double? previousLeaves;
  final double? payableDays;
  final double? balanceLeave;
  final double? absentDays;
  final double? monthlyPackage;
  final double? basicPercent;
  final bool? pfApplicable;
  final bool? esiApplicable;
  final double? otherDeduction;
  final String? accommodationPaidBy;
  final String? foodPaidBy;
  final double? foodAmount;
  final String? leavesRemark;
  final String? remarks;
  final double? earnedBasic;
  final double? earnedHra;
  final double? earnedGross;
  final double? pf;
  final double? esi;
  final double? totalDeduction;
  final double? netPayable;

  factory SalarySheet.fromJson(Map<String, dynamic> json) {
    return SalarySheet(
      monthDays: _toInt(json['month_days']),
      actualDays: _toDouble(json['actual_days']),
      paidLeave: _toDouble(json['paid_leave']),
      previousLeaves: _toDouble(json['previous_leaves']),
      payableDays: _toDouble(json['payable_days']),
      balanceLeave: _toDouble(json['balance_leave']),
      absentDays: _toDouble(json['absent_days']),
      monthlyPackage: _toDouble(json['monthly_package']),
      basicPercent: _toDouble(json['basic_percent']),
      pfApplicable: json['pf_applicable'] == null
          ? null
          : json['pf_applicable'] == true || json['pf_applicable'] == 1,
      esiApplicable: json['esi_applicable'] == null
          ? null
          : json['esi_applicable'] == true || json['esi_applicable'] == 1,
      otherDeduction: _toDouble(json['other_deduction']),
      accommodationPaidBy: json['accommodation_paid_by']?.toString(),
      foodPaidBy: json['food_paid_by']?.toString(),
      foodAmount: _toDouble(json['food_amount']),
      leavesRemark: json['leaves_remark']?.toString(),
      remarks: json['remarks']?.toString(),
      earnedBasic: _toDouble(json['earned_basic']),
      earnedHra: _toDouble(json['earned_hra']),
      earnedGross: _toDouble(json['earned_gross']),
      pf: _toDouble(json['pf']),
      esi: _toDouble(json['esi']),
      totalDeduction: _toDouble(json['total_deduction']),
      netPayable: _toDouble(json['net_payable']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (monthDays != null) 'month_days': monthDays,
    if (actualDays != null) 'actual_days': actualDays,
    if (paidLeave != null) 'paid_leave': paidLeave,
    if (previousLeaves != null) 'previous_leaves': previousLeaves,
    if (payableDays != null) 'payable_days': payableDays,
    if (balanceLeave != null) 'balance_leave': balanceLeave,
    if (absentDays != null) 'absent_days': absentDays,
    if (monthlyPackage != null) 'monthly_package': monthlyPackage,
    if (basicPercent != null) 'basic_percent': basicPercent,
    if (pfApplicable != null) 'pf_applicable': pfApplicable,
    if (esiApplicable != null) 'esi_applicable': esiApplicable,
    if (otherDeduction != null) 'other_deduction': otherDeduction,
    if (accommodationPaidBy != null)
      'accommodation_paid_by': accommodationPaidBy,
    if (foodPaidBy != null) 'food_paid_by': foodPaidBy,
    if (foodAmount != null) 'food_amount': foodAmount,
    if (leavesRemark != null) 'leaves_remark': leavesRemark,
    if (remarks != null) 'remarks': remarks,
  };
}

class PayoutRow {
  const PayoutRow({
    this.employeeId,
    this.name,
    this.username,
    this.designation,
    this.dateOfJoin,
    this.monthlySalary,
    this.leaveAllocation,
    this.bankName,
    this.accountNumber,
    this.accountHolderName,
    this.stayAllowanceType,
    this.foodAllowanceType,
    this.foodCompanyAmount,
    this.foodEmployeeAmount,
    this.presentDays,
    this.leaveDays,
    this.holidayDays,
    this.absentDays,
    this.monthDays,
    this.payableDays,
    this.package,
    this.earnedGross,
    this.totalDeduction,
    this.netPayable,
    this.saved = false,
    this.salaryId,
  });

  final int? employeeId;
  final String? name;
  final String? username;
  final String? designation;
  final String? dateOfJoin;
  final double? monthlySalary;
  final int? leaveAllocation;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final String? stayAllowanceType;
  final String? foodAllowanceType;
  final double? foodCompanyAmount;
  final double? foodEmployeeAmount;
  final int? presentDays;
  final int? leaveDays;
  final int? holidayDays;
  final int? absentDays;
  final int? monthDays;
  final double? payableDays;
  final double? package;
  final double? earnedGross;
  final double? totalDeduction;
  final double? netPayable;
  final bool saved;
  final int? salaryId;

  factory PayoutRow.fromJson(Map<String, dynamic> json) {
    return PayoutRow(
      employeeId: _toInt(json['employee_id'] ?? json['id']),
      name: json['name']?.toString(),
      username: json['username']?.toString(),
      designation: json['designation']?.toString(),
      dateOfJoin: json['date_of_join']?.toString(),
      monthlySalary: _toDouble(json['monthly_salary']),
      leaveAllocation: _toInt(json['leave_allocation']),
      bankName: json['bank_name']?.toString(),
      accountNumber: json['account_number']?.toString(),
      accountHolderName: json['account_holder_name']?.toString(),
      stayAllowanceType: json['stay_allowance_type']?.toString(),
      foodAllowanceType: json['food_allowance_type']?.toString(),
      foodCompanyAmount: _toDouble(json['food_company_amount']),
      foodEmployeeAmount: _toDouble(json['food_employee_amount']),
      presentDays: _toInt(json['present_days']),
      leaveDays: _toInt(json['leave_days']),
      holidayDays: _toInt(json['holiday_days']),
      absentDays: _toInt(json['absent_days']),
      monthDays: _toInt(json['month_days']),
      payableDays: _toDouble(json['payable_days']),
      package: _toDouble(json['package'] ?? json['monthly_package']),
      earnedGross: _toDouble(json['earned_gross']),
      totalDeduction: _toDouble(json['total_deduction']),
      netPayable: _toDouble(json['net_payable']),
      saved: json['saved'] == true,
      salaryId: _toInt(json['salary_id']),
    );
  }

  SalaryBreakdown? get breakdown {
    final amount = package ?? monthlySalary;
    if (amount == null || amount <= 0) return null;
    final days = monthDays ?? 30;
    final payable =
        payableDays ??
        ((presentDays ?? 0) + (leaveDays ?? 0) + (holidayDays ?? 0)).toDouble();
    return SalaryBreakdown.from(
      withStatutoryDefaults(
        SalaryInput(
          monthlyPackage: amount,
          monthDays: days,
          payableDays: payable,
        ),
      ),
    );
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
