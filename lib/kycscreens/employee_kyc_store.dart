import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grjoffice_apps/core/preference.dart';

class EmployeeKycConfig {
  const EmployeeKycConfig({
    required this.employeeId,
    required this.foodAllowance,
    required this.stayAllowance,
    required this.emergencyContact,
    required this.configuredAt,
    this.employeeName = '',
    this.email = '',
    this.phoneNumber = '',
    this.assignedSite = '',
    this.monthlySalary = '',
    this.leaveAllocation = '',
    this.employmentType = '',
    this.joiningDate = '',
    this.foodAllowanceType = '',
    this.foodEmployeeAmount = '',
    this.stayAllowanceType = '',
    this.stayEmployeeAmount = '',
    this.panPath = '',
    this.aadhaarFrontPath = '',
    this.aadhaarBackPath = '',
    this.marksheet10Path = '',
    this.marksheet12Path = '',
    this.accountHolderName = '',
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.bankChequePath = '',
    this.status = 'Submitted',
    this.kycId = 0,
  });

  final String employeeId;
  final String employeeName;
  final String email;
  final String phoneNumber;
  final String assignedSite;
  final String monthlySalary;
  final String leaveAllocation;
  final String employmentType;
  final String joiningDate;
  final bool foodAllowance;
  final String foodAllowanceType;
  final String foodEmployeeAmount;
  final bool stayAllowance;
  final String stayAllowanceType;
  final String stayEmployeeAmount;
  final String emergencyContact;
  final String panPath;
  final String aadhaarFrontPath;
  final String aadhaarBackPath;
  final String marksheet10Path;
  final String marksheet12Path;
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String bankChequePath;
  final DateTime configuredAt;
  final String status;
  final int kycId;

  String get foodTypeLabel {
    if (!foodAllowance) return 'No';
    if (foodAllowanceType == 'amount') {
      return foodEmployeeAmount.isEmpty
          ? 'Amount'
          : 'Amount ₹ $foodEmployeeAmount';
    }
    return 'Company Mess';
  }

  String get stayTypeLabel {
    if (!stayAllowance) return 'No';
    if (stayAllowanceType == 'amount') {
      return stayEmployeeAmount.isEmpty
          ? 'Amount'
          : 'Amount ₹ $stayEmployeeAmount';
    }
    return 'Company Hostel';
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'email': email,
        'phoneNumber': phoneNumber,
        'assignedSite': assignedSite,
        'monthlySalary': monthlySalary,
        'leaveAllocation': leaveAllocation,
        'employmentType': employmentType,
        'joiningDate': joiningDate,
        'foodAllowance': foodAllowance,
        'foodAllowanceType': foodAllowanceType,
        'foodEmployeeAmount': foodEmployeeAmount,
        'stayAllowance': stayAllowance,
        'stayAllowanceType': stayAllowanceType,
        'stayEmployeeAmount': stayEmployeeAmount,
        'emergencyContact': emergencyContact,
        'panPath': panPath,
        'aadhaarFrontPath': aadhaarFrontPath,
        'aadhaarBackPath': aadhaarBackPath,
        'marksheet10Path': marksheet10Path,
        'marksheet12Path': marksheet12Path,
        'accountHolderName': accountHolderName,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'bankChequePath': bankChequePath,
        'savedAt': configuredAt.toIso8601String(),
        'status': status,
        'kycId': kycId,
      };

  factory EmployeeKycConfig.fromJson(Map<String, dynamic> json) {
    return EmployeeKycConfig(
      employeeId: json['employeeId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      assignedSite: json['assignedSite']?.toString() ?? '',
      monthlySalary: json['monthlySalary']?.toString() ?? '',
      leaveAllocation: json['leaveAllocation']?.toString() ?? '',
      employmentType: json['employmentType']?.toString() ?? '',
      joiningDate: json['joiningDate']?.toString() ?? '',
      foodAllowance: json['foodAllowance'] == true,
      foodAllowanceType: json['foodAllowanceType']?.toString() ?? '',
      foodEmployeeAmount: (json['foodEmployeeAmount'] ??
              json['foodAllowanceAmount'])
          ?.toString() ??
          '',
      stayAllowance: json['stayAllowance'] == true,
      stayAllowanceType: json['stayAllowanceType']?.toString() ?? '',
      stayEmployeeAmount: (json['stayEmployeeAmount'] ??
              json['stayAllowanceAmount'])
          ?.toString() ??
          '',
      emergencyContact: json['emergencyContact']?.toString() ?? '',
      panPath: json['panPath']?.toString() ?? '',
      aadhaarFrontPath: json['aadhaarFrontPath']?.toString() ?? '',
      aadhaarBackPath: json['aadhaarBackPath']?.toString() ?? '',
      marksheet10Path: json['marksheet10Path']?.toString() ?? '',
      marksheet12Path: json['marksheet12Path']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      bankChequePath: json['bankChequePath']?.toString() ?? '',
      configuredAt: DateTime.tryParse('${json['savedAt']}') ??
          DateTime.tryParse('${json['configuredAt']}') ??
          DateTime.now(),
      status: json['status']?.toString().trim().isNotEmpty == true
          ? json['status'].toString()
          : 'Submitted',
      kycId: int.tryParse('${json['kycId'] ?? json['id'] ?? 0}') ?? 0,
    );
  }

  EmployeeKycConfig copyWith({
    String? status,
    int? kycId,
  }) {
    return EmployeeKycConfig(
      employeeId: employeeId,
      employeeName: employeeName,
      email: email,
      phoneNumber: phoneNumber,
      assignedSite: assignedSite,
      monthlySalary: monthlySalary,
      leaveAllocation: leaveAllocation,
      employmentType: employmentType,
      joiningDate: joiningDate,
      foodAllowance: foodAllowance,
      foodAllowanceType: foodAllowanceType,
      foodEmployeeAmount: foodEmployeeAmount,
      stayAllowance: stayAllowance,
      stayAllowanceType: stayAllowanceType,
      stayEmployeeAmount: stayEmployeeAmount,
      emergencyContact: emergencyContact,
      panPath: panPath,
      aadhaarFrontPath: aadhaarFrontPath,
      aadhaarBackPath: aadhaarBackPath,
      marksheet10Path: marksheet10Path,
      marksheet12Path: marksheet12Path,
      accountHolderName: accountHolderName,
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      bankChequePath: bankChequePath,
      configuredAt: configuredAt,
      status: status ?? this.status,
      kycId: kycId ?? this.kycId,
    );
  }
}

/// Shared local store for Employee KYC submissions.
class EmployeeKycStore extends ChangeNotifier {
  EmployeeKycStore._();
  static final EmployeeKycStore instance = EmployeeKycStore._();

  static const prefsKey = 'employee_kyc_configs_v1';

  final List<EmployeeKycConfig> _items = [];
  bool _loaded = false;

  List<EmployeeKycConfig> get items {
    final list = List<EmployeeKycConfig>.from(_items);
    list.sort((a, b) => b.configuredAt.compareTo(a.configuredAt));
    return list;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _load();
  }

  Future<void> _load() async {
    try {
      final raw = Preference.pref.getString(prefsKey);
      _items.clear();
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _items.add(EmployeeKycConfig.fromJson(item));
            } else if (item is Map) {
              _items.add(
                EmployeeKycConfig.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[EmployeeKycStore] load error: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final payload = jsonEncode(_items.map((e) => e.toJson()).toList());
    await Preference.pref.setString(prefsKey, payload);
  }

  Future<void> save(EmployeeKycConfig config) async {
    await ensureLoaded();
    _items.removeWhere((e) => e.employeeId == config.employeeId);
    _items.insert(0, config);
    await _persist();
    notifyListeners();
  }

  EmployeeKycConfig? byEmployeeId(String id) {
    for (final e in _items) {
      if (e.employeeId == id) return e;
    }
    return null;
  }
}
