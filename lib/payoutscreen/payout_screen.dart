import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:grjoffice_apps/EmployeeListscreen/employee.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/models/getcalendermodal.dart';
import 'package:grjoffice_apps/models/getemployeemodal.dart';
import 'package:grjoffice_apps/models/mykycdatamodal.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/payoutscreen/generate_salary_screen.dart';
import 'package:grjoffice_apps/payoutscreen/salary_calculator.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

/// Monthly employee payout overview. All employee data is shown on this screen.
class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  List<_PayoutEmployee> _employees = const [];
  bool _loading = true;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static const _presentColor = Color(0xFF047857);
  static const _absentColor = Color(0xFFB91C1C);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPayouts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth =>
      _month.year == _currentMonth.year && _month.month == _currentMonth.month;

  String get _monthApi => DateFormat('yyyy-MM').format(_month);

  String get _monthLabel => DateFormat('MMMM yyyy').format(_month);

  String get _siteLabel {
    final name = selectedSiteName()?.trim();
    if (name == null || name.isEmpty) return 'All sites';
    return name;
  }

  Future<void> _shiftMonth(int delta) async {
    final next = DateTime(_month.year, _month.month + delta);
    if (next.isAfter(_currentMonth)) return;
    setState(() => _month = next);
    await _loadPayouts();
  }

  Future<void> _loadPayouts() async {
    setState(() => _loading = true);
    final response = await getEmployeesApi(
      context,
      perPage: 15,
      fetchAllPages: true,
    );
    if (!mounted) return;

    final activeEmployees =
        (response?.data?.items ?? const <EmployeeListItem>[])
            .where((item) => item.isActiveStatus)
            .map(_employeeFromApi)
            .toList();
    final kycByEmployee = await _loadKycRecords();
    if (!mounted) return;

    final rows = await Future.wait(
      activeEmployees.map(
        (employee) => _loadEmployeePayout(
          employee,
          _monthApi,
          kycByEmployee[employee.employeeId],
        ),
      ),
    );
    if (!mounted) return;
    rows.sort(
      (a, b) => a.employee.name.toLowerCase().compareTo(
        b.employee.name.toLowerCase(),
      ),
    );
    setState(() {
      _employees = rows;
      _loading = false;
    });
  }

  /// Pulls every KYC record for the site once and keys it by employee id.
  ///
  /// The per-employee endpoint takes a KYC record id, not an employee id, so
  /// the list endpoint is both the correct and the cheaper source here.
  Future<Map<int, MyKycModalData>> _loadKycRecords() async {
    final byEmployee = <int, MyKycModalData>{};
    var page = 1;
    while (true) {
      final response = await getMyEmployeeKycRequestApi(
        context,
        perPage: 50,
        page: page,
      );
      if (!mounted) break;
      final items = response?.items ?? const <MyKycModalData>[];
      for (final item in items) {
        final id = int.tryParse(item.employeeId ?? '');
        if (id != null) byEmployee[id] = item;
      }
      final lastPage = response?.pagination?.lastPage ?? page;
      if (items.isEmpty || page >= lastPage) break;
      page++;
    }
    return byEmployee;
  }

  Future<_PayoutEmployee> _loadEmployeePayout(
    Employee employee,
    String month,
    MyKycModalData? kyc,
  ) async {
    final employeeId = employee.employeeId;
    if (employeeId == null) {
      return _PayoutEmployee(
        employee: employee,
        monthDays: DateUtils.getDaysInMonth(_month.year, _month.month),
        monthlySalary: _salaryFromKyc(kyc) ?? _salaryOf(employee.monthlySalary),
        kyc: kyc,
      );
    }

    final calendar = await getAttendanceCalendarApi(
      context,
      month: month,
      userId: employeeId,
      showErrors: false,
    );
    final days = calendar?.data?.days ?? const [];
    final today = DateTime.now();
    final presentDays = days
        .where((day) => day.status == CalendarDayStatus.present)
        .length;
    final absentDays = days.where((day) {
      final date = day.date;
      return day.status == CalendarDayStatus.absent &&
          date != null &&
          !date.isAfter(DateTime(today.year, today.month, today.day));
    }).length;
    final leaveDays = days
        .where((day) => day.status == CalendarDayStatus.leave)
        .length;

    return _PayoutEmployee(
      employee: employee,
      monthDays: DateUtils.getDaysInMonth(_month.year, _month.month),
      presentDays: presentDays,
      absentDays: absentDays,
      leaveDays: leaveDays,
      monthlySalary: _salaryFromKyc(kyc) ?? _salaryOf(employee.monthlySalary),
      kyc: kyc,
    );
  }

  Employee _employeeFromApi(EmployeeListItem item) {
    final fullName = item.name?.trim().isNotEmpty == true
        ? item.name!.trim()
        : '${item.firstName ?? ''} ${item.lastName ?? ''}'.trim();
    return Employee(
      id: item.username?.trim().isNotEmpty == true
          ? item.username!.trim()
          : (item.id?.toString() ?? '-'),
      employeeId: item.id,
      name: fullName.isEmpty ? 'Employee' : fullName,
      role: item.designation?.trim().isNotEmpty == true
          ? item.designation!.trim()
          : 'Employee',
      site: selectedSiteName() ?? 'Assigned site',
      dateOfJoin: item.dateOfJoin,
      monthlySalary: item.monthlySalary,
    );
  }

  double? _salaryFromKyc(MyKycModalData? kyc) => _salaryOf(kyc?.monthlySalary);

  /// The API sends salary as a formatted string, so strip everything but the
  /// digits before parsing.
  double? _salaryOf(String? raw) {
    final value = raw?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '';
    final parsed = double.tryParse(value);
    return (parsed == null || parsed <= 0) ? null : parsed;
  }

  List<_PayoutEmployee> get _filteredEmployees {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _employees;
    return _employees.where((entry) {
      final employee = entry.employee;
      return '${employee.name} ${employee.id} ${employee.role}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  int get _salaryCount =>
      _employees.where((entry) => entry.breakdown != null).length;

  double get _totalGross => _employees.fold<double>(
    0,
    (sum, entry) => sum + (entry.breakdown?.earnedGross ?? 0),
  );

  double get _totalDeduction => _employees.fold<double>(
    0,
    (sum, entry) => sum + (entry.breakdown?.totalDeduction ?? 0),
  );

  double get _totalNet => _employees.fold<double>(
    0,
    (sum, entry) => sum + (entry.breakdown?.netPayable ?? 0),
  );

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
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.payout,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Payout',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: _loadPayouts,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSummaryCard(),
                                  const SizedBox(height: 12),
                                  _buildKpiRow(),
                                  const SizedBox(height: 16),
                                  _buildSearch(),
                                  const SizedBox(height: 20),
                                  _buildSectionHeader(),
                                  const SizedBox(height: 10),
                                  if (_filteredEmployees.isEmpty)
                                    _buildEmptyState()
                                  else
                                    _buildRegister(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net salary payable',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _salaryCount == 0 ? '—' : _money(_totalNet),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMonthControl(),
                const SizedBox(height: 8),
                Text(
                  _siteLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primaryRed,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.operationsCardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _monthArrow(
            icon: Icons.chevron_left_rounded,
            onTap: () => _shiftMonth(-1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              _monthLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          _monthArrow(
            icon: Icons.chevron_right_rounded,
            onTap: _isCurrentMonth ? null : () => _shiftMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _monthArrow({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? AppColors.textDark
              : AppColors.textSecondary.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            label: 'Employees',
            value: '${_employees.length}',
            icon: Icons.groups_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiCard(
            label: 'Gross salary',
            value: _salaryCount == 0 ? '—' : _money(_totalGross),
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiCard(
            label: 'Deductions',
            value: _salaryCount == 0 ? '—' : _money(_totalDeduction),
            icon: Icons.remove_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryRed),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    final hasQuery = _searchController.text.isNotEmpty;
    return TextField(
      controller: _searchController,
      style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search by name, role or ID',
        hintStyle: GoogleFonts.poppins(
          color: AppColors.inputHint,
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
          size: 22,
        ),
        suffixIcon: hasQuery
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () => _searchController.clear(),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    final count = _filteredEmployees.length;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Payroll register',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
        ),
        Text(
          count == 1 ? '1 employee' : '$count employees',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRegister() {
    final rows = _filteredEmployees;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _buildEmployeeRow(rows[i]),
            if (i < rows.length - 1)
              Divider(
                height: 1,
                indent: 72,
                color: AppColors.borderGray.withValues(alpha: 0.35),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeRow(_PayoutEmployee entry) {
    final employee = entry.employee;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openGenerateSalary(entry),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(employee.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            employee.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.headingBlack,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _money(entry.breakdown?.netPayable),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.headingBlack,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${employee.role}  ·  ${employee.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildSalaryLine(entry),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _attendanceChip(
                          label: '${entry.presentDays ?? '—'} Present',
                          color: _presentColor,
                        ),
                        const SizedBox(width: 8),
                        _attendanceChip(
                          label: '${entry.absentDays ?? '—'} Absent',
                          color: _absentColor,
                        ),
                        const SizedBox(width: 8),
                        _attendanceChip(
                          label: 'PD ${_days(entry.payableDays)}',
                          color: AppColors.primaryRed,
                        ),
                      ],
                    ),
                    if (entry.attendanceTotal > 0) ...[
                      const SizedBox(height: 8),
                      _attendanceBar(entry),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Package, gross and deduction line under the employee name, mirroring the
  /// salary register columns.
  Widget _buildSalaryLine(_PayoutEmployee entry) {
    final breakdown = entry.breakdown;
    if (breakdown == null) {
      return Text(
        'Salary package not set',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _absentColor,
        ),
      );
    }
    final parts = <String>[
      'Package ${_money(entry.monthlySalary)}',
      'Gross ${_money(breakdown.earnedGross)}',
      if (breakdown.totalDeduction > 0)
        'Deduction ${_money(breakdown.totalDeduction)}',
    ];
    return Text(
      parts.join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  String _days(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  Widget _buildAvatar(String initials) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primaryRed.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.22)),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            color: AppColors.primaryRed,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _attendanceChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _attendanceBar(_PayoutEmployee entry) {
    final ratio = entry.presentRatio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: ratio,
          backgroundColor: _absentColor.withValues(alpha: 0.16),
          valueColor: const AlwaysStoppedAnimation(_presentColor),
        ),
      ),
    );
  }

  void _openGenerateSalary(_PayoutEmployee entry) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GenerateSalaryScreen(
          employee: entry.employee,
          month: _month,
          kyc: entry.kyc,
          monthlySalary: entry.monthlySalary,
          presentDays: entry.presentDays,
          leaveDays: entry.leaveDays,
          absentDays: entry.absentDays,
        ),
      ),
    );
  }

  String _money(double? amount) {
    if (amount == null) return '—';
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  Widget _buildEmptyState() {
    final searching = _searchController.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searching ? Icons.search_off_rounded : Icons.payments_outlined,
              color: AppColors.primaryRed,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            searching ? 'No matching employees' : 'No payroll data',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Try a different name, role or ID'
                : 'Active employees for this month will appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutEmployee {
  const _PayoutEmployee({
    required this.employee,
    this.monthDays = 30,
    this.presentDays,
    this.absentDays,
    this.leaveDays,
    this.monthlySalary,
    this.kyc,
  });

  final Employee employee;
  final int monthDays;
  final int? presentDays;
  final int? absentDays;
  final int? leaveDays;
  final double? monthlySalary;
  final MyKycModalData? kyc;

  int get attendanceTotal => (presentDays ?? 0) + (absentDays ?? 0);

  double get presentRatio {
    if (attendanceTotal <= 0) return 0;
    return (presentDays ?? 0) / attendanceTotal;
  }

  /// Present days plus paid leave, the same default the salary sheet uses.
  double get payableDays =>
      ((presentDays ?? 0) + (leaveDays ?? 0)).toDouble();

  /// Register figures for this employee, or null when no package is on record.
  SalaryBreakdown? get breakdown {
    final package = monthlySalary;
    if (package == null || package <= 0) return null;
    return SalaryBreakdown.from(
      withStatutoryDefaults(
        SalaryInput(
          monthlyPackage: package,
          monthDays: monthDays,
          payableDays: payableDays,
        ),
      ),
    );
  }
}
