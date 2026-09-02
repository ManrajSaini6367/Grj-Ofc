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
import 'package:grjoffice_apps/models/showemployeeskycmodal.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
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
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final rows = await Future.wait(
      activeEmployees.map((employee) => _loadEmployeePayout(employee, month)),
    );
    if (!mounted) return;
    setState(() {
      _employees = rows;
      _loading = false;
    });
  }

  Future<_PayoutEmployee> _loadEmployeePayout(
    Employee employee,
    String month,
  ) async {
    final employeeId = employee.employeeId;
    if (employeeId == null) return _PayoutEmployee(employee: employee);

    final responses = await Future.wait([
      getAttendanceCalendarApi(
        context,
        month: month,
        userId: employeeId,
        showErrors: false,
      ),
      showEmployeeKycApi(context, employeeId: employeeId, showErrors: false),
    ]);
    final calendar = responses[0] as Getcalendermodal?;
    final kyc = (responses[1] as Showemployyeskycmodal?)?.data;
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

    return _PayoutEmployee(
      employee: employee,
      presentDays: presentDays,
      absentDays: absentDays,
      monthlySalary: _salaryFromKyc(kyc),
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
    );
  }

  double? _salaryFromKyc(MyKycModalData? kyc) {
    final value = kyc?.monthlySalary?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '';
    return double.tryParse(value);
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

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMMM yyyy').format(DateTime.now());
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
            AppTopBar.shell(title: 'Payout', scaffoldKey: _scaffoldKey),
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
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        children: [
                          _buildHeader(month),
                          const SizedBox(height: 18),
                          _buildSearch(),
                          const SizedBox(height: 16),
                          if (_filteredEmployees.isEmpty)
                            _buildEmptyState()
                          else
                            ..._filteredEmployees.map(_buildEmployeeCard),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String month) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly payout overview',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  month,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search employee by name or ID',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: .6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: .6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(_PayoutEmployee entry) {
    final employee = entry.employee;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: .5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primaryRed.withValues(alpha: .1),
                child: Text(
                  employee.initials,
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w700,
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
                      style: GoogleFonts.poppins(
                        color: AppColors.headingBlack,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${employee.role} • ${employee.id}',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 12,
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
              Expanded(
                child: _stat(
                  label: 'Present',
                  value: entry.presentDays?.toString() ?? '—',
                  color: const Color(0xFF15803D),
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  label: 'Absent',
                  value: entry.absentDays?.toString() ?? '—',
                  color: AppColors.primaryRed,
                  icon: Icons.cancel_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  label: 'Salary',
                  value: _money(entry.monthlySalary),
                  color: const Color(0xFF1D4ED8),
                  icon: Icons.currency_rupee_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 46,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            'No employees found',
            style: GoogleFonts.poppins(color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}

class _PayoutEmployee {
  const _PayoutEmployee({
    required this.employee,
    this.presentDays,
    this.absentDays,
    this.monthlySalary,
  });

  final Employee employee;
  final int? presentDays;
  final int? absentDays;
  final double? monthlySalary;
}
