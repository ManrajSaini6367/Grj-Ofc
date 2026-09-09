import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import 'package:grjoffice_apps/EmployeeListscreen/employee.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/mykycdatamodal.dart';
import 'package:grjoffice_apps/payoutscreen/payslip_pdf.dart';
import 'package:grjoffice_apps/payoutscreen/salary_calculator.dart';
import 'package:grjoffice_apps/utils/app_helpers.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';

/// Who bears an allowance, matching the Accomodation and Food columns of the
/// salary register.
enum PaidBy { self, company }

/// Prefilled, editable salary sheet for one employee for one month.
///
/// The fields follow the monthly salary register: leaves, working days,
/// accomodation and food, the basic / HRA split, and the statutory deductions.
/// Everything is auto filled and can be overridden before the payslip is made.
class GenerateSalaryScreen extends StatefulWidget {
  const GenerateSalaryScreen({
    super.key,
    required this.employee,
    required this.month,
    this.kyc,
    this.monthlySalary,
    this.presentDays,
    this.leaveDays,
    this.absentDays,
  });

  final Employee employee;
  final DateTime month;
  final MyKycModalData? kyc;
  final double? monthlySalary;
  final int? presentDays;
  final int? leaveDays;
  final int? absentDays;

  @override
  State<GenerateSalaryScreen> createState() => _GenerateSalaryScreenState();
}

class _GenerateSalaryScreenState extends State<GenerateSalaryScreen> {
  late final TextEditingController _package;
  late final TextEditingController _basicPercent;
  late final TextEditingController _monthDays;
  late final TextEditingController _actualDays;
  late final TextEditingController _paidLeave;
  late final TextEditingController _previousLeaves;
  late final TextEditingController _balanceLeave;
  late final TextEditingController _payableDays;
  late final TextEditingController _foodAmount;
  late final TextEditingController _advance;
  late final TextEditingController _leavesRemark;
  late final TextEditingController _remarks;

  PaidBy _accomodation = PaidBy.self;
  PaidBy _food = PaidBy.self;
  bool _pfApplicable = true;
  bool _esiApplicable = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    final kyc = widget.kyc;
    final monthDays = DateUtils.getDaysInMonth(
      widget.month.year,
      widget.month.month,
    );
    final actual = (widget.presentDays ?? 0).toDouble();
    final leave = (widget.leaveDays ?? 0).toDouble();

    _package = TextEditingController(
      text: _plain(
        widget.monthlySalary ?? _amountOf(widget.employee.monthlySalary),
      ),
    );
    _basicPercent = TextEditingController(
      text: _plain(SalaryRules.defaultBasicPercent),
    );
    _monthDays = TextEditingController(text: '$monthDays');
    _actualDays = TextEditingController(text: _plain(actual));
    _paidLeave = TextEditingController(text: _plain(leave));
    _previousLeaves = TextEditingController(text: '0');
    _balanceLeave = TextEditingController(
      text: _plain(_remainingLeaveAllocation(leave)),
    );
    _payableDays = TextEditingController(text: _plain(actual + leave));
    _advance = TextEditingController(text: '0');
    _leavesRemark = TextEditingController();
    _remarks = TextEditingController();

    _accomodation = _paidByOf(kyc?.stayAllowanceType);
    _food = _paidByOf(kyc?.foodAllowanceType);
    _foodAmount = TextEditingController(
      text: _plain(
        _amountOf(
          _food == PaidBy.company
              ? kyc?.foodCompanyAmount
              : kyc?.foodEmployeeAmount,
        ),
      ),
    );

    // Payable days follow the leave fields until the user overrides them.
    _actualDays.addListener(_syncPayableDays);
    _paidLeave.addListener(_syncPayableDays);
    _previousLeaves.addListener(_syncPayableDays);
    for (final controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }

    final basic = SalaryBreakdown.from(_input).earnedBasic;
    _pfApplicable = basic > 0;
    _esiApplicable = SalaryRules.esiAppliesTo(basic);
  }

  List<TextEditingController> get _controllers => [
    _package,
    _basicPercent,
    _monthDays,
    _actualDays,
    _paidLeave,
    _previousLeaves,
    _balanceLeave,
    _payableDays,
    _foodAmount,
    _advance,
    _leavesRemark,
    _remarks,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _syncPayableDays() {
    final payable =
        _read(_actualDays) + _read(_paidLeave) + _read(_previousLeaves);
    final text = _plain(payable);
    if (_payableDays.text == text) return;
    _payableDays.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Leaves still in hand after this month, from the employee's allocation.
  double? _remainingLeaveAllocation(double used) {
    final allocated = widget.employee.leaveAllocation;
    if (allocated == null) return null;
    final balance = allocated - used;
    return balance < 0 ? 0 : balance;
  }

  PaidBy _paidByOf(String? type) {
    final value = type?.toLowerCase() ?? '';
    return value.contains('company') ? PaidBy.company : PaidBy.self;
  }

  double? _amountOf(String? raw) {
    final value = raw?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '';
    final parsed = double.tryParse(value);
    return (parsed == null || parsed <= 0) ? null : parsed;
  }

  double _read(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  SalaryInput get _input => SalaryInput(
    monthlyPackage: _read(_package),
    monthDays: _read(_monthDays).round(),
    payableDays: _read(_payableDays),
    basicPercent: _read(_basicPercent),
    pfApplicable: _pfApplicable,
    esiApplicable: _esiApplicable,
    otherDeduction: _read(_advance),
  );

  SalaryBreakdown get _breakdown => SalaryBreakdown.from(_input);

  /// Leaves actually adjusted this month, printed as `PL` on the payslip.
  double get _leavesAdjusted {
    final adjusted = _read(_payableDays) - _read(_actualDays);
    return adjusted < 0 ? 0 : adjusted;
  }

  double get _absentDays {
    final absent = _read(_monthDays) - _read(_payableDays);
    return absent < 0 ? 0 : absent;
  }

  String get _monthLabel => DateFormat('MMMM yyyy').format(widget.month);

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Generate Salary',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _headerCard(),
                        const SizedBox(height: 14),
                        _attendanceSection(),
                        const SizedBox(height: 14),
                        _structureSection(),
                        const SizedBox(height: 14),
                        _deductionSection(),
                        const SizedBox(height: 14),
                        _allowanceSection(),
                        const SizedBox(height: 14),
                        _previewSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _bottomBar(hPad),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _headerCard() {
    final employee = widget.employee;
    final kyc = widget.kyc;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryRed, Color(0xFF5F1212)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    employee.initials,
                    style: GoogleFonts.poppins(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      '${employee.role}  ·  ${employee.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _headerPill(Icons.calendar_month_outlined, _monthLabel),
              const SizedBox(width: 8),
              _headerPill(
                Icons.account_balance_outlined,
                _dash(kyc?.bankName ?? '').length > 16
                    ? '${kyc!.bankName!.substring(0, 16)}…'
                    : _dash(kyc?.bankName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- sections

  Widget _attendanceSection() {
    return _section(
      icon: Icons.event_available_outlined,
      title: 'Attendance & leaves',
      children: [
        _rowField('Monthly working days', _monthDays, isRequired: true),
        _rowField('Actual working days', _actualDays),
        _rowField('Paid leave', _paidLeave),
        _rowField('Previous leaves adjusted', _previousLeaves),
        _rowField(
          'Payable working days',
          _payableDays,
          highlight: true,
          isRequired: true,
        ),
        _rowField('Balance leave', _balanceLeave),
        _rowValue('Absent days', _plain(_absentDays)),
        _rowText('Leaves remark', _leavesRemark, hint: 'e.g. 1.5 PL adjusted'),
      ],
    );
  }

  Widget _structureSection() {
    final breakdown = _breakdown;
    final basicPercent = _read(_basicPercent);
    final belowMinimum = basicPercent < SalaryRules.minBasicPercent;
    return _section(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Salary structure',
      children: [
        _rowField(
          'Salary package',
          _package,
          highlight: true,
          isRequired: true,
        ),
        _rowField('Basic %', _basicPercent, isRequired: true),
        _rowValue('HRA %', _plain(100 - basicPercent)),
        if (belowMinimum)
          _note(
            'Basic must be at least ${_plain(SalaryRules.minBasicPercent)}% of the package.',
            warning: true,
          ),
        _rowValue('Basic', _money(breakdown.earnedBasic)),
        _rowValue('HRA', _money(breakdown.earnedHra)),
        _rowValue('Gross salary', _money(breakdown.earnedGross), bold: true),
      ],
    );
  }

  Widget _deductionSection() {
    final breakdown = _breakdown;
    final basic = breakdown.earnedBasic;
    final pfCapped = basic > SalaryRules.pfWageCeiling;
    final esiOverLimit = basic >= SalaryRules.esiWageLimit;
    return _section(
      icon: Icons.remove_circle_outline,
      title: 'Deductions',
      children: [
        _switchRow(
          label: 'PF',
          note: pfCapped
              ? 'Capped at 12% of ${_money(SalaryRules.pfWageCeiling)}'
              : '12% of basic',
          amount: breakdown.pf,
          value: _pfApplicable,
          onChanged: (value) => setState(() => _pfApplicable = value),
        ),
        _switchRow(
          label: 'ESI',
          note: esiOverLimit
              ? 'Basic over ${_money(SalaryRules.esiWageLimit)} — keep on till quarter end'
              : '0.75% of basic',
          amount: breakdown.esi,
          value: _esiApplicable,
          onChanged: (value) => setState(() => _esiApplicable = value),
        ),
        _rowField('Advance', _advance),
        _rowValue(
          'Total deduction',
          _money(breakdown.totalDeduction),
          bold: true,
        ),
      ],
    );
  }

  Widget _allowanceSection() {
    return _section(
      icon: Icons.hotel_outlined,
      title: 'Accomodation & food',
      children: [
        _rowSegmented(
          'Accomodation',
          _accomodation,
          (value) => setState(() => _accomodation = value),
        ),
        _rowSegmented('Food', _food, (value) => setState(() => _food = value)),
        _rowField('Food amount', _foodAmount),
        _note('Kept for the register. It does not change the gross pay.'),
      ],
    );
  }

  Widget _previewSection() {
    final breakdown = _breakdown;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.operationsCardBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 17,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payslip preview',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _previewColumn('EARNINGS', [
                          ['Basic', breakdown.earnedBasic],
                          ['HRA', breakdown.earnedHra],
                          ['Gross', breakdown.earnedGross],
                        ]),
                      ),
                      VerticalDivider(
                        width: 24,
                        thickness: 1,
                        color: AppColors.borderGray.withValues(alpha: 0.5),
                      ),
                      Expanded(
                        child: _previewColumn('DEDUCTIONS', [
                          ['PF', breakdown.pf],
                          ['ESI', breakdown.esi],
                          ['Advance', breakdown.otherDeduction],
                          ['Total', breakdown.totalDeduction],
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _rowText('Remarks', _remarks, hint: 'Optional note'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewColumn(String title, List<List<Object>> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < rows.length; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i][0] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: i == rows.length - 1
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: i == rows.length - 1
                          ? AppColors.headingBlack
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  _money(rows[i][1] as double),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: i == rows.length - 1
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: AppColors.headingBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------- bottom action

  Widget _bottomBar(double hPad) {
    final breakdown = _breakdown;
    return Container(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Net payable',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _money(breakdown.netPayable),
                      style: GoogleFonts.poppins(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    disabledBackgroundColor: AppColors.primaryRed.withValues(
                      alpha: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 18,
                          color: AppColors.white,
                        ),
                  label: Text(
                    'Generate',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ generate

  Future<void> _generate() async {
    final input = _input;
    if (input.monthlyPackage <= 0) {
      message(context, 'Enter the salary package.');
      return;
    }
    if (input.monthDays <= 0) {
      message(context, 'Enter the monthly working days.');
      return;
    }
    if (input.payableDays <= 0) {
      message(context, 'Payable working days must be more than zero.');
      return;
    }
    if (input.payableDays > input.monthDays) {
      message(
        context,
        'Payable working days cannot exceed the monthly working days.',
      );
      return;
    }
    if (input.basicPercent < SalaryRules.minBasicPercent ||
        input.basicPercent > 100) {
      message(
        context,
        'Basic must be between ${_plain(SalaryRules.minBasicPercent)}% and 100%.',
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final file = await generatePayslipFile(_payslipData());
      if (!mounted) return;
      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (result.type == ResultType.done) {
        message(context, 'Payslip generated for ${widget.employee.name}.');
      } else {
        message(context, 'Payslip saved at ${file.path}');
      }
    } catch (e) {
      debugPrint('[GenerateSalaryScreen] payslip failed: $e');
      if (mounted) message(context, 'Could not generate the payslip.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  PayslipData _payslipData() {
    final kyc = widget.kyc;
    final leavesAdjusted = _leavesAdjusted;
    final absent = _absentDays;
    return PayslipData(
      month: widget.month,
      employeeName: widget.employee.name,
      breakdown: _breakdown,
      employeeCode: widget.employee.id,
      department: kyc?.assignedSite ?? widget.employee.site,
      designation: widget.employee.role,
      dateOfJoining: _joiningDate(),
      bankName: kyc?.bankName ?? '',
      location: kyc?.assignedSite ?? widget.employee.site,
      bankAccountNumber: kyc?.accountNumber ?? '',
      remarks: _remarkLine(),
      attendance: [
        PayslipAttendanceLine('P', _plain(_read(_actualDays))),
        if (leavesAdjusted > 0)
          PayslipAttendanceLine('PL', _plain(leavesAdjusted)),
        PayslipAttendanceLine('Pay Days', _plain(_read(_payableDays))),
        if (absent > 0) PayslipAttendanceLine('AB', _plain(absent)),
      ],
    );
  }

  String _remarkLine() {
    final notes = [
      _leavesRemark.text.trim(),
      _remarks.text.trim(),
    ].where((note) => note.isNotEmpty);
    return notes.join('  ·  ');
  }

  String _joiningDate() {
    final raw = widget.kyc?.joiningDate?.trim();
    if (raw != null && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      return parsed == null ? raw : DateFormat('dd/MMM/yyyy').format(parsed);
    }
    final date = widget.employee.dateOfJoin;
    return date == null ? '' : DateFormat('dd/MMM/yyyy').format(date);
  }

  // ------------------------------------------------------ shared widgets

  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 17, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.borderGray.withValues(alpha: 0.4),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Register style line: caption on the left, compact input on the right.
  Widget _rowField(
    String label,
    TextEditingController controller, {
    bool highlight = false,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: _rowLabel(label, bold: highlight, isRequired: isRequired),
          ),
          SizedBox(
            width: 118,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.headingBlack,
              ),
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: highlight
                    ? AppColors.primaryRed.withValues(alpha: 0.06)
                    : AppColors.operationsCardBg,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.inputHint,
                ),
                border: _fieldBorder(highlight),
                enabledBorder: _fieldBorder(highlight),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: AppColors.primaryRed,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _fieldBorder(bool highlight) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: highlight
            ? AppColors.primaryRed.withValues(alpha: 0.45)
            : AppColors.borderGray.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _rowText(
    String label,
    TextEditingController controller, {
    required String hint,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowLabel(label, isRequired: isRequired),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.headingBlack,
            ),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              filled: true,
              fillColor: AppColors.operationsCardBg,
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.inputHint,
              ),
              border: _fieldBorder(false),
              enabledBorder: _fieldBorder(false),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(
                  color: AppColors.primaryRed,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowValue(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: _rowLabel(label, bold: bold)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: bold ? 15 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.headingBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowSegmented(
    String label,
    PaidBy value,
    ValueChanged<PaidBy> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: _rowLabel(label)),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.operationsCardBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in PaidBy.values)
                  GestureDetector(
                    onTap: () => onChanged(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: value == option
                            ? AppColors.primaryRed
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        option == PaidBy.self ? 'Self' : 'Company',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: value == option
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required String note,
    required double amount,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rowLabel(label),
                Text(
                  note,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _money(amount),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: value ? AppColors.headingBlack : AppColors.textSecondary,
            ),
          ),
          SizedBox(
            width: 52,
            child: Transform.scale(
              scale: 0.82,
              child: Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowLabel(String text, {bool bold = false, bool isRequired = false}) {
    return fieldLabelText(
      text,
      isRequired: isRequired,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        color: bold ? AppColors.headingBlack : AppColors.textDark,
      ),
    );
  }

  Widget _note(String text, {bool warning = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: warning ? FontWeight.w600 : FontWeight.w400,
          color: warning ? AppColors.primaryRed : AppColors.textSecondary,
        ),
      ),
    );
  }

  String _dash(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '—' : trimmed;
  }

  String _money(double amount) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  ).format(amount);

  /// Formats a number without a trailing `.0` so day counts read as `29` but
  /// half days still read as `29.5`.
  static String _plain(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }
}
