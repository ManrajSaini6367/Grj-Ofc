import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/EmployeeListscreen/employee.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_requests_screen.dart';
import 'package:grjoffice_apps/kycscreens/employee_kyc_store.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

/// HR Employee KYC = company configuration (salary, role, site, allowances).
/// Not document verification.
class EmployeeKycScreen extends StatefulWidget {
  const EmployeeKycScreen({
    super.key,
    this.employeeName,
    this.employeeId,
  });

  final String? employeeName;
  final String? employeeId;

  @override
  State<EmployeeKycScreen> createState() => _EmployeeKycScreenState();
}

class _EmployeeKycScreenState extends State<EmployeeKycScreen> {
  static const _roles = [
    'Site Engineer',
    'Project Manager',
    'Supervisor',
    'Accountant',
    'HR Executive',
    'Store Keeper',
    'Safety Officer',
    'Foreman',
  ];

  static const _employmentTypes = ['Full-Time', 'Part-Time', 'Contract'];

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _store = EmployeeKycStore.instance;

  int _stepIndex = 0;
  bool _saving = false;
  bool _saved = false;
  bool _loadingEmployees = true;

  List<Employee> _employees = const [];
  List<String> _sites = const [];

  Employee? _selectedEmployee;
  String? _role;
  String? _assignedSite;
  String? _employmentType;

  final _salaryCtrl = TextEditingController();
  final _leaveCtrl = TextEditingController();
  bool _foodAllowance = false;
  bool _stayAllowance = false;
  bool _sundayOff = false;
  DateTime? _joiningDate;

  bool get _isLastStep => _stepIndex == 1;
  double get _progress => (_stepIndex + 1) / 2;

  String get _employeeName =>
      _selectedEmployee?.name ?? widget.employeeName ?? '—';
  String get _employeeId =>
      _selectedEmployee?.id ?? widget.employeeId ?? '—';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final sites = cachedSites() ?? const <SiteModel>[];
    var siteNames = sites
        .map((e) => e.name.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (siteNames.isEmpty) {
      siteNames = [
        'Head Office',
        'Skyline Main',
        'Skyline B-2',
        'Skyline B-4',
      ];
    }

    List<Employee> employees = List<Employee>.from(kMockEmployees);
    try {
      final response = await getEmployeesApi(
        context,
        fetchAllPages: true,
        perPage: 50,
      );
      final items = response?.data?.items;
      if (items != null && items.isNotEmpty) {
        employees = items.map((item) {
          final displayName = (item.name?.trim().isNotEmpty == true)
              ? item.name!.trim()
              : '${item.firstName ?? ''} ${item.lastName ?? ''}'.trim();
          return Employee(
            id: item.username?.toString().isNotEmpty == true
                ? item.username!
                : (item.id?.toString() ?? 'EMP'),
            name: displayName.isNotEmpty ? displayName : 'Employee',
            role: item.designation ?? '',
            site: '',
            employeeId: item.id,
            dateOfJoin: item.dateOfJoin,
          );
        }).toList();
      }
    } catch (_) {
      // Keep mock list for offline / UI demo.
    }

    if (!mounted) return;

    Employee? preselected;
    final forcedId = widget.employeeId;
    final forcedName = widget.employeeName;
    if (forcedId != null || forcedName != null) {
      for (final e in employees) {
        if ((forcedId != null && e.id == forcedId) ||
            (forcedName != null && e.name == forcedName)) {
          preselected = e;
          break;
        }
      }
      preselected ??= Employee(
        id: forcedId ?? 'EMP',
        name: forcedName ?? 'Employee',
        role: '',
        site: '',
      );
    }

    setState(() {
      _sites = siteNames;
      _employees = employees;
      _selectedEmployee =
          preselected ?? (employees.isNotEmpty ? employees.first : null);
      _role = _roles.first;
      _assignedSite = _sites.first;
      _employmentType = _employmentTypes.first;
      _joiningDate = _selectedEmployee?.dateOfJoin ?? DateTime.now();
      _loadingEmployees = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _salaryCtrl.dispose();
    _leaveCtrl.dispose();
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

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
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
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.borderGray.withValues(alpha: 0.35),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }

  Future<void> _pickJoiningDate() async {
    final now = DateTime.now();
    final initial = _joiningDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 1),
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

  /// Validates Step 1 using the Form (only while Step 1 is visible).
  bool _validateStep1Form() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return false;
    return _hasRequiredValues(showSnack: true);
  }

  /// Value-based check used on Review / Save (avoids off-screen Form issues).
  bool _hasRequiredValues({bool showSnack = false}) {
    if (_selectedEmployee == null) {
      if (showSnack) _snack('Please select an employee.');
      return false;
    }
    if (_role == null || _assignedSite == null || _employmentType == null) {
      if (showSnack) _snack('Please complete all required fields.');
      return false;
    }
    if (_salaryCtrl.text.trim().isEmpty || _leaveCtrl.text.trim().isEmpty) {
      if (showSnack) _snack('Please enter salary and leave allocation.');
      return false;
    }
    if (_joiningDate == null) {
      if (showSnack) _snack('Please select Joining Date.');
      return false;
    }
    return true;
  }

  Future<void> _goNext() async {
    FocusScope.of(context).unfocus();
    if (_stepIndex == 0) {
      if (!_validateStep1Form()) return;
      setState(() {
        _stepIndex = 1;
        _saved = false;
      });
      await _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _save();
  }

  Future<void> _goPrevious() async {
    FocusScope.of(context).unfocus();
    if (_stepIndex <= 0) return;
    setState(() => _stepIndex = 0);
    await _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _save() async {
    // Never jump back to Step 1 after a successful save attempt from Review.
    // Use value checks only (Form may be off-screen on Step 2).
    if (!_hasRequiredValues(showSnack: true)) return;

    setState(() => _saving = true);

    final now = DateTime.now();
    await _store.save(
      EmployeeKycConfig(
        employeeName: _employeeName,
        employeeId: _employeeId,
        role: _role ?? '',
        assignedSite: _assignedSite ?? '',
        monthlySalary: _salaryCtrl.text.trim(),
        leaveAllocation: _leaveCtrl.text.trim(),
        foodAllowance: _foodAllowance,
        stayAllowance: _stayAllowance,
        sundayOff: _sundayOff,
        employmentType: _employmentType ?? '',
        joiningDate: _joiningDate!,
        configuredAt: now,
        status: 'Configured',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() {
      _saving = false;
      _saved = true;
      _stepIndex = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Employee configuration has been saved successfully.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF059669),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _goToRequests() {
    pushInShell(context, const EmployeeKycRequestsScreen());
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

  void _markDirty() {
    if (_saved) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    final contentMax = width >= 900 ? 680.0 : double.infinity;
    final stepTitle =
        _stepIndex == 0 ? 'Employee Configuration' : 'Review & Submit';

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
              title: stepTitle,
              progress: _progress,
            ),
            Expanded(
              child: _loadingEmployees
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMax),
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (i) =>
                              setState(() => _stepIndex = i),
                          children: [
                            _StepCard(
                              hPad: hPad,
                              child: Form(
                                key: _formKey,
                                child: _ConfigStep(
                                  employees: _employees,
                                  selectedEmployee: _selectedEmployee,
                                  roles: _roles,
                                  sites: _sites,
                                  employmentTypes: _employmentTypes,
                                  role: _role,
                                  assignedSite: _assignedSite,
                                  employmentType: _employmentType,
                                  salaryCtrl: _salaryCtrl,
                                  leaveCtrl: _leaveCtrl,
                                  foodAllowance: _foodAllowance,
                                  stayAllowance: _stayAllowance,
                                  sundayOff: _sundayOff,
                                  joiningDate: _joiningDate,
                                  decoration: _decoration,
                                  lockEmployee: widget.employeeId != null ||
                                      widget.employeeName != null,
                                  onEmployeeChanged: (e) {
                                    setState(() {
                                      _selectedEmployee = e;
                                      _saved = false;
                                      if (e?.role.isNotEmpty == true &&
                                          _roles.contains(e!.role)) {
                                        _role = e.role;
                                      }
                                      if (e?.dateOfJoin != null) {
                                        _joiningDate = e!.dateOfJoin;
                                      }
                                    });
                                  },
                                  onRoleChanged: (v) {
                                    setState(() {
                                      _role = v;
                                      _saved = false;
                                    });
                                  },
                                  onSiteChanged: (v) {
                                    setState(() {
                                      _assignedSite = v;
                                      _saved = false;
                                    });
                                  },
                                  onEmploymentChanged: (v) {
                                    setState(() {
                                      _employmentType = v;
                                      _saved = false;
                                    });
                                  },
                                  onFoodChanged: (v) {
                                    setState(() {
                                      _foodAllowance = v;
                                      _saved = false;
                                    });
                                  },
                                  onStayChanged: (v) {
                                    setState(() {
                                      _stayAllowance = v;
                                      _saved = false;
                                    });
                                  },
                                  onSundayChanged: (v) {
                                    setState(() {
                                      _sundayOff = v;
                                      _saved = false;
                                    });
                                  },
                                  onPickJoiningDate: _pickJoiningDate,
                                  onFieldChanged: _markDirty,
                                ),
                              ),
                            ),
                            _StepCard(
                              hPad: hPad,
                              child: _ReviewStep(
                                saved: _saved,
                                employeeName: _employeeName,
                                employeeId: _employeeId,
                                role: _role ?? '—',
                                site: _assignedSite ?? '—',
                                salary: _salaryCtrl.text.trim().isEmpty
                                    ? '—'
                                    : _salaryCtrl.text.trim(),
                                leave: _leaveCtrl.text.trim().isEmpty
                                    ? '—'
                                    : _leaveCtrl.text.trim(),
                                foodAllowance: _foodAllowance,
                                stayAllowance: _stayAllowance,
                                sundayOff: _sundayOff,
                                employmentType: _employmentType ?? '—',
                                joiningDate: _joiningDate,
                              ),
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
              isLast: _isLastStep,
              saving: _saving,
              saved: _saved,
              onPrevious: _goPrevious,
              onNext: _goNext,
              onViewRequests: _goToRequests,
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
  });

  final double hPad;
  final int stepIndex;
  final String title;
  final double progress;

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
                  'Step ${stepIndex + 1} of 2 — $title',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Single progress indicator only.
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor:
                      AppColors.borderGray.withValues(alpha: 0.3),
                  color: AppColors.primaryRed,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.hPad, required this.child});

  final double hPad;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: EdgeInsets.all(hPad < 16 ? 16 : 20),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.borderGray.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.hPad,
    required this.bottomInset,
    required this.stepIndex,
    required this.isLast,
    required this.saving,
    required this.saved,
    required this.onPrevious,
    required this.onNext,
    required this.onViewRequests,
  });

  final double hPad;
  final double bottomInset;
  final int stepIndex;
  final bool isLast;
  final bool saving;
  final bool saved;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onViewRequests;

  @override
  Widget build(BuildContext context) {
    // After successful save: hide Previous/Save and show success CTA only.
    if (saved && isLast) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12 + bottomInset),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onViewRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'View Employee KYC Requests',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (stepIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onPrevious,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: BorderSide(
                    color: AppColors.primaryRed.withValues(alpha: 0.65),
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
            child: ElevatedButton(
              onPressed: saving ? null : onNext,
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
                      isLast ? 'Save Configuration' : 'Next',
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

class _ConfigStep extends StatelessWidget {
  const _ConfigStep({
    required this.employees,
    required this.selectedEmployee,
    required this.roles,
    required this.sites,
    required this.employmentTypes,
    required this.role,
    required this.assignedSite,
    required this.employmentType,
    required this.salaryCtrl,
    required this.leaveCtrl,
    required this.foodAllowance,
    required this.stayAllowance,
    required this.sundayOff,
    required this.joiningDate,
    required this.decoration,
    required this.lockEmployee,
    required this.onEmployeeChanged,
    required this.onRoleChanged,
    required this.onSiteChanged,
    required this.onEmploymentChanged,
    required this.onFoodChanged,
    required this.onStayChanged,
    required this.onSundayChanged,
    required this.onPickJoiningDate,
    required this.onFieldChanged,
  });

  final List<Employee> employees;
  final Employee? selectedEmployee;
  final List<String> roles;
  final List<String> sites;
  final List<String> employmentTypes;
  final String? role;
  final String? assignedSite;
  final String? employmentType;
  final TextEditingController salaryCtrl;
  final TextEditingController leaveCtrl;
  final bool foodAllowance;
  final bool stayAllowance;
  final bool sundayOff;
  final DateTime? joiningDate;
  final InputDecoration Function(String) decoration;
  final bool lockEmployee;
  final ValueChanged<Employee?> onEmployeeChanged;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<String?> onSiteChanged;
  final ValueChanged<String?> onEmploymentChanged;
  final ValueChanged<bool> onFoodChanged;
  final ValueChanged<bool> onStayChanged;
  final ValueChanged<bool> onSundayChanged;
  final VoidCallback onPickJoiningDate;
  final VoidCallback onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 420;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign company settings',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure role, site, salary, leave, allowances and Sunday Off.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        if (!lockEmployee) ...[
          DropdownButtonFormField<Employee>(
            value: selectedEmployee,
            isExpanded: true,
            items: employees
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      '${e.name} (${e.id})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onEmployeeChanged,
            decoration: decoration('Select Employee'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 14),
        ],
        TextFormField(
          initialValue: selectedEmployee?.name ?? '—',
          key: ValueKey('name_${selectedEmployee?.id}'),
          enabled: false,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: decoration('Employee Name (Read Only)'),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: selectedEmployee?.id ?? '—',
          key: ValueKey('id_${selectedEmployee?.id}'),
          enabled: false,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: decoration('Employee ID (Read Only)'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: role,
          isExpanded: true,
          items: roles
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onRoleChanged,
          decoration: decoration('Role'),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.headingBlack,
          ),
          validator: (v) => v == null ? 'Select role' : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: assignedSite,
          isExpanded: true,
          items: sites
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onSiteChanged,
          decoration: decoration('Assigned Site'),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.headingBlack,
          ),
          validator: (v) => v == null ? 'Select site' : null,
        ),
        const SizedBox(height: 14),
        if (narrow) ...[
          TextFormField(
            controller: salaryCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => onFieldChanged(),
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: decoration('Monthly Salary'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: leaveCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onFieldChanged(),
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: decoration('Leave Allocation'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: salaryCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => onFieldChanged(),
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: decoration('Monthly Salary'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: leaveCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onFieldChanged(),
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: decoration('Leave Allocation'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Text(
          'Benefits & Off Days',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 10),
        _ToggleRow(
          label: 'Food Allowance',
          value: foodAllowance,
          onChanged: onFoodChanged,
        ),
        const SizedBox(height: 10),
        _ToggleRow(
          label: 'Stay Allowance',
          value: stayAllowance,
          onChanged: onStayChanged,
        ),
        const SizedBox(height: 10),
        _ToggleRow(
          label: 'Sunday Off',
          value: sundayOff,
          onChanged: onSundayChanged,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: employmentType,
          isExpanded: true,
          items: employmentTypes
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onEmploymentChanged,
          decoration: decoration('Employment Type'),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.headingBlack,
          ),
          validator: (v) => v == null ? 'Select type' : null,
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: onPickJoiningDate,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: decoration('Joining Date'),
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
                    joiningDate == null
                        ? 'Select date'
                        : DateFormat('dd MMM yyyy').format(joiningDate!),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: joiningDate == null
                          ? AppColors.inputHint
                          : AppColors.headingBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value
          ? AppColors.primaryRed.withValues(alpha: 0.06)
          : const Color(0xFFF8F9FB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value
                  ? AppColors.primaryRed.withValues(alpha: 0.35)
                  : AppColors.borderGray.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingBlack,
                  ),
                ),
              ),
              Text(
                value ? 'Yes' : 'No',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: value
                      ? AppColors.primaryRed
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Switch.adaptive(
                value: value,
                activeColor: AppColors.primaryRed,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.saved,
    required this.employeeName,
    required this.employeeId,
    required this.role,
    required this.site,
    required this.salary,
    required this.leave,
    required this.foodAllowance,
    required this.stayAllowance,
    required this.sundayOff,
    required this.employmentType,
    required this.joiningDate,
  });

  final bool saved;
  final String employeeName;
  final String employeeId;
  final String role;
  final String site;
  final String salary;
  final String leave;
  final bool foodAllowance;
  final bool stayAllowance;
  final bool sundayOff;
  final String employmentType;
  final DateTime? joiningDate;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final rows = [
      ('Employee Name', employeeName),
      ('Employee ID', employeeId),
      ('Assigned Role', role),
      ('Assigned Site', site),
      ('Monthly Salary', salary),
      ('Leave Allocation', leave),
      ('Food Allowance', foodAllowance ? 'Yes' : 'No'),
      ('Stay Allowance', stayAllowance ? 'Yes' : 'No'),
      ('Sunday Off', sundayOff ? 'Yes' : 'No'),
      ('Employment Type', employmentType),
      (
        'Joining Date',
        joiningDate == null ? '—' : dateFmt.format(joiningDate!),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review configuration',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Confirm the details before saving.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        if (saved) ...[
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF059669).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Employee configuration has been saved successfully.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF065F46),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderGray.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width < 360
                            ? 110
                            : 130,
                        child: Text(
                          row.$1,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.$2,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.headingBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
