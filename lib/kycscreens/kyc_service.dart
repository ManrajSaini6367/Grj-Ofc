import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grjoffice_apps/core/preference.dart';

import 'kyc_models.dart';

/// Local KYC store (API wiring later).
class KycService extends ChangeNotifier {
  KycService._();
  static final KycService instance = KycService._();

  static const _prefsKey = 'kyc_requests_v1';

  final List<KycRequest> _requests = [];
  bool _loaded = false;

  List<KycRequest> get requests {
    final list = List<KycRequest>.from(_requests);
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  String get _myEmployeeId {
    final raw = Preference.pref.getString('userId');
    if (raw == null) return 'EMP';
    final v = raw.toString().trim();
    return v.isNotEmpty ? v : 'EMP';
  }

  String get _myName {
    final raw = Preference.pref.getString('name');
    if (raw == null) return 'Employee';
    final v = raw.toString().trim();
    return v.isNotEmpty ? v : 'Employee';
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _load();
  }

  Future<void> _load() async {
    try {
      final raw = Preference.pref.getString(_prefsKey);
      _requests.clear();
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _requests.add(KycRequest.fromJson(item));
            } else if (item is Map) {
              _requests.add(
                KycRequest.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[KycService] load error: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final payload = jsonEncode(_requests.map((e) => e.toJson()).toList());
    await Preference.pref.setString(_prefsKey, payload);
  }

  KycRequest? get myRequest {
    final myId = _myEmployeeId;
    for (final r in _requests) {
      if (r.employeeId == myId) return r;
    }
    return null;
  }

  Future<void> submitOrUpdateMyKyc({
    required String fullName,
    required String mobileNumber,
    required String email,
    required DateTime dateOfBirth,
    required String gender,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    required IdentityProofType identityProofType,
    required String identityNumber,
    required String aadhaarNumber,
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    required String emergencyContactName,
    required String emergencyContactMobile,
    required String emergencyContactRelation,
    required String profilePhotoPath,
    required String identityFrontPath,
    String? identityBackPath,
  }) async {
    await ensureLoaded();

    final now = DateTime.now();
    final id = 'kyc_$_myEmployeeId';

    final request = KycRequest(
      id: id,
      employeeName: _myName,
      employeeId: _myEmployeeId,
      fullName: fullName,
      mobileNumber: mobileNumber,
      email: email,
      dateOfBirth: dateOfBirth,
      gender: gender,
      addressLine: addressLine,
      city: city,
      state: state,
      pincode: pincode,
      identityProofType: identityProofType,
      identityNumber: identityNumber,
      aadhaarNumber: aadhaarNumber,
      accountHolderName: accountHolderName,
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      emergencyContactName: emergencyContactName,
      emergencyContactMobile: emergencyContactMobile,
      emergencyContactRelation: emergencyContactRelation,
      profilePhotoPath: profilePhotoPath,
      identityFrontPath: identityFrontPath,
      identityBackPath: identityBackPath,
      status: KycStatus.pending,
      submittedAt: now,
      verifiedAt: null,
      rejectionReason: null,
      durationDaysHint: 0,
    );

    final index = _requests.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _requests[index] = request;
    } else {
      _requests.insert(0, request);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> approve(String id) async {
    await ensureLoaded();
    final index = _requests.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _requests[index] = _requests[index].copyWith(
      status: KycStatus.approved,
      verifiedAt: DateTime.now(),
      rejectionReason: null,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> reject(String id, String reason) async {
    await ensureLoaded();
    final index = _requests.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _requests[index] = _requests[index].copyWith(
      status: KycStatus.rejected,
      verifiedAt: null,
      rejectionReason: reason.trim(),
    );
    await _persist();
    notifyListeners();
  }
}

