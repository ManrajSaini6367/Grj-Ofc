import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grjoffice_apps/core/preference.dart';

class EmployeeKycConfig {
  const EmployeeKycConfig({
    required this.employeeName,
    required this.employeeId,
    required this.role,
    required this.assignedSite,
    required this.monthlySalary,
    required this.leaveAllocation,
    required this.foodAllowance,
    required this.stayAllowance,
    required this.sundayOff,
    required this.employmentType,
    required this.joiningDate,
    required this.configuredAt,
    this.status = 'Configured',
  });

  final String employeeName;
  final String employeeId;
  final String role;
  final String assignedSite;
  final String monthlySalary;
  final String leaveAllocation;
  final bool foodAllowance;
  final bool stayAllowance;
  final bool sundayOff;
  final String employmentType;
  final DateTime joiningDate;
  final DateTime configuredAt;
  final String status;

  Map<String, dynamic> toJson() => {
        'employeeName': employeeName,
        'employeeId': employeeId,
        'role': role,
        'assignedSite': assignedSite,
        'monthlySalary': monthlySalary,
        'leaveAllocation': leaveAllocation,
        'foodAllowance': foodAllowance,
        'stayAllowance': stayAllowance,
        'sundayOff': sundayOff,
        'employmentType': employmentType,
        'joiningDate': joiningDate.toIso8601String(),
        'savedAt': configuredAt.toIso8601String(),
        'status': status,
      };

  factory EmployeeKycConfig.fromJson(Map<String, dynamic> json) {
    return EmployeeKycConfig(
      employeeName: json['employeeName']?.toString() ?? 'Employee',
      employeeId: json['employeeId']?.toString() ?? '',
      role: json['role']?.toString() ?? '—',
      assignedSite: json['assignedSite']?.toString() ?? '—',
      monthlySalary: json['monthlySalary']?.toString() ?? '—',
      leaveAllocation: json['leaveAllocation']?.toString() ?? '—',
      foodAllowance: json['foodAllowance'] == true,
      stayAllowance: json['stayAllowance'] == true,
      sundayOff: json['sundayOff'] == true,
      employmentType: json['employmentType']?.toString() ?? '—',
      joiningDate:
          DateTime.tryParse('${json['joiningDate']}') ?? DateTime.now(),
      configuredAt: DateTime.tryParse('${json['savedAt']}') ??
          DateTime.tryParse('${json['configuredAt']}') ??
          DateTime.now(),
      status: json['status']?.toString().trim().isNotEmpty == true
          ? json['status'].toString()
          : 'Configured',
    );
  }
}

/// Shared local store for HR Employee KYC configurations.
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
