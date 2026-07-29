import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/leavescreens/leave_models.dart';

/// Local leave store until leave APIs are wired.
class LeaveService extends ChangeNotifier {
  LeaveService._();
  static final LeaveService instance = LeaveService._();

  static const _prefsKey = 'user_leave_requests_v1';

  final List<LeaveRequest> _leaves = [];
  bool _loaded = false;

  List<LeaveRequest> get leaves {
    final list = List<LeaveRequest>.from(_leaves);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _load();
  }

  Future<void> _load() async {
    try {
      final raw = Preference.pref.getString(_prefsKey);
      _leaves.clear();
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _leaves.add(LeaveRequest.fromJson(item));
            } else if (item is Map) {
              _leaves.add(
                LeaveRequest.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[LeaveService] load error: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final payload = jsonEncode(_leaves.map((e) => e.toJson()).toList());
    await Preference.pref.setString(_prefsKey, payload);
  }

  static int calculateDurationDays(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (end.isBefore(start)) return 0;
    return end.difference(start).inDays + 1;
  }

  Future<LeaveRequest> applyLeave({
    required DateTime fromDate,
    required DateTime toDate,
    required LeaveType type,
    required String description,
    String? employeeName,
  }) async {
    await ensureLoaded();
    final name = (employeeName ?? Preference.pref.getString('name') ?? 'Employee')
        .trim();
    final request = LeaveRequest(
      id: 'leave_${DateTime.now().millisecondsSinceEpoch}',
      fromDate: DateTime(fromDate.year, fromDate.month, fromDate.day),
      toDate: DateTime(toDate.year, toDate.month, toDate.day),
      type: type,
      description: description.trim(),
      status: LeaveStatus.pending,
      createdAt: DateTime.now(),
      durationDays: calculateDurationDays(fromDate, toDate),
      employeeName: name.isEmpty ? 'Employee' : name,
    );
    _leaves.insert(0, request);
    await _persist();
    notifyListeners();
    return request;
  }

  /// Used when admin API later returns Approved / Rejected.
  Future<void> updateStatus(String id, LeaveStatus status) async {
    await ensureLoaded();
    final index = _leaves.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _leaves[index] = _leaves[index].copyWith(status: status);
    await _persist();
    notifyListeners();
  }
}
