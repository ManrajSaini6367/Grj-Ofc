enum KycStatus {
  notStarted('Not Started'),
  pending('Pending Verification'),
  approved('Approved'),
  rejected('Rejected'),
  ;

  const KycStatus(this.label);
  final String label;
}

enum IdentityProofType {
  aadhaar('Aadhaar Card'),
  pan('PAN Card'),
  passport('Passport'),
  drivingLicense('Driving License'),
  ;

  const IdentityProofType(this.label);
  final String label;
}

class KycRequest {
  const KycRequest({
    required this.id,
    required this.employeeName,
    required this.employeeId,
    required this.mobileNumber,
    required this.email,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    required this.identityProofType,
    required this.identityNumber,
    required this.aadhaarNumber,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.emergencyContactName,
    required this.emergencyContactMobile,
    required this.emergencyContactRelation,
    required this.profilePhotoPath,
    required this.identityFrontPath,
    this.identityBackPath,
    required this.status,
    required this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
    required this.durationDaysHint,
  });

  /// Local identifier (for demo) in the format `kyc_{employeeId}`.
  final String id;

  final String employeeName;
  final String employeeId;

  // Personal
  final String fullName;
  final String mobileNumber;
  final String email;
  final DateTime dateOfBirth;
  final String gender;

  // Address
  final String addressLine;
  final String city;
  final String state;
  final String pincode;

  // Identity
  final IdentityProofType identityProofType;
  final String identityNumber;
  final String aadhaarNumber;
  final String identityFrontPath;
  final String? identityBackPath;

  // Bank
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;

  // Emergency
  final String emergencyContactName;
  final String emergencyContactMobile;
  final String emergencyContactRelation;

  // Photo/documents (local file paths for now)
  final String profilePhotoPath;

  // Workflow
  final KycStatus status;
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  /// Small UI helper for test data; keeps model stable if later expanded.
  final int durationDaysHint;

  KycRequest copyWith({
    KycStatus? status,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
  }) {
    return KycRequest(
      id: id,
      employeeName: employeeName,
      employeeId: employeeId,
      mobileNumber: mobileNumber,
      email: email,
      fullName: fullName,
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
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      durationDaysHint: durationDaysHint,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeName': employeeName,
        'employeeId': employeeId,
        'fullName': fullName,
        'mobileNumber': mobileNumber,
        'email': email,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'gender': gender,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
        'identityProofType': identityProofType.name,
        'identityNumber': identityNumber,
        'aadhaarNumber': aadhaarNumber,
        'identityFrontPath': identityFrontPath,
        'identityBackPath': identityBackPath,
        'accountHolderName': accountHolderName,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'emergencyContactName': emergencyContactName,
        'emergencyContactMobile': emergencyContactMobile,
        'emergencyContactRelation': emergencyContactRelation,
        'profilePhotoPath': profilePhotoPath,
        'status': status.name,
        'submittedAt': submittedAt.toIso8601String(),
        'verifiedAt': verifiedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
        'durationDaysHint': durationDaysHint,
      };

  factory KycRequest.fromJson(Map<String, dynamic> json) {
    return KycRequest(
      id: json['id']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? 'Employee',
      employeeId: json['employeeId']?.toString() ?? 'EMP',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? (json['employeeName']?.toString() ?? ''),
      dateOfBirth: DateTime.tryParse('${json['dateOfBirth']}') ?? DateTime.now(),
      gender: json['gender']?.toString() ?? 'Other',
      addressLine: json['addressLine']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      identityProofType: IdentityProofType.values.firstWhere(
        (e) => e.name == json['identityProofType'],
        orElse: () => IdentityProofType.aadhaar,
      ),
      identityNumber: json['identityNumber']?.toString() ?? '',
      aadhaarNumber: json['aadhaarNumber']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      emergencyContactName: json['emergencyContactName']?.toString() ?? '',
      emergencyContactMobile: json['emergencyContactMobile']?.toString() ?? '',
      emergencyContactRelation: json['emergencyContactRelation']?.toString() ?? '',
      profilePhotoPath: json['profilePhotoPath']?.toString() ?? '',
      identityFrontPath: json['identityFrontPath']?.toString() ?? '',
      identityBackPath: json['identityBackPath']?.toString(),
      status: KycStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => KycStatus.pending,
      ),
      submittedAt: DateTime.tryParse('${json['submittedAt']}') ?? DateTime.now(),
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.tryParse('${json['verifiedAt']}'),
      rejectionReason: json['rejectionReason']?.toString(),
      durationDaysHint: json['durationDaysHint'] is int
          ? json['durationDaysHint'] as int
          : int.tryParse('${json['durationDaysHint']}') ?? 0,
    );
  }
}

