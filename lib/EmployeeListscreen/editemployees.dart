import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';
import 'package:grjoffice_apps/EmployeeListscreen/employee.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/models/user_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class EditEmployeeScreen extends StatefulWidget {
  const EditEmployeeScreen({super.key, required this.employee});

  final Employee employee;

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final TextEditingController _salary;
  late final TextEditingController _leave;

  bool _isLoadingRoles = true;
  int? _selectedRoleId;
  final Set<int> _selectedAccessRoleIds = {};
  List<_EditRole> _roles = const [];
  List<_EditRole> _accessRoles = const [];
  bool _isLoadingAccessRoles = true;
  bool _isLoadingSites = true;
  final Set<int> _selectedSiteIds = {};
  List<SiteModel> _sites = const [];
  DateTime? _dateOfJoin;
  DateTime? _dateSuspended;
  bool _attendanceAllowed = true;
  bool _sundayMarkedHoliday = true;
  bool _webLoginAllow = true;
  bool _appLoginAllow = true;
  bool _isActive = true;
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    final parts = e.name.trim().split(RegExp(r'\s+'));
    _firstName = TextEditingController(text: e.firstName ?? (parts.isNotEmpty ? parts.first : ''));
    _lastName = TextEditingController(text: e.lastName ?? (parts.length > 1 ? parts.sublist(1).join(' ') : ''));
    _email = TextEditingController(text: e.email ?? '');
    _phone = TextEditingController(text: e.mobile ?? '');
    _password = TextEditingController();
    _salary = TextEditingController(text: e.monthlySalary ?? '');
    _leave = TextEditingController(text: e.leaveAllocation?.toString() ?? '');
    _dateOfJoin = e.dateOfJoin ?? DateTime.now();
    _attendanceAllowed = e.attendanceAllow;
    _sundayMarkedHoliday = e.sundayMarkedHoliday;
    _webLoginAllow = e.webLoginAllow;
    _appLoginAllow = e.appLoginAllow;
    _isActive = e.status == EmployeeStatus.active;
    _selectedAccessRoleIds.addAll(e.accessRoleIds);
    _selectedSiteIds.addAll(e.siteIds);
    _loadAccessRoles();
    _loadSites();
  }

  Future<void> _loadAccessRoles() async {
    _applyProfileAccessRoles(cachedUser());
    final profile = await profileApi(context);
    if (!mounted) return;
    _applyProfileAccessRoles(profile ?? cachedUser());
  }

  void _applyProfileAccessRoles(UserModel? user) {
    final fromProfile = user?.assignableAccessRoles ?? const <UserAccessRole>[];
    final options = fromProfile
        .map((role) => _EditRole(id: role.id, name: role.name))
        .toList();
    final currentName = widget.employee.role.toLowerCase();
    setState(() {
      _roles = options;
      _accessRoles = options;
      _isLoadingRoles = false;
      _isLoadingAccessRoles = false;
      _selectedRoleId ??= options
            .where((role) => role.name.toLowerCase() == currentName)
            .firstOrNull
            ?.id;
      if (_selectedAccessRoleIds.isEmpty && widget.employee.accessRoles.isNotEmpty) {
        final names = widget.employee.accessRoles.map((n) => n.toLowerCase()).toSet();
        _selectedAccessRoleIds.addAll(
          options.where((role) => names.contains(role.name.toLowerCase())).map((role) => role.id),
        );
      }
    });
  }

  Future<void> _loadSites() async {
    final currentId = selectedSiteId();
    final data = await sitesApi(context, perPage: 100);
    if (!mounted) return;
    final sites = data ?? cachedSites() ?? const <SiteModel>[];
    setState(() {
      _sites = sites;
      if (_selectedSiteIds.isEmpty) {
        if (widget.employee.siteIds.isNotEmpty) {
          _selectedSiteIds.addAll(widget.employee.siteIds);
        } else if (currentId != null) {
          _selectedSiteIds.add(currentId);
        }
      }
      _isLoadingSites = false;
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _salary.dispose();
    _leave.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDate({required bool isJoin}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isJoin ? (_dateOfJoin ?? DateTime.now()) : (_dateSuspended ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryRed,
            onPrimary: AppColors.white,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isJoin) {
        _dateOfJoin = picked;
      } else {
        _dateSuspended = picked;
      }
    });
  }

  String _formatApiDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select role.')),
      );
      return;
    }
    if (_dateOfJoin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of join.')),
      );
      return;
    }
    if (_selectedSiteIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one site.')),
      );
      return;
    }

    final employeeId = widget.employee.employeeId;
    if (employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid employee id.')),
      );
      return;
    }

    final int roleId = _selectedRoleId!;
    final List<int> accessRoles = _selectedAccessRoleIds
        .where((id) => id != roleId)
        .toList();

    setState(() => _isSaving = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    try {
      final password = _password.text.trim();
      final success = await updateEmployeeApi(
        context,
        employeeId: employeeId,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        mobile: _phone.text.trim(),
        designation: _roles
            .where((role) => role.id == roleId)
            .firstOrNull
            ?.name ??
            widget.employee.role,
        dateOfJoin: _formatApiDate(_dateOfJoin!),
        dateOfSuspended:
            _dateSuspended != null ? _formatApiDate(_dateSuspended!) : null,
        password: password.isNotEmpty ? password : null,
        passwordConfirmation: password.isNotEmpty ? password : null,
        monthlySalary: _salary.text.trim(),
        leaveAllocation: _leave.text.trim(),
        attendanceAllow: _attendanceAllowed,
        sundayMarkedHoliday: _sundayMarkedHoliday,
        webLoginAllow: _webLoginAllow,
        appLoginAllow: _appLoginAllow,
        status: _isActive ? 'published' : 'unpublished',
        roleId: roleId,
        accessRoleIds: accessRoles,
        siteIds: _selectedSiteIds.toList(),
      );

      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Edit Employee',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Update Employee',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headingBlack,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Update employee details below.',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('Employee ID'),
                            _readOnly(widget.employee.id),
                            const SizedBox(height: 16),
                            _label('First Name', isRequired: true),
                            TextFormField(
                              controller: _firstName,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              decoration: _decoration('First name', inputBorder),
                            ),
                            const SizedBox(height: 16),
                            _label('Last Name', isRequired: true),
                            TextFormField(
                              controller: _lastName,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              decoration: _decoration('Last name', inputBorder),
                            ),
                            const SizedBox(height: 16),
                            _label('Email', isRequired: true),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                if (!v.contains('@')) return 'Invalid email';
                                return null;
                              },
                              decoration: _decoration('employee@company.com', inputBorder),
                            ),
                            const SizedBox(height: 16),
                            _label('Phone', isRequired: true),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              decoration: _decoration('+91 98765 43210', inputBorder),
                            ),
                            const SizedBox(height: 16),
                            _label('Password (optional)'),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              decoration: _decoration('Leave blank to keep same', inputBorder).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _label('Role', isRequired: true),
                            DropdownButtonFormField<int>(
                              key: ValueKey('edit-role-${_roles.length}'),
                              initialValue: _roles.any((r) => r.id == _selectedRoleId)
                                  ? _selectedRoleId
                                  : null,
                              items: _roles
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r.id,
                                      child: Text(r.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isLoadingRoles
                                  ? null
                                  : (v) => setState(() => _selectedRoleId = v),
                              decoration: _decoration(
                                _isLoadingRoles ? 'Loading roles...' : 'Select role',
                                inputBorder,
                              ),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            ),
                            const SizedBox(height: 16),
                            _label('Access Roles (Optional)'),
                            _buildAccessRolesChips(),
                            const SizedBox(height: 16),
                            _label('Sites', isRequired: true),
                            _buildSitesChips(),
                            const SizedBox(height: 16),
                            _label('Date of Join', isRequired: true),
                            InkWell(
                              onTap: () => _pickDate(isJoin: true),
                              child: InputDecorator(
                                decoration: _decoration(_formatDate(_dateOfJoin), inputBorder),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(_formatDate(_dateOfJoin))),
                                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _label('Date of Suspended (Optional)'),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _pickDate(isJoin: false),
                                    child: InputDecorator(
                                      decoration: _decoration(_formatDate(_dateSuspended), inputBorder),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(_formatDate(_dateSuspended))),
                                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (_dateSuspended != null)
                                  IconButton(
                                    onPressed: () => setState(() => _dateSuspended = null),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _label('Monthly Salary'),
                            TextFormField(
                              controller: _salary,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              ],
                              validator: (v) {
                                final t = (v ?? '').trim();
                                if (t.isEmpty) return null;
                                final n = double.tryParse(t);
                                if (n == null || n < 0) return 'Enter a valid salary';
                                return null;
                              },
                              decoration: _decoration('0.00', inputBorder),
                            ),
                            const SizedBox(height: 16),
                            _label('Leave Allocation'),
                            TextFormField(
                              controller: _leave,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                final t = (v ?? '').trim();
                                if (t.isEmpty) return null;
                                final n = int.tryParse(t);
                                if (n == null || n < 0 || n > 365) {
                                  return 'Enter leaves between 0 and 365';
                                }
                                return null;
                              },
                              decoration: _decoration('e.g. 12', inputBorder),
                            ),
                            const SizedBox(height: 16),
                            _label('Attendance Allow'),
                            Row(
                              children: [
                                Expanded(child: _chip('Yes', _attendanceAllowed, () => setState(() => _attendanceAllowed = true))),
                                const SizedBox(width: 10),
                                Expanded(child: _chip('No', !_attendanceAllowed, () => setState(() => _attendanceAllowed = false))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _label('Sunday Marked Holiday'),
                            Row(
                              children: [
                                Expanded(child: _chip('Yes', _sundayMarkedHoliday, () => setState(() => _sundayMarkedHoliday = true))),
                                const SizedBox(width: 10),
                                Expanded(child: _chip('No', !_sundayMarkedHoliday, () => setState(() => _sundayMarkedHoliday = false))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _label('Web Login Allow'),
                            Row(
                              children: [
                                Expanded(child: _chip('Yes', _webLoginAllow, () => setState(() => _webLoginAllow = true))),
                                const SizedBox(width: 10),
                                Expanded(child: _chip('No', !_webLoginAllow, () => setState(() => _webLoginAllow = false))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _label('App Login Allow'),
                            Row(
                              children: [
                                Expanded(child: _chip('Yes', _appLoginAllow, () => setState(() => _appLoginAllow = true))),
                                const SizedBox(width: 10),
                                Expanded(child: _chip('No', !_appLoginAllow, () => setState(() => _appLoginAllow = false))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _label('Status'),
                            Row(
                              children: [
                                Expanded(child: _chip('Active', _isActive, () => setState(() => _isActive = true))),
                                const SizedBox(width: 10),
                                Expanded(child: _chip('Inactive', !_isActive, () => setState(() => _isActive = false))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                )
                              : Text(
                                  'UPDATE EMPLOYEE',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.8)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('CANCEL', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, {bool isRequired = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: fieldLabelText(
          text,
          isRequired: isRequired,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark),
        ),
      );

  InputDecoration _decoration(String hint, OutlineInputBorder border) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 14),
        filled: true,
        fillColor: AppColors.operationsCardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5)),
        errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primaryRed)),
      );

  Widget _readOnly(String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.operationsCardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.6)),
        ),
        child: Text(value, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.headingBlack)),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryRed.withValues(alpha: 0.1) : AppColors.operationsCardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primaryRed : AppColors.borderGray.withValues(alpha: 0.6),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? AppColors.primaryRed : AppColors.textDark,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _buildAccessRolesChips() {
    final options = _accessRoles;
    if (_isLoadingAccessRoles) {
      return Text(
        'Loading roles...',
        style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    if (options.isEmpty) {
      return Text(
        'No extra roles available.',
        style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((role) {
        final selected = _selectedAccessRoleIds.contains(role.id);
        return FilterChip(
          label: Text(
            role.name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primaryRed : AppColors.textDark,
            ),
          ),
          selected: selected,
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedAccessRoleIds.add(role.id);
              } else {
                _selectedAccessRoleIds.remove(role.id);
              }
            });
          },
          selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
          checkmarkColor: AppColors.primaryRed,
          backgroundColor: AppColors.cardWhite,
          side: BorderSide(
            color: selected
                ? AppColors.primaryRed.withValues(alpha: 0.4)
                : AppColors.borderGray.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }

  Widget _buildSitesChips() {
    if (_isLoadingSites) {
      return Text(
        'Loading sites...',
        style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    if (_sites.isEmpty) {
      return Text(
        'No sites available.',
        style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _sites.map((site) {
        final selected = _selectedSiteIds.contains(site.id);
        return FilterChip(
          label: Text(
            site.name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primaryRed : AppColors.textDark,
            ),
          ),
          selected: selected,
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedSiteIds.add(site.id);
              } else {
                _selectedSiteIds.remove(site.id);
              }
            });
          },
          selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
          checkmarkColor: AppColors.primaryRed,
          backgroundColor: AppColors.cardWhite,
          side: BorderSide(
            color: selected
                ? AppColors.primaryRed.withValues(alpha: 0.4)
                : AppColors.borderGray.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }
}

class _EditRole {
  const _EditRole({required this.id, required this.name});

  final int id;
  final String name;
}
