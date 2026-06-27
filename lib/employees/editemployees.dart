import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/employees/employee.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

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

  static const _roles = [
    'Site Engineer',
    'Project Architect',
    'General Foreman',
    'Safety Compliance Officer',
    'Structural Specialist',
    'Director',
    'Store Manager',
    'Accountant',
  ];

  String? _role;
  DateTime? _dateOfJoin;
  DateTime? _dateSuspended;
  bool _attendanceAllowed = true;
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
    _role = e.role.isNotEmpty ? e.role : null;
    _dateOfJoin = e.dateOfJoin ?? DateTime.now();
    _attendanceAllowed = e.attendanceAllow;
    _isActive = e.status == EmployeeStatus.active;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
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
    if (_role == null) {
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

    final employeeId = widget.employee.employeeId;
    if (employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid employee id.')),
      );
      return;
    }

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
        designation: _role!,
        dateOfJoin: _formatApiDate(_dateOfJoin!),
        dateOfSuspended:
            _dateSuspended != null ? _formatApiDate(_dateSuspended!) : null,
        password: password.isNotEmpty ? password : null,
        passwordConfirmation: password.isNotEmpty ? password : null,
        attendanceAllow: _attendanceAllowed,
        status: _isActive ? 1 : 0,
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
            Container(
              color: AppColors.cardWhite,
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: AppColors.textDark,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                  const AppLogo(size: 36),
                  const SizedBox(width: 10),
                  Text(
                    'Edit Employee',
                    style: GoogleFonts.poppins(
                      color: AppColors.headingBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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
                            _label('First Name'),
                            TextFormField(
                              controller: _firstName,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              decoration: _decoration('First name', inputBorder),
                            ),
                            const SizedBox(height: 16),
                            _label('Last Name'),
                            TextFormField(
                              controller: _lastName,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              decoration: _decoration('Last name', inputBorder),
                            ),
                            const SizedBox(height: 16),
                            _label('Email'),
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
                            _label('Phone'),
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
                            _label('Role'),
                            DropdownButtonFormField<String>(
                              initialValue: _roles.contains(_role) ? _role : null,
                              items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                              onChanged: (v) => setState(() => _role = v),
                              decoration: _decoration('Select role', inputBorder),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            ),
                            const SizedBox(height: 16),
                            _label('Site'),
                            _readOnly(widget.employee.site),
                            const SizedBox(height: 16),
                            _label('Date of Join'),
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
                            _label('Attendance Allow'),
                            Row(
                              children: [
                                Expanded(child: _chip('Yes', _attendanceAllowed, () => setState(() => _attendanceAllowed = true))),
                                const SizedBox(width: 10),
                                Expanded(child: _chip('No', !_attendanceAllowed, () => setState(() => _attendanceAllowed = false))),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
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
}
