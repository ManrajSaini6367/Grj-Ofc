import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/kycscreens/kyc_models.dart';
import 'package:grjoffice_apps/kycscreens/kyc_service.dart';
import 'package:grjoffice_apps/services/image_pick_helper.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';
import 'package:intl/intl.dart';

/// Multi-step KYC wizard — one screen per step with top progress.
class KycWizardScreen extends StatefulWidget {
  const KycWizardScreen({
    super.key,
    this.initialRequest,
    required this.readOnly,
  });

  final KycRequest? initialRequest;
  final bool readOnly;

  @override
  State<KycWizardScreen> createState() => _KycWizardScreenState();
}

class _KycWizardScreenState extends State<KycWizardScreen> {
  static const _stepTitles = [
    'Personal Information',
    'Address Details',
    'Identity Verification',
    'Bank Details',
    'Profile Photo',
    'Review & Submit',
  ];

  final _service = KycService.instance;
  final _pageController = PageController();

  // Per-step form keys so only the active step validates.
  final _personalKey = GlobalKey<FormState>();
  final _addressKey = GlobalKey<FormState>();
  final _identityKey = GlobalKey<FormState>();
  final _bankKey = GlobalKey<FormState>();

  int _stepIndex = 0;
  bool _submitting = false;

  // Personal
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _emailCtrl;
  late final String _employeeId;
  late final String _employeeName;
  DateTime? _dob;
  String _gender = 'Male';

  // Address
  late final TextEditingController _addressLineCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;

  // Identity
  IdentityProofType _identityType = IdentityProofType.aadhaar;
  late final TextEditingController _identityNumberCtrl;
  File? _identityFront;
  File? _identityBack;

  // Bank
  late final TextEditingController _accountHolderCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _confirmAccountNumberCtrl;
  late final TextEditingController _ifscCtrl;

  // Profile
  File? _profilePhoto;

  // Kept for model compatibility (not shown as a wizard step).
  late final TextEditingController _emgNameCtrl;
  late final TextEditingController _emgMobileCtrl;
  late final TextEditingController _emgRelationCtrl;

  int get _totalSteps => _stepTitles.length;
  double get _progress => (_stepIndex + 1) / _totalSteps;
  bool get _isLastStep => _stepIndex == _totalSteps - 1;

  @override
  void initState() {
    super.initState();
    final req = widget.initialRequest;

    _employeeId = (req?.employeeId.isNotEmpty == true)
        ? req!.employeeId
        : (Preference.pref.getString('userId') ?? 'EMP');
    _employeeName = (req?.employeeName.isNotEmpty == true)
        ? req!.employeeName
        : (Preference.pref.getString('name') ?? 'Employee');

    _fullNameCtrl = TextEditingController(
      text: req?.fullName.isNotEmpty == true ? req!.fullName : _employeeName,
    );
    _mobileCtrl = TextEditingController(
      text: req?.mobileNumber.isNotEmpty == true
          ? req!.mobileNumber
          : (Preference.pref.getString('phone') ?? ''),
    );
    _emailCtrl = TextEditingController(
      text: req?.email.isNotEmpty == true
          ? req!.email
          : (Preference.pref.getString('email') ?? ''),
    );
    _dob = req?.dateOfBirth;
    _gender = req?.gender ?? 'Male';

    _addressLineCtrl = TextEditingController(text: req?.addressLine ?? '');
    _cityCtrl = TextEditingController(text: req?.city ?? '');
    _stateCtrl = TextEditingController(text: req?.state ?? '');
    _pincodeCtrl = TextEditingController(text: req?.pincode ?? '');

    _identityType = req?.identityProofType ?? IdentityProofType.aadhaar;
    _identityNumberCtrl =
        TextEditingController(text: req?.identityNumber ?? '');
    _identityFront = req?.identityFrontPath.isNotEmpty == true
        ? File(req!.identityFrontPath)
        : null;
    _identityBack = req?.identityBackPath?.isNotEmpty == true
        ? File(req!.identityBackPath!)
        : null;

    _accountHolderCtrl =
        TextEditingController(text: req?.accountHolderName ?? '');
    _bankNameCtrl = TextEditingController(text: req?.bankName ?? '');
    _accountNumberCtrl =
        TextEditingController(text: req?.accountNumber ?? '');
    _confirmAccountNumberCtrl =
        TextEditingController(text: req?.accountNumber ?? '');
    _ifscCtrl = TextEditingController(text: req?.ifscCode ?? '');

    _emgNameCtrl =
        TextEditingController(text: req?.emergencyContactName ?? '');
    _emgMobileCtrl =
        TextEditingController(text: req?.emergencyContactMobile ?? '');
    _emgRelationCtrl =
        TextEditingController(text: req?.emergencyContactRelation ?? '');

    _profilePhoto = req?.profilePhotoPath.isNotEmpty == true
        ? File(req!.profilePhotoPath)
        : null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressLineCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _identityNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _confirmAccountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _emgNameCtrl.dispose();
    _emgMobileCtrl.dispose();
    _emgRelationCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, {bool isRequired = false}) {
    final labelStyle = GoogleFonts.poppins(
      fontSize: 13.5,
      color: AppColors.textSecondary,
    );
    return InputDecoration(
      label: inputDecorationLabel(
        label,
        style: labelStyle,
        isRequired: isRequired,
      ),
      labelStyle: labelStyle,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.borderGray.withValues(alpha: 0.55),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.borderGray.withValues(alpha: 0.4),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }

  Future<void> _pickDob() async {
    if (widget.readOnly) return;
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 90, now.month, now.day);
    final lastDate = DateTime(now.year - 18, now.month, now.day);
    final initial = _dob != null && !_dob!.isAfter(lastDate) ? _dob! : lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
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
    setState(() => _dob = picked);
  }

  bool _validateCurrentStep() {
    if (widget.readOnly) return true;

    switch (_stepIndex) {
      case 0:
        final ok = _personalKey.currentState?.validate() ?? false;
        if (!ok) return false;
        if (_dob == null) {
          _snack('Please select Date of Birth.');
          return false;
        }
        return true;
      case 1:
        return _addressKey.currentState?.validate() ?? false;
      case 2:
        final ok = _identityKey.currentState?.validate() ?? false;
        if (!ok) return false;
        if (_identityFront == null) {
          _snack('Please upload the front image of your ID.');
          return false;
        }
        return true;
      case 3:
        return _bankKey.currentState?.validate() ?? false;
      case 4:
        if (_profilePhoto == null) {
          _snack('Please add a profile photo.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _goNext() async {
    FocusScope.of(context).unfocus();
    if (!_validateCurrentStep()) return;

    if (_isLastStep) {
      await _submit();
      return;
    }

    setState(() => _stepIndex++);
    await _pageController.animateToPage(
      _stepIndex,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goPrevious() async {
    FocusScope.of(context).unfocus();
    if (_stepIndex <= 0) return;
    setState(() => _stepIndex--);
    await _pageController.animateToPage(
      _stepIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
    if (widget.readOnly) {
      Navigator.of(context).pop();
      return;
    }
    if (_dob == null || _identityFront == null || _profilePhoto == null) {
      _snack('Please complete all required fields.');
      return;
    }

    setState(() => _submitting = true);
    await _service.submitOrUpdateMyKyc(
      fullName: _fullNameCtrl.text.trim(),
      mobileNumber: _mobileCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      dateOfBirth: _dob!,
      gender: _gender,
      addressLine: _addressLineCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
      identityProofType: _identityType,
      identityNumber: _identityNumberCtrl.text.trim(),
      aadhaarNumber: _identityType == IdentityProofType.aadhaar
          ? _identityNumberCtrl.text.trim()
          : '',
      accountHolderName: _accountHolderCtrl.text.trim(),
      bankName: _bankNameCtrl.text.trim(),
      accountNumber: _accountNumberCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim(),
      emergencyContactName: _emgNameCtrl.text.trim(),
      emergencyContactMobile: _emgMobileCtrl.text.trim(),
      emergencyContactRelation: _emgRelationCtrl.text.trim(),
      profilePhotoPath: _profilePhoto!.path,
      identityFrontPath: _identityFront!.path,
      identityBackPath: _identityBack?.path,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'KYC submitted successfully.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.headingBlack,
      ),
    );
    Navigator.of(context).pop();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.headingBlack,
      ),
    );
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 24;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final contentMax = width >= 900 ? 640.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.headingBlack,
        elevation: 0,
        title: Text(
          widget.readOnly ? 'KYC Details' : 'Complete KYC',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(
              hPad: hPad,
              stepIndex: _stepIndex,
              totalSteps: _totalSteps,
              title: _stepTitles[_stepIndex],
              progress: _progress,
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
                      _StepScaffold(
                        hPad: hPad,
                        child: Form(
                          key: _personalKey,
                          child: _PersonalStep(
                            fullNameCtrl: _fullNameCtrl,
                            mobileCtrl: _mobileCtrl,
                            emailCtrl: _emailCtrl,
                            employeeId: _employeeId,
                            dob: _dob,
                            gender: _gender,
                            readOnly: widget.readOnly,
                            decoration: _fieldDecoration,
                            onPickDob: _pickDob,
                            onGenderChanged: (v) =>
                                setState(() => _gender = v),
                          ),
                        ),
                      ),
                      _StepScaffold(
                        hPad: hPad,
                        child: Form(
                          key: _addressKey,
                          child: _AddressStep(
                            addressCtrl: _addressLineCtrl,
                            cityCtrl: _cityCtrl,
                            stateCtrl: _stateCtrl,
                            pincodeCtrl: _pincodeCtrl,
                            readOnly: widget.readOnly,
                            decoration: _fieldDecoration,
                          ),
                        ),
                      ),
                      _StepScaffold(
                        hPad: hPad,
                        child: Form(
                          key: _identityKey,
                          child: _IdentityStep(
                            identityType: _identityType,
                            identityNumberCtrl: _identityNumberCtrl,
                            front: _identityFront,
                            back: _identityBack,
                            readOnly: widget.readOnly,
                            decoration: _fieldDecoration,
                            onTypeChanged: (v) =>
                                setState(() => _identityType = v),
                            onPickFront: () async {
                              final file =
                                  await pickPurchaseImageFile(context);
                              if (file == null) return;
                              setState(() => _identityFront = file);
                            },
                            onPickBack: () async {
                              final file =
                                  await pickPurchaseImageFile(context);
                              if (file == null) return;
                              setState(() => _identityBack = file);
                            },
                          ),
                        ),
                      ),
                      _StepScaffold(
                        hPad: hPad,
                        child: Form(
                          key: _bankKey,
                          child: _BankStep(
                            accountHolderCtrl: _accountHolderCtrl,
                            bankNameCtrl: _bankNameCtrl,
                            accountNumberCtrl: _accountNumberCtrl,
                            confirmAccountNumberCtrl:
                                _confirmAccountNumberCtrl,
                            ifscCtrl: _ifscCtrl,
                            readOnly: widget.readOnly,
                            decoration: _fieldDecoration,
                          ),
                        ),
                      ),
                      _StepScaffold(
                        hPad: hPad,
                        child: _PhotoStep(
                          photo: _profilePhoto,
                          readOnly: widget.readOnly,
                          onPick: () async {
                            final file =
                                await pickPurchaseImageFile(context);
                            if (file == null) return;
                            setState(() => _profilePhoto = file);
                          },
                        ),
                      ),
                      _StepScaffold(
                        hPad: hPad,
                        child: _ReviewStep(
                          fullName: _fullNameCtrl.text.trim(),
                          employeeId: _employeeId,
                          mobile: _mobileCtrl.text.trim(),
                          email: _emailCtrl.text.trim(),
                          dob: _dob,
                          gender: _gender,
                          address: _addressLineCtrl.text.trim(),
                          city: _cityCtrl.text.trim(),
                          state: _stateCtrl.text.trim(),
                          pincode: _pincodeCtrl.text.trim(),
                          identityType: _identityType,
                          identityNumber: _identityNumberCtrl.text.trim(),
                          front: _identityFront,
                          back: _identityBack,
                          accountHolder: _accountHolderCtrl.text.trim(),
                          bankName: _bankNameCtrl.text.trim(),
                          accountNumber: _accountNumberCtrl.text.trim(),
                          ifsc: _ifscCtrl.text.trim(),
                          profilePhoto: _profilePhoto,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _BottomNavBar(
              hPad: hPad,
              bottomInset: bottomInset,
              stepIndex: _stepIndex,
              isLast: _isLastStep,
              readOnly: widget.readOnly,
              submitting: _submitting,
              onPrevious: _goPrevious,
              onNext: _goNext,
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
    required this.totalSteps,
    required this.title,
    required this.progress,
  });

  final double hPad;
  final int stepIndex;
  final int totalSteps;
  final String title;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.cardWhite,
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Step ${stepIndex + 1} of $totalSteps — $title',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ),
              Text(
                '${((progress) * 100).round()}%',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.borderGray.withValues(alpha: 0.35),
                  color: AppColors.primaryRed,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _StepDots(current: stepIndex, total: totalSteps),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: done || active
                  ? AppColors.primaryRed
                  : AppColors.borderGray.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.hPad, required this.child});

  final double hPad;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(hPad < 16 ? 14 : 18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.borderGray.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.hPad,
    required this.bottomInset,
    required this.stepIndex,
    required this.isLast,
    required this.readOnly,
    required this.submitting,
    required this.onPrevious,
    required this.onNext,
  });

  final double hPad;
  final double bottomInset;
  final int stepIndex;
  final bool isLast;
  final bool readOnly;
  final bool submitting;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final nextLabel = readOnly && isLast
        ? 'Done'
        : isLast
            ? 'Submit KYC'
            : 'Next';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          top: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          if (stepIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: submitting ? null : onPrevious,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: BorderSide(
                    color: AppColors.primaryRed.withValues(alpha: 0.7),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          if (stepIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: stepIndex == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: submitting ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.white,
                disabledBackgroundColor:
                    AppColors.primaryRed.withValues(alpha: 0.45),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      nextLabel,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalStep extends StatelessWidget {
  const _PersonalStep({
    required this.fullNameCtrl,
    required this.mobileCtrl,
    required this.emailCtrl,
    required this.employeeId,
    required this.dob,
    required this.gender,
    required this.readOnly,
    required this.decoration,
    required this.onPickDob,
    required this.onGenderChanged,
  });

  final TextEditingController fullNameCtrl;
  final TextEditingController mobileCtrl;
  final TextEditingController emailCtrl;
  final String employeeId;
  final DateTime? dob;
  final String gender;
  final bool readOnly;
  final InputDecoration Function(String, {bool isRequired}) decoration;
  final VoidCallback onPickDob;
  final ValueChanged<String> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your personal details',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Make sure the information matches your official records.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: fullNameCtrl,
          enabled: !readOnly,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('Full Name', isRequired: !readOnly),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: employeeId,
          enabled: false,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('Employee ID (Read Only)'),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: mobileCtrl,
          enabled: !readOnly,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('Mobile Number', isRequired: !readOnly),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Mobile is required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: emailCtrl,
          enabled: !readOnly,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('Email', isRequired: !readOnly),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Email is required' : null,
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: readOnly ? null : onPickDob,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: decoration('Date of Birth', isRequired: !readOnly),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dob == null
                        ? 'Select date'
                        : DateFormat('dd MMM yyyy').format(dob!),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dob == null
                          ? AppColors.inputHint
                          : AppColors.headingBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: gender,
          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),
            DropdownMenuItem(value: 'Female', child: Text('Female')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: readOnly ? null : (v) {
            if (v != null) onGenderChanged(v);
          },
          decoration: decoration('Gender'),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.headingBlack,
          ),
        ),
      ],
    );
  }
}

class _AddressStep extends StatelessWidget {
  const _AddressStep({
    required this.addressCtrl,
    required this.cityCtrl,
    required this.stateCtrl,
    required this.pincodeCtrl,
    required this.readOnly,
    required this.decoration,
  });

  final TextEditingController addressCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController pincodeCtrl;
  final bool readOnly;
  final InputDecoration Function(String, {bool isRequired}) decoration;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 420;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where do you currently live?',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Provide your residential address details.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: addressCtrl,
          enabled: !readOnly,
          maxLines: 2,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('Address', isRequired: !readOnly),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Address is required' : null,
        ),
        const SizedBox(height: 14),
        if (narrow) ...[
          TextFormField(
            controller: cityCtrl,
            enabled: !readOnly,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: decoration('City', isRequired: !readOnly),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'City is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: stateCtrl,
            enabled: !readOnly,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: decoration('State', isRequired: !readOnly),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'State is required' : null,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: cityCtrl,
                  enabled: !readOnly,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: decoration('City', isRequired: !readOnly),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'City is required'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: stateCtrl,
                  enabled: !readOnly,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: decoration('State', isRequired: !readOnly),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'State is required'
                      : null,
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        TextFormField(
          controller: pincodeCtrl,
          enabled: !readOnly,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('PIN Code', isRequired: !readOnly),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'PIN Code is required' : null,
        ),
      ],
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.identityType,
    required this.identityNumberCtrl,
    required this.front,
    required this.back,
    required this.readOnly,
    required this.decoration,
    required this.onTypeChanged,
    required this.onPickFront,
    required this.onPickBack,
  });

  final IdentityProofType identityType;
  final TextEditingController identityNumberCtrl;
  final File? front;
  final File? back;
  final bool readOnly;
  final InputDecoration Function(String, {bool isRequired}) decoration;
  final ValueChanged<IdentityProofType> onTypeChanged;
  final VoidCallback onPickFront;
  final VoidCallback onPickBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify your identity',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload a clear photo of your identity document.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<IdentityProofType>(
          value: identityType,
          items: IdentityProofType.values
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.label),
                ),
              )
              .toList(),
          onChanged: readOnly
              ? null
              : (v) {
                  if (v != null) onTypeChanged(v);
                },
          decoration: decoration('Identity Type'),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: identityNumberCtrl,
          enabled: !readOnly,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('Identity Number', isRequired: !readOnly),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Identity Number is required'
              : null,
        ),
        const SizedBox(height: 16),
        _UploadCard(
          title: 'Upload Front Image',
          subtitle: 'Required',
          file: front,
          onTap: readOnly ? null : onPickFront,
          isRequired: !readOnly,
        ),
        const SizedBox(height: 12),
        _UploadCard(
          title: 'Upload Back Image',
          subtitle: 'Optional',
          file: back,
          onTap: readOnly ? null : onPickBack,
        ),
      ],
    );
  }
}

class _BankStep extends StatelessWidget {
  const _BankStep({
    required this.accountHolderCtrl,
    required this.bankNameCtrl,
    required this.accountNumberCtrl,
    required this.confirmAccountNumberCtrl,
    required this.ifscCtrl,
    required this.readOnly,
    required this.decoration,
  });

  final TextEditingController accountHolderCtrl;
  final TextEditingController bankNameCtrl;
  final TextEditingController accountNumberCtrl;
  final TextEditingController confirmAccountNumberCtrl;
  final TextEditingController ifscCtrl;
  final bool readOnly;
  final InputDecoration Function(String, {bool isRequired}) decoration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bank account details',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Used for salary and reimbursements.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: accountHolderCtrl,
          enabled: !readOnly,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('Account Holder Name', isRequired: !readOnly),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Account holder name is required'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: bankNameCtrl,
          enabled: !readOnly,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('Bank Name', isRequired: !readOnly),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Bank name is required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: accountNumberCtrl,
          enabled: !readOnly,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('Account Number', isRequired: !readOnly),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Account number is required'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: confirmAccountNumberCtrl,
          enabled: !readOnly,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration(
            'Confirm Account Number',
            isRequired: !readOnly,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Confirm account number';
            }
            if (v.trim() != accountNumberCtrl.text.trim()) {
              return 'Account numbers do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: ifscCtrl,
          enabled: !readOnly,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: decoration('IFSC Code', isRequired: !readOnly),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'IFSC is required' : null,
        ),
      ],
    );
  }
}

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.photo,
    required this.readOnly,
    required this.onPick,
  });

  final File? photo;
  final bool readOnly;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add your profile photo',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Take a clear selfie or choose from gallery.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.borderGray.withValues(alpha: 0.55),
                  ),
                  image: photo == null
                      ? null
                      : DecorationImage(
                          image: FileImage(photo!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: photo == null
                    ? const Icon(
                        Icons.person_outline_rounded,
                        size: 64,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              const SizedBox(height: 18),
              if (!readOnly)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      photo == null
                          ? 'Take Photo / Choose Gallery'
                          : 'Change Photo',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: BorderSide(
                        color: AppColors.primaryRed.withValues(alpha: 0.75),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.fullName,
    required this.employeeId,
    required this.mobile,
    required this.email,
    required this.dob,
    required this.gender,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.identityType,
    required this.identityNumber,
    required this.front,
    required this.back,
    required this.accountHolder,
    required this.bankName,
    required this.accountNumber,
    required this.ifsc,
    required this.profilePhoto,
  });

  final String fullName;
  final String employeeId;
  final String mobile;
  final String email;
  final DateTime? dob;
  final String gender;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final IdentityProofType identityType;
  final String identityNumber;
  final File? front;
  final File? back;
  final String accountHolder;
  final String bankName;
  final String accountNumber;
  final String ifsc;
  final File? profilePhoto;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review your details',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Please confirm everything looks correct before submitting.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _ReviewSection(
          title: 'Personal Information',
          rows: [
            ('Full Name', fullName),
            ('Employee ID', employeeId),
            ('Mobile', mobile),
            ('Email', email),
            ('Date of Birth', dob == null ? '--' : dateFmt.format(dob!)),
            ('Gender', gender),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewSection(
          title: 'Address Details',
          rows: [
            ('Address', address),
            ('City', city),
            ('State', state),
            ('PIN Code', pincode),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewSection(
          title: 'Identity Verification',
          rows: [
            ('Identity Type', identityType.label),
            ('Identity Number', identityNumber),
            ('Front Image', front == null ? 'Missing' : 'Uploaded'),
            ('Back Image', back == null ? 'Not uploaded' : 'Uploaded'),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewSection(
          title: 'Bank Details',
          rows: [
            ('Account Holder', accountHolder),
            ('Bank Name', bankName),
            ('Account Number', accountNumber),
            ('IFSC Code', ifsc),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewSection(
          title: 'Profile Photo',
          rows: [
            ('Photo', profilePhoto == null ? 'Missing' : 'Uploaded'),
          ],
        ),
        if (profilePhoto != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              profilePhoto!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 8),
          for (final row in rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    row.$1,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.$2.isEmpty ? '--' : row.$2,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headingBlack,
                    ),
                  ),
                ),
              ],
            ),
            if (row != rows.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onTap,
    this.isRequired = false,
  });

  final String title;
  final String subtitle;
  final File? file;
  final VoidCallback? onTap;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderGray.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldLabelText(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.headingBlack,
                          ),
                          isRequired: isRequired,
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    file == null
                        ? Icons.upload_rounded
                        : Icons.check_circle_rounded,
                    color: file == null
                        ? AppColors.primaryRed
                        : const Color(0xFF059669),
                  ),
                ],
              ),
              if (file != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    file!,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
