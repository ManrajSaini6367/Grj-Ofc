import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_requests_screen.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_store.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/image_pick_helper.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class EmployeeKycScreen extends StatefulWidget {
  const EmployeeKycScreen({
    super.key,
    this.employeeId,
    this.employeeName,
  });

  final String? employeeId;
  final String? employeeName;

  @override
  State<EmployeeKycScreen> createState() => _EmployeeKycScreenState();
}

class _EmployeeKycScreenState extends State<EmployeeKycScreen> {
  static const _stepTitles = [
    'Employee Details',
    'KYC Documents',
    'KYC Summary',
  ];

  /// Company-provided allowance amounts (not editable by employee).
  static const _companyFoodAmount = '2500';
  static const _companyStayAmount = '4000';
  static const _companyLeaveAllocation = '12';

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _detailsKey = GlobalKey<FormState>();
  final _docsKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _store = EmployeeKycStore.instance;

  static const _employmentTypes = ['Full-Time', 'Part-Time', 'Contract'];

  final _employeeIdCtrl = TextEditingController();
  final _assignedSiteCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _leaveCtrl = TextEditingController();
  final _foodEmployeeCtrl = TextEditingController();
  final _foodCompanyCtrl = TextEditingController();
  final _stayEmployeeCtrl = TextEditingController();
  final _stayCompanyCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();

  int _stepIndex = 0;
  bool _saving = false;
  bool _saved = false;
  bool _foodAllowance = false;
  bool _stayAllowance = false;
  String _employmentType = 'Full-Time';
  DateTime? _joiningDate;

  File? _panCard;
  File? _aadhaarFront;
  File? _aadhaarBack;
  File? _marksheet10;
  File? _marksheet12;
  File? _bankCheque;

  bool get _isLastStep => _stepIndex == _stepTitles.length - 1;
  double get _progress => (_stepIndex + 1) / _stepTitles.length;

  @override
  void initState() {
    super.initState();
    final id = (widget.employeeId ??
            Preference.pref.getString('userId') ??
            Preference.pref.getString('username') ??
            '')
        .trim();
    _employeeIdCtrl.text = id;
    _assignedSiteCtrl.text = _resolveAssignedSite();
    _joiningDate = _parseJoinDate(cachedUser()?.dateOfJoin);
    _foodCompanyCtrl.text = _companyFoodAmount;
    _stayCompanyCtrl.text = _companyStayAmount;
    _leaveCtrl.text = _companyLeaveAllocation;
    _salaryCtrl.addListener(_onAmountChanged);
    _foodEmployeeCtrl.addListener(_onAmountChanged);
    _stayEmployeeCtrl.addListener(_onAmountChanged);
  }

  String _resolveAssignedSite() {
    final named = selectedSiteName()?.trim();
    if (named != null && named.isNotEmpty) return named;
    final user = cachedUser();
    final sites = cachedSites() ?? const [];
    final siteId = selectedSiteId() ?? user?.siteId;
    if (siteId != null && siteId > 0) {
      final fromList = siteNameById(sites, siteId)?.trim();
      if (fromList != null && fromList.isNotEmpty) return fromList;
    }
    return '';
  }

  DateTime? _parseJoinDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim();
    final iso = DateTime.tryParse(t);
    if (iso != null) return iso;
    for (final pattern in ['dd/MM/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy', 'dd MMM yyyy']) {
      try {
        return DateFormat(pattern).parse(t);
      } catch (_) {}
    }
    return null;
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    _employeeIdCtrl.dispose();
    _assignedSiteCtrl.dispose();
    _salaryCtrl.removeListener(_onAmountChanged);
    _foodEmployeeCtrl.removeListener(_onAmountChanged);
    _stayEmployeeCtrl.removeListener(_onAmountChanged);
    _salaryCtrl.dispose();
    _leaveCtrl.dispose();
    _foodEmployeeCtrl.dispose();
    _foodCompanyCtrl.dispose();
    _stayEmployeeCtrl.dispose();
    _stayCompanyCtrl.dispose();
    _accountHolderCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 24;
  }

  InputDecoration _decoration(
    String label, {
    String? hint,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.headingBlack,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.inputHint),
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.borderGray.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.headingBlack,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _validateDetails() {
    if (!(_detailsKey.currentState?.validate() ?? false)) return false;
    if (_employeeIdCtrl.text.trim().isEmpty) {
      _snack('Employee ID is required.');
      return false;
    }
    if (_joiningDate == null) {
      _snack('Please select joining date.');
      return false;
    }
    return true;
  }

  Future<void> _pickJoiningDate() async {
    final now = DateTime.now();
    final initial = _joiningDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(now.year - 40),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _joiningDate = picked;
      _saved = false;
    });
  }

  bool _validateDocuments() {
    if (!(_docsKey.currentState?.validate() ?? false)) return false;
    if (_panCard == null) {
      _snack('Please upload PAN Card photo.');
      return false;
    }
    if (_aadhaarFront == null) {
      _snack('Please upload Aadhaar Card front photo.');
      return false;
    }
    if (_aadhaarBack == null) {
      _snack('Please upload Aadhaar Card back photo.');
      return false;
    }
    if (_marksheet10 == null) {
      _snack('Please upload 10th Marksheet.');
      return false;
    }
    if (_marksheet12 == null) {
      _snack('Please upload 12th Marksheet.');
      return false;
    }
    if (_accountHolderCtrl.text.trim().isEmpty) {
      _snack('Please enter account holder name.');
      return false;
    }
    if (_bankNameCtrl.text.trim().isEmpty) {
      _snack('Please enter bank name.');
      return false;
    }
    if (_accountNumberCtrl.text.trim().isEmpty) {
      _snack('Please enter account number.');
      return false;
    }
    if (_ifscCtrl.text.trim().length != 11) {
      _snack('Please enter a valid 11-character IFSC code.');
      return false;
    }
    if (_bankCheque == null) {
      _snack('Please upload Cancelled Cheque photo.');
      return false;
    }
    return true;
  }

  Future<void> _pickDoc(
    void Function(File file) assign, {
    required String title,
    required bool fromCamera,
  }) async {
    final file = await pickPurchaseImageFile(
      context,
      title: title,
      documentGuide: fromCamera,
      fromCamera: fromCamera,
    );
    if (file == null || !mounted) return;
    setState(() {
      assign(file);
      _saved = false;
    });
  }

  void _goNext() {
    FocusScope.of(context).unfocus();
    if (_stepIndex == 0 && !_validateDetails()) return;
    if (_stepIndex == 1 && !_validateDocuments()) return;
    if (_isLastStep) {
      _submit();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goPrevious() {
    FocusScope.of(context).unfocus();
    if (_stepIndex == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    await _store.save(
      EmployeeKycConfig(
        employeeId: _employeeIdCtrl.text.trim(),
        employeeName: widget.employeeName ??
            Preference.pref.getString('name') ??
            '',
        assignedSite: _assignedSiteCtrl.text.trim(),
        monthlySalary: _salaryCtrl.text.trim(),
        leaveAllocation: _leaveCtrl.text.trim(),
        employmentType: _employmentType,
        joiningDate: _formatJoinDate(_joiningDate),
        foodAllowance: _foodAllowance,
        foodEmployeeAmount:
            _foodAllowance ? _foodEmployeeCtrl.text.trim() : '',
        foodCompanyAmount:
            _foodAllowance ? _foodCompanyCtrl.text.trim() : '',
        stayAllowance: _stayAllowance,
        stayEmployeeAmount:
            _stayAllowance ? _stayEmployeeCtrl.text.trim() : '',
        stayCompanyAmount:
            _stayAllowance ? _stayCompanyCtrl.text.trim() : '',
        accountHolderName: _accountHolderCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim().toUpperCase(),
        emergencyContact: _emergencyCtrl.text.trim(),
        panPath: _panCard?.path ?? '',
        aadhaarFrontPath: _aadhaarFront?.path ?? '',
        aadhaarBackPath: _aadhaarBack?.path ?? '',
        marksheet10Path: _marksheet10?.path ?? '',
        marksheet12Path: _marksheet12?.path ?? '',
        bankChequePath: _bankCheque?.path ?? '',
        configuredAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    _snack('Employee KYC submitted successfully.');
  }

  String get _primaryCta {
    if (_stepIndex == 0) return 'Next →';
    if (_stepIndex == 1) return 'Accept';
    return _saved ? 'View Requests' : 'Done';
  }

  void _onPrimary() {
    if (_isLastStep && _saved) {
      pushInShell(context, const EmployeeKycRequestsScreen());
      return;
    }
    _goNext();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final contentMax = width >= 900 ? 680.0 : double.infinity;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.employeeKyc,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Employee KYC',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            _ProgressHeader(
              hPad: hPad,
              stepIndex: _stepIndex,
              title: _stepTitles[_stepIndex],
              progress: _progress,
              total: _stepTitles.length,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMax),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _stepIndex = i),
                    children: [
                      Form(
                        key: _detailsKey,
                        child: _DetailsStep(
                          hPad: hPad,
                          employeeIdCtrl: _employeeIdCtrl,
                          assignedSiteCtrl: _assignedSiteCtrl,
                          salaryCtrl: _salaryCtrl,
                          leaveCtrl: _leaveCtrl,
                          joiningDateLabel: _formatJoinDate(_joiningDate),
                          employmentType: _employmentType,
                          employmentTypes: _employmentTypes,
                          foodAllowance: _foodAllowance,
                          stayAllowance: _stayAllowance,
                          foodEmployeeCtrl: _foodEmployeeCtrl,
                          foodCompanyCtrl: _foodCompanyCtrl,
                          stayEmployeeCtrl: _stayEmployeeCtrl,
                          stayCompanyCtrl: _stayCompanyCtrl,
                          decoration: _decoration,
                          onPickJoiningDate: _pickJoiningDate,
                          onEmploymentTypeChanged: (v) {
                            setState(() {
                              _employmentType = v;
                              _saved = false;
                            });
                          },
                          onFoodChanged: (v) {
                            setState(() {
                              _foodAllowance = v;
                              _saved = false;
                              if (!v) {
                                _foodEmployeeCtrl.clear();
                              } else {
                                _foodCompanyCtrl.text = _companyFoodAmount;
                              }
                            });
                          },
                          onStayChanged: (v) {
                            setState(() {
                              _stayAllowance = v;
                              _saved = false;
                              if (!v) {
                                _stayEmployeeCtrl.clear();
                              } else {
                                _stayCompanyCtrl.text = _companyStayAmount;
                              }
                            });
                          },
                        ),
                      ),
                      Form(
                        key: _docsKey,
                        child: _DocumentsStep(
                          hPad: hPad,
                          emergencyCtrl: _emergencyCtrl,
                          accountHolderCtrl: _accountHolderCtrl,
                          bankNameCtrl: _bankNameCtrl,
                          accountNumberCtrl: _accountNumberCtrl,
                          ifscCtrl: _ifscCtrl,
                          panCard: _panCard,
                          aadhaarFront: _aadhaarFront,
                          aadhaarBack: _aadhaarBack,
                          marksheet10: _marksheet10,
                          marksheet12: _marksheet12,
                          bankCheque: _bankCheque,
                          decoration: _decoration,
                          onPanCamera: () => _pickDoc(
                            (f) => _panCard = f,
                            title: 'PAN Card',
                            fromCamera: true,
                          ),
                          onPanGallery: () => _pickDoc(
                            (f) => _panCard = f,
                            title: 'PAN Card',
                            fromCamera: false,
                          ),
                          onAadhaarFrontCamera: () => _pickDoc(
                            (f) => _aadhaarFront = f,
                            title: 'Aadhaar Front',
                            fromCamera: true,
                          ),
                          onAadhaarFrontGallery: () => _pickDoc(
                            (f) => _aadhaarFront = f,
                            title: 'Aadhaar Front',
                            fromCamera: false,
                          ),
                          onAadhaarBackCamera: () => _pickDoc(
                            (f) => _aadhaarBack = f,
                            title: 'Aadhaar Back',
                            fromCamera: true,
                          ),
                          onAadhaarBackGallery: () => _pickDoc(
                            (f) => _aadhaarBack = f,
                            title: 'Aadhaar Back',
                            fromCamera: false,
                          ),
                          onPick10Camera: () => _pickDoc(
                            (f) => _marksheet10 = f,
                            title: '10th Marksheet',
                            fromCamera: true,
                          ),
                          onPick10Gallery: () => _pickDoc(
                            (f) => _marksheet10 = f,
                            title: '10th Marksheet',
                            fromCamera: false,
                          ),
                          onPick12Camera: () => _pickDoc(
                            (f) => _marksheet12 = f,
                            title: '12th Marksheet',
                            fromCamera: true,
                          ),
                          onPick12Gallery: () => _pickDoc(
                            (f) => _marksheet12 = f,
                            title: '12th Marksheet',
                            fromCamera: false,
                          ),
                          onChequeCamera: () => _pickDoc(
                            (f) => _bankCheque = f,
                            title: 'Cancelled Cheque',
                            fromCamera: true,
                          ),
                          onChequeGallery: () => _pickDoc(
                            (f) => _bankCheque = f,
                            title: 'Cancelled Cheque',
                            fromCamera: false,
                          ),
                        ),
                      ),
                      _SummaryStep(
                        hPad: hPad,
                        employeeId: _employeeIdCtrl.text.trim(),
                        assignedSite: _assignedSiteCtrl.text.trim(),
                        monthlySalary: _salaryCtrl.text.trim(),
                        leaveAllocation: _leaveCtrl.text.trim(),
                        employmentType: _employmentType,
                        joiningDate: _formatJoinDate(_joiningDate),
                        foodAllowance: _foodAllowance,
                        foodEmployeeAmount: _foodEmployeeCtrl.text.trim(),
                        foodCompanyAmount: _foodCompanyCtrl.text.trim(),
                        stayAllowance: _stayAllowance,
                        stayEmployeeAmount: _stayEmployeeCtrl.text.trim(),
                        stayCompanyAmount: _stayCompanyCtrl.text.trim(),
                        accountHolderName: _accountHolderCtrl.text.trim(),
                        bankName: _bankNameCtrl.text.trim(),
                        accountNumber: _accountNumberCtrl.text.trim(),
                        ifscCode: _ifscCtrl.text.trim().toUpperCase(),
                        emergencyContact: _emergencyCtrl.text.trim(),
                        panCard: _panCard,
                        aadhaarFront: _aadhaarFront,
                        aadhaarBack: _aadhaarBack,
                        marksheet10: _marksheet10,
                        marksheet12: _marksheet12,
                        bankCheque: _bankCheque,
                        saved: _saved,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _BottomBar(
              hPad: hPad,
              bottomInset: bottomInset,
              stepIndex: _stepIndex,
              primaryLabel: _primaryCta,
              saving: _saving,
              onPrevious: _stepIndex == 0 ? null : _goPrevious,
              onPrimary: _onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.hPad,
    required this.stepIndex,
    required this.title,
    required this.progress,
    required this.total,
  });

  final double hPad;
  final int stepIndex;
  final String title;
  final double progress;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${stepIndex + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Step ${stepIndex + 1} of $total — $title',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F3F6),
              color: AppColors.primaryRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.hPad,
    required this.employeeIdCtrl,
    required this.assignedSiteCtrl,
    required this.salaryCtrl,
    required this.leaveCtrl,
    required this.joiningDateLabel,
    required this.employmentType,
    required this.employmentTypes,
    required this.foodAllowance,
    required this.stayAllowance,
    required this.foodEmployeeCtrl,
    required this.foodCompanyCtrl,
    required this.stayEmployeeCtrl,
    required this.stayCompanyCtrl,
    required this.decoration,
    required this.onPickJoiningDate,
    required this.onEmploymentTypeChanged,
    required this.onFoodChanged,
    required this.onStayChanged,
  });

  final double hPad;
  final TextEditingController employeeIdCtrl;
  final TextEditingController assignedSiteCtrl;
  final TextEditingController salaryCtrl;
  final TextEditingController leaveCtrl;
  final String joiningDateLabel;
  final String employmentType;
  final List<String> employmentTypes;
  final bool foodAllowance;
  final bool stayAllowance;
  final TextEditingController foodEmployeeCtrl;
  final TextEditingController foodCompanyCtrl;
  final TextEditingController stayEmployeeCtrl;
  final TextEditingController stayCompanyCtrl;
  final InputDecoration Function(String, {String? hint, String? prefixText})
      decoration;
  final VoidCallback onPickJoiningDate;
  final ValueChanged<String> onEmploymentTypeChanged;
  final ValueChanged<bool> onFoodChanged;
  final ValueChanged<bool> onStayChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 20),
      children: [
        _SectionCard(
          icon: Icons.badge_outlined,
          title: 'Employee Details',
          subtitle: 'Employee ID, salary, site and employment details.',
          child: Column(
            children: [
              TextFormField(
                controller: employeeIdCtrl,
                readOnly: true,
                decoration: decoration('Employee ID'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Employee ID is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: assignedSiteCtrl,
                readOnly: true,
                decoration: decoration(
                  'Assigned Site',
                  hint: 'Site not assigned',
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: onPickJoiningDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: decoration('Joining Date').copyWith(
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  child: Text(
                    joiningDateLabel.isEmpty ? 'Select joining date' : joiningDateLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: joiningDateLabel.isEmpty
                          ? AppColors.inputHint
                          : AppColors.headingBlack,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _AmountField(
                controller: salaryCtrl,
                label: 'Monthly Salary',
                hint: '0.00',
                readOnly: false,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Enter monthly salary';
                  final n = double.tryParse(t);
                  if (n == null || n <= 0) return 'Enter a valid salary';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              IgnorePointer(
                child: TextFormField(
                  controller: leaveCtrl,
                  readOnly: true,
                  canRequestFocus: false,
                  enableInteractiveSelection: false,
                  decoration: decoration(
                    'Leave Allocation',
                    hint: 'Company provided leaves',
                  ).copyWith(
                    filled: true,
                    fillColor: const Color(0xFFEEF2F6),
                    suffixText: 'leaves / year',
                    suffixStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Employment Type',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _EmploymentTypeToggle(
                value: employmentType,
                options: employmentTypes,
                onChanged: onEmploymentTypeChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AllowanceCard(
          icon: Icons.restaurant_outlined,
          title: 'Food Allowance',
          subtitle: 'Select Yes if food allowance is applicable.',
          enabled: foodAllowance,
          onChanged: onFoodChanged,
          employeeCtrl: foodEmployeeCtrl,
          companyCtrl: foodCompanyCtrl,
          employeeLabel: 'Employee Amount',
          companyLabel: 'Company Provides',
          decoration: decoration,
        ),
        const SizedBox(height: 14),
        _AllowanceCard(
          icon: Icons.home_work_outlined,
          title: 'Stay Allowance',
          subtitle: 'Select Yes if stay allowance is applicable.',
          enabled: stayAllowance,
          onChanged: onStayChanged,
          employeeCtrl: stayEmployeeCtrl,
          companyCtrl: stayCompanyCtrl,
          employeeLabel: 'Employee Amount',
          companyLabel: 'Company Provides',
          decoration: decoration,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryRed, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.headingBlack,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AllowanceCard extends StatelessWidget {
  const _AllowanceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
    required this.employeeCtrl,
    required this.companyCtrl,
    required this.employeeLabel,
    required this.companyLabel,
    required this.decoration,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final TextEditingController employeeCtrl;
  final TextEditingController companyCtrl;
  final String employeeLabel;
  final String companyLabel;
  final InputDecoration Function(String, {String? hint, String? prefixText})
      decoration;

  String? _amountValidator(bool required, String? value, String emptyMsg) {
    if (!required) return null;
    final t = (value ?? '').trim();
    if (t.isEmpty) return emptyMsg;
    final n = double.tryParse(t);
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          _YesNoToggle(value: enabled, onChanged: onChanged),
          if (enabled) ...[
            const SizedBox(height: 16),
            _AmountField(
              controller: employeeCtrl,
              label: employeeLabel,
              hint: '0.00',
              readOnly: false,
              validator: (v) => _amountValidator(
                enabled,
                v,
                'Enter employee amount',
              ),
            ),
            const SizedBox(height: 12),
            IgnorePointer(
              child: _AmountField(
                controller: companyCtrl,
                label: companyLabel,
                hint: '0.00',
                readOnly: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.readOnly,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool readOnly;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.trim().isNotEmpty;
    final rupeeColor = hasValue
        ? const Color(0xFF059669)
        : AppColors.textSecondary;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      canRequestFocus: !readOnly,
      enableInteractiveSelection: !readOnly,
      mouseCursor: readOnly ? SystemMouseCursors.basic : null,
      keyboardType: readOnly
          ? TextInputType.none
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: readOnly
          ? const []
          : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: AppColors.headingBlack,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Text(
            '₹',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: rupeeColor,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.inputHint),
        filled: true,
        fillColor: readOnly ? const Color(0xFFEEF2F6) : const Color(0xFFF8F9FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: readOnly
                ? AppColors.borderGray.withValues(alpha: 0.5)
                : AppColors.primaryRed,
            width: readOnly ? 1 : 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
      ),
    );
  }
}

class _EmploymentTypeToggle extends StatelessWidget {
  const _EmploymentTypeToggle({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 380;

    Widget chip(String option) {
      final selected = option == value;
      return Material(
        color: selected ? AppColors.primaryRed : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: () => onChanged(option),
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              option,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.headingBlack,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: narrow
          ? Column(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  SizedBox(width: double.infinity, child: chip(options[i])),
                ],
              ],
            )
          : Row(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(child: chip(options[i])),
                ],
              ],
            ),
    );
  }
}

class _YesNoToggle extends StatelessWidget {
  const _YesNoToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleItem(
              label: 'Yes',
              selected: value,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleItem(
              label: 'No',
              selected: !value,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryRed : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.white : AppColors.headingBlack,
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentsStep extends StatelessWidget {
  const _DocumentsStep({
    required this.hPad,
    required this.emergencyCtrl,
    required this.accountHolderCtrl,
    required this.bankNameCtrl,
    required this.accountNumberCtrl,
    required this.ifscCtrl,
    required this.panCard,
    required this.aadhaarFront,
    required this.aadhaarBack,
    required this.marksheet10,
    required this.marksheet12,
    required this.bankCheque,
    required this.decoration,
    required this.onPanCamera,
    required this.onPanGallery,
    required this.onAadhaarFrontCamera,
    required this.onAadhaarFrontGallery,
    required this.onAadhaarBackCamera,
    required this.onAadhaarBackGallery,
    required this.onPick10Camera,
    required this.onPick10Gallery,
    required this.onPick12Camera,
    required this.onPick12Gallery,
    required this.onChequeCamera,
    required this.onChequeGallery,
  });

  final double hPad;
  final TextEditingController emergencyCtrl;
  final TextEditingController accountHolderCtrl;
  final TextEditingController bankNameCtrl;
  final TextEditingController accountNumberCtrl;
  final TextEditingController ifscCtrl;
  final File? panCard;
  final File? aadhaarFront;
  final File? aadhaarBack;
  final File? marksheet10;
  final File? marksheet12;
  final File? bankCheque;
  final InputDecoration Function(String, {String? hint, String? prefixText})
      decoration;
  final VoidCallback onPanCamera;
  final VoidCallback onPanGallery;
  final VoidCallback onAadhaarFrontCamera;
  final VoidCallback onAadhaarFrontGallery;
  final VoidCallback onAadhaarBackCamera;
  final VoidCallback onAadhaarBackGallery;
  final VoidCallback onPick10Camera;
  final VoidCallback onPick10Gallery;
  final VoidCallback onPick12Camera;
  final VoidCallback onPick12Gallery;
  final VoidCallback onChequeCamera;
  final VoidCallback onChequeGallery;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 20),
      children: [
        _SectionCard(
          icon: Icons.credit_card_outlined,
          title: 'PAN Card',
          subtitle: 'Upload a clear photo of your PAN Card.',
          child: _DocUploadField(
            title: 'PAN Card',
            subtitle: 'Capture or select PAN Card photo.',
            file: panCard,
            onCamera: onPanCamera,
            onGallery: onPanGallery,
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          icon: Icons.badge_outlined,
          title: 'Aadhaar Card',
          subtitle: 'Upload Front and Back separately.',
          child: Column(
            children: [
              _DocUploadField(
                title: 'Aadhaar Front',
                subtitle: 'Upload Aadhaar Card front side.',
                file: aadhaarFront,
                onCamera: onAadhaarFrontCamera,
                onGallery: onAadhaarFrontGallery,
              ),
              const SizedBox(height: 12),
              _DocUploadField(
                title: 'Aadhaar Back',
                subtitle: 'Upload Aadhaar Card back side.',
                file: aadhaarBack,
                onCamera: onAadhaarBackCamera,
                onGallery: onAadhaarBackGallery,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          icon: Icons.menu_book_outlined,
          title: 'Education Documents',
          subtitle: 'Upload 10th and 12th marksheets.',
          child: Column(
            children: [
              _DocUploadField(
                title: '10th Marksheet',
                subtitle: 'Capture or select 10th marksheet.',
                file: marksheet10,
                onCamera: onPick10Camera,
                onGallery: onPick10Gallery,
              ),
              const SizedBox(height: 12),
              _DocUploadField(
                title: '12th Marksheet',
                subtitle: 'Capture or select 12th marksheet.',
                file: marksheet12,
                onCamera: onPick12Camera,
                onGallery: onPick12Gallery,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          icon: Icons.account_balance_outlined,
          title: 'Bank Details',
          subtitle: 'Enter account details, then upload cancelled cheque.',
          child: Column(
            children: [
              TextFormField(
                controller: accountHolderCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: decoration(
                  'Account Holder Name',
                  hint: 'Name as per bank account',
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Enter account holder name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bankNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: decoration(
                  'Bank Name',
                  hint: 'e.g. State Bank of India',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter bank name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: accountNumberCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(18),
                ],
                decoration: decoration(
                  'Account Number',
                  hint: 'Enter account number',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Enter account number';
                  if (t.length < 8) return 'Enter a valid account number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ifscCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(11),
                  _UpperCaseTextFormatter(),
                ],
                decoration: decoration(
                  'IFSC Code',
                  hint: 'e.g. SBIN0001234',
                ),
                validator: (v) {
                  final t = (v ?? '').trim().toUpperCase();
                  if (t.isEmpty) return 'Enter IFSC code';
                  if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(t)) {
                    return 'Enter a valid IFSC code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _DocUploadField(
                title: 'Cancelled Cheque',
                subtitle: 'Upload cancelled cheque photo after bank details.',
                file: bankCheque,
                onCamera: onChequeCamera,
                onGallery: onChequeGallery,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          icon: Icons.phone_in_talk_outlined,
          title: 'Emergency Contact',
          subtitle: 'Enter a 10-digit mobile number.',
          child: TextFormField(
            controller: emergencyCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: decoration(
              'Emergency Contact Number',
              hint: '10-digit mobile number',
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'Enter emergency contact number';
              if (t.length != 10) return 'Enter a valid 10-digit number';
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _DocUploadField extends StatelessWidget {
  const _DocUploadField({
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onCamera,
    required this.onGallery,
  });

  final String title;
  final String subtitle;
  final File? file;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null && file!.existsSync();
    final width = MediaQuery.sizeOf(context).width;
    final previewH = (width * 0.48).clamp(150.0, 220.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFile
              ? AppColors.primaryRed.withValues(alpha: 0.35)
              : AppColors.borderGray.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (hasFile) ...[
            GestureDetector(
              onTap: () => _openPreview(context, file!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Image.file(
                      file!,
                      height: previewH,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Tap to preview',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: onCamera,
                    icon: Icon(
                      hasFile
                          ? Icons.cameraswitch_outlined
                          : Icons.photo_camera_outlined,
                      size: 18,
                      color: AppColors.primaryRed,
                    ),
                    label: Text(
                      hasFile ? 'Retake' : 'Camera',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryRed,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.primaryRed.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: 18,
                      color: AppColors.primaryRed,
                    ),
                    label: Text(
                      hasFile ? 'Change' : 'Gallery',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryRed,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.primaryRed.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context, File image) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ImagePreviewScreen(title: title, file: image),
      ),
    );
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  const _ImagePreviewScreen({required this.title, required this.file});

  final String title;
  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.hPad,
    required this.employeeId,
    required this.assignedSite,
    required this.monthlySalary,
    required this.leaveAllocation,
    required this.employmentType,
    required this.joiningDate,
    required this.foodAllowance,
    required this.foodEmployeeAmount,
    required this.foodCompanyAmount,
    required this.stayAllowance,
    required this.stayEmployeeAmount,
    required this.stayCompanyAmount,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.emergencyContact,
    required this.panCard,
    required this.aadhaarFront,
    required this.aadhaarBack,
    required this.marksheet10,
    required this.marksheet12,
    required this.bankCheque,
    required this.saved,
  });

  final double hPad;
  final String employeeId;
  final String assignedSite;
  final String monthlySalary;
  final String leaveAllocation;
  final String employmentType;
  final String joiningDate;
  final bool foodAllowance;
  final String foodEmployeeAmount;
  final String foodCompanyAmount;
  final bool stayAllowance;
  final String stayEmployeeAmount;
  final String stayCompanyAmount;
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String emergencyContact;
  final File? panCard;
  final File? aadhaarFront;
  final File? aadhaarBack;
  final File? marksheet10;
  final File? marksheet12;
  final File? bankCheque;
  final bool saved;

  String _rupee(String value) => value.trim().isEmpty ? '—' : '₹ $value';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 20),
      children: [
        if (saved)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Employee KYC submitted successfully.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF059669),
              ),
            ),
          ),
        _SummarySection(
          title: 'Employee Information',
          children: [
            _SummaryRow(label: 'Employee ID', value: employeeId),
            _SummaryRow(label: 'Assigned Site', value: assignedSite),
            _SummaryRow(label: 'Joining Date', value: joiningDate),
            _SummaryRow(label: 'Monthly Salary', value: _rupee(monthlySalary)),
            _SummaryRow(
              label: 'Leave Allocation',
              value: leaveAllocation.isEmpty
                  ? '—'
                  : '$leaveAllocation leaves / year',
            ),
            _SummaryRow(label: 'Employment Type', value: employmentType),
          ],
        ),
        const SizedBox(height: 12),
        _SummarySection(
          title: 'Food Allowance',
          children: [
            _SummaryRow(
              label: 'Food Allowance',
              value: foodAllowance ? 'Yes' : 'No',
            ),
            if (foodAllowance) ...[
              _SummaryRow(
                label: 'Employee Amount',
                value: _rupee(foodEmployeeAmount),
              ),
              _SummaryRow(
                label: 'Company Provides',
                value: _rupee(foodCompanyAmount),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _SummarySection(
          title: 'Stay Allowance',
          children: [
            _SummaryRow(
              label: 'Stay Allowance',
              value: stayAllowance ? 'Yes' : 'No',
            ),
            if (stayAllowance) ...[
              _SummaryRow(
                label: 'Employee Amount',
                value: _rupee(stayEmployeeAmount),
              ),
              _SummaryRow(
                label: 'Company Provides',
                value: _rupee(stayCompanyAmount),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _SummarySection(
          title: 'Bank Details',
          children: [
            _SummaryRow(label: 'Account Holder', value: accountHolderName),
            _SummaryRow(label: 'Bank Name', value: bankName),
            _SummaryRow(label: 'Account Number', value: accountNumber),
            _SummaryRow(label: 'IFSC Code', value: ifscCode),
          ],
        ),
        const SizedBox(height: 12),
        _SummarySection(
          title: 'Emergency Contact',
          children: [
            _SummaryRow(label: 'Contact Number', value: emergencyContact),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderGray.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uploaded Documents',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(height: 12),
              _SummaryImage(label: 'PAN Card', file: panCard),
              _SummaryImage(label: 'Aadhaar Front', file: aadhaarFront),
              _SummaryImage(label: 'Aadhaar Back', file: aadhaarBack),
              _SummaryImage(label: '10th Marksheet', file: marksheet10),
              _SummaryImage(label: '12th Marksheet', file: marksheet12),
              _SummaryImage(label: 'Cancelled Cheque', file: bankCheque),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.headingBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryImage extends StatelessWidget {
  const _SummaryImage({required this.label, required this.file});

  final String label;
  final File? file;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null && file!.existsSync();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasFile
                ? Image.file(
                    file!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 90,
                    width: double.infinity,
                    alignment: Alignment.center,
                    color: const Color(0xFFF8F9FB),
                    child: Text(
                      'No image',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.hPad,
    required this.bottomInset,
    required this.stepIndex,
    required this.primaryLabel,
    required this.saving,
    required this.onPrevious,
    required this.onPrimary,
  });

  final double hPad;
  final double bottomInset;
  final int stepIndex;
  final String primaryLabel;
  final bool saving;
  final VoidCallback? onPrevious;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 12 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onPrevious != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onPrevious,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.headingBlack,
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(
                    color: AppColors.borderGray.withValues(alpha: 0.7),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: onPrevious == null ? 1 : 1,
            child: ElevatedButton(
              onPressed: saving ? null : onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.white,
                disabledBackgroundColor:
                    AppColors.primaryRed.withValues(alpha: 0.45),
                minimumSize: const Size.fromHeight(50),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      primaryLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
