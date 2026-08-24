class Mykycmodaldata {
  Mykycmodaldata({
    this.success,
    this.message,
    this.data,
  });

  bool? success;
  String? message;
  MyKycModalData? data;

  factory Mykycmodaldata.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return Mykycmodaldata(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: rawData is Map
          ? MyKycModalData.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class MyKycModalData {
  MyKycModalData({
    this.id,
    this.employeeId,
    this.employeeName,
    this.siteId,
    this.assignedSite,
    this.monthlySalary,
    this.leaveAllocation,
    this.employmentType,
    this.joiningDate,
    this.foodAllowance = false,
    this.foodEmployeeAmount,
    this.foodCompanyAmount,
    this.stayAllowance = false,
    this.stayEmployeeAmount,
    this.stayCompanyAmount,
    this.emergencyContact,
    this.accountHolderName,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.panPath,
    this.aadhaarFrontPath,
    this.aadhaarBackPath,
    this.marksheet10Path,
    this.marksheet12Path,
    this.bankChequePath,
    this.kycStatus,
    this.status,
    this.kycSubmittedAt,
    this.savedAt,
    this.kycVerifiedAt,
    this.kycRejectionReason,
    this.email,
    this.mobile,
  });

  int? id;
  String? employeeId;
  String? employeeName;
  int? siteId;
  String? assignedSite;
  String? monthlySalary;
  String? leaveAllocation;
  String? employmentType;
  String? joiningDate;
  bool foodAllowance;
  String? foodEmployeeAmount;
  String? foodCompanyAmount;
  bool stayAllowance;
  String? stayEmployeeAmount;
  String? stayCompanyAmount;
  String? emergencyContact;
  String? accountHolderName;
  String? bankName;
  String? accountNumber;
  String? ifscCode;
  String? panPath;
  String? aadhaarFrontPath;
  String? aadhaarBackPath;
  String? marksheet10Path;
  String? marksheet12Path;
  String? bankChequePath;
  String? kycStatus;
  String? status;
  DateTime? kycSubmittedAt;
  DateTime? savedAt;
  dynamic kycVerifiedAt;
  dynamic kycRejectionReason;
  String? email;
  String? mobile;

  factory MyKycModalData.fromJson(Map<String, dynamic> json) {
    return MyKycModalData(
      id: _parseInt(json['id']),
      employeeId: _parseString(
        json['employee_id'] ??
            json['employeeId'] ??
            json['dataEmployeeId'] ??
            _nested(json['employee'] ?? json['user'], 'id'),
      ),
      employeeName: _parseString(
        json['employee_name'] ??
            json['employeeName'] ??
            json['dataEmployeeName'] ??
            _nested(json['employee'] ?? json['user'], 'name'),
      ),
      siteId: _parseInt(json['site_id'] ?? json['siteId'] ?? _nested(json['site'], 'id')),
      assignedSite: _parseString(
        json['assigned_site'] ??
            json['assignedSite'] ??
            _nested(json['site'], 'name'),
      ),
      monthlySalary: _parseString(
        json['monthly_salary'] ??
            json['monthlySalary'] ??
            json['dataMonthlySalary'],
      ),
      leaveAllocation: _parseString(
        json['leave_allocation'] ??
            json['leaveAllocation'] ??
            json['dataLeaveAllocation'],
      ),
      employmentType: _parseString(
        json['employment_type'] ??
            json['employmentType'] ??
            json['dataEmploymentType'],
      ),
      joiningDate: _parseString(
        json['joining_date'] ?? json['joiningDate'] ?? json['dataJoiningDate'],
      ),
      foodAllowance: _parseBool(
        json['food_allowance'] ??
            json['foodAllowance'] ??
            json['dataFoodAllowance'],
      ),
      foodEmployeeAmount: _parseString(
        json['food_employee_amount'] ??
            json['foodEmployeeAmount'] ??
            json['dataFoodEmployeeAmount'],
      ),
      foodCompanyAmount: _parseString(
        json['food_company_amount'] ??
            json['foodCompanyAmount'] ??
            json['dataFoodCompanyAmount'],
      ),
      stayAllowance: _parseBool(
        json['stay_allowance'] ??
            json['stayAllowance'] ??
            json['dataStayAllowance'],
      ),
      stayEmployeeAmount: _parseString(
        json['stay_employee_amount'] ??
            json['stayEmployeeAmount'] ??
            json['dataStayEmployeeAmount'],
      ),
      stayCompanyAmount: _parseString(
        json['stay_company_amount'] ??
            json['stayCompanyAmount'] ??
            json['dataStayCompanyAmount'],
      ),
      emergencyContact: _parseString(
        json['emergency_contact'] ??
            json['emergencyContact'] ??
            json['dataEmergencyContact'],
      ),
      accountHolderName: _parseString(
        json['account_holder_name'] ??
            json['accountHolderName'] ??
            json['dataAccountHolderName'],
      ),
      bankName: _parseString(
        json['bank_name'] ?? json['bankName'] ?? json['dataBankName'],
      ),
      accountNumber: _parseString(
        json['account_number'] ??
            json['accountNumber'] ??
            json['dataAccountNumber'],
      ),
      ifscCode: _parseString(
        json['ifsc_code'] ?? json['ifscCode'] ?? json['dataIfscCode'],
      ),
      panPath: _parseString(
        json['pan_path'] ?? json['panPath'] ?? json['dataPanPath'] ?? json['pan'],
      ),
      aadhaarFrontPath: _parseString(
        json['aadhaar_front_path'] ??
            json['aadhaarFrontPath'] ??
            json['dataAadhaarFrontPath'] ??
            json['aadhaar_front'],
      ),
      aadhaarBackPath: _parseString(
        json['aadhaar_back_path'] ??
            json['aadhaarBackPath'] ??
            json['dataAadhaarBackPath'] ??
            json['aadhaar_back'],
      ),
      marksheet10Path: _parseString(
        json['marksheet_10_path'] ??
            json['marksheet10Path'] ??
            json['dataMarksheet10Path'] ??
            json['marksheet_10'],
      ),
      marksheet12Path: _parseString(
        json['marksheet_12_path'] ??
            json['marksheet12Path'] ??
            json['dataMarksheet12Path'] ??
            json['marksheet_12'],
      ),
      bankChequePath: _parseString(
        json['bank_cheque_path'] ??
            json['bankChequePath'] ??
            json['dataBankChequePath'] ??
            json['bank_cheque'],
      ),
      kycStatus: _parseString(json['kyc_status'] ?? json['kycStatus']),
      status: _parseString(json['status']),
      kycSubmittedAt: _parseDateTime(
        json['kyc_submitted_at'] ?? json['kycSubmittedAt'],
      ),
      savedAt: _parseDateTime(json['saved_at'] ?? json['savedAt']),
      kycVerifiedAt: json['kyc_verified_at'] ?? json['kycVerifiedAt'],
      kycRejectionReason:
          json['kyc_rejection_reason'] ?? json['kycRejectionReason'],
      email: _parseString(
        json['email'] ??
            _nested(json['employee'] ?? json['user'], 'email'),
      ),
      mobile: _parseString(
        json['mobile'] ??
            json['phone'] ??
            json['phone_number'] ??
            _nested(json['employee'] ?? json['user'], 'mobile'),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'site_id': siteId,
        'assigned_site': assignedSite,
        'monthly_salary': monthlySalary,
        'leave_allocation': leaveAllocation,
        'employment_type': employmentType,
        'joining_date': joiningDate,
        'food_allowance': foodAllowance,
        'food_employee_amount': foodEmployeeAmount,
        'food_company_amount': foodCompanyAmount,
        'stay_allowance': stayAllowance,
        'stay_employee_amount': stayEmployeeAmount,
        'stay_company_amount': stayCompanyAmount,
        'emergency_contact': emergencyContact,
        'account_holder_name': accountHolderName,
        'bank_name': bankName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        'pan_path': panPath,
        'aadhaar_front_path': aadhaarFrontPath,
        'aadhaar_back_path': aadhaarBackPath,
        'marksheet_10_path': marksheet10Path,
        'marksheet_12_path': marksheet12Path,
        'bank_cheque_path': bankChequePath,
        'kyc_status': kycStatus,
        'status': status,
        'kyc_submitted_at': kycSubmittedAt?.toIso8601String(),
        'saved_at': savedAt?.toIso8601String(),
        'kyc_verified_at': kycVerifiedAt,
        'kyc_rejection_reason': kycRejectionReason,
        'email': email,
        'mobile': mobile,
      };
}

dynamic _nested(dynamic source, String key) {
  if (source is Map) return source[key];
  return null;
}

String? _parseString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _parseBool(dynamic value) {
  if (value == true || value == 1) return true;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == '1' ||
      normalized == 'true' ||
      normalized == 'yes';
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
