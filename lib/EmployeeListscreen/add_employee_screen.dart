import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/EmployeeListscreen/employee.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/models/user_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key, this.employee});

  final Employee? employee;

  bool get isEditing => employee != null;

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _salaryController = TextEditingController();
  final _leaveController = TextEditingController();

  bool _obscurePassword = true;
  bool _attendanceAllowed = true;
  bool _isSaving = false;
  bool _isLoadingRoles = true;
  int? _selectedRoleId;
  final Set<int> _selectedAccessRoleIds = {};
  List<_EmployeeRole> _roles = const [];
  List<_EmployeeRole> _accessRoles = const [];
  bool _isLoadingAccessRoles = true;
  bool _isLoadingSites = true;
  final Set<int> _selectedSiteIds = {};
  List<SiteModel> _sites = const [];
  DateTime? _dateOfJoin;
  DateTime? _dateSuspended;

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    if (employee != null) {
      final parts = employee.name.trim().split(RegExp(r'\s+'));
      _firstNameController.text = parts.isNotEmpty ? parts.first : '';
      _lastNameController.text = parts.length > 1
          ? parts.sublist(1).join(' ')
          : '';
      _dateOfJoin = DateTime.now().subtract(const Duration(days: 365));
      _salaryController.text = employee.monthlySalary ?? '';
      _leaveController.text = employee.leaveAllocation?.toString() ?? '';
    }
    _loadAccessRoles();
    _loadSites();
  }

  Set<int> _existingAccessRoleIds(List<_EmployeeRole> roles) {
    final employee = widget.employee;
    if (employee == null) return {};
    if (employee.accessRoleIds.isNotEmpty) {
      return employee.accessRoleIds.toSet();
    }
    final names = employee.accessRoles.map((n) => n.toLowerCase()).toSet();
    if (names.isEmpty) return {};
    return roles
        .where((role) => names.contains(role.name.toLowerCase()))
        .map((role) => role.id)
        .toSet();
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
        .map((role) => _EmployeeRole(id: role.id, name: role.name))
        .toList();
    final employeeRole = widget.employee?.role.toLowerCase();
    setState(() {
      _roles = options;
      _accessRoles = options;
      _isLoadingRoles = false;
      _isLoadingAccessRoles = false;
      if (_selectedRoleId == null && employeeRole != null) {
        _selectedRoleId = options
            .where((role) => role.name.toLowerCase() == employeeRole)
            .firstOrNull
            ?.id;
      }
      if (widget.employee != null && _selectedAccessRoleIds.isEmpty) {
        _selectedAccessRoleIds.addAll(_existingAccessRoleIds(options));
      }
    });
  }

  Future<void> _loadSites() async {
    final currentId = selectedSiteId();
    final existing = widget.employee?.siteIds ?? const <int>[];
    final data = await sitesApi(context, perPage: 100);
    if (!mounted) return;
    final sites = data ?? cachedSites() ?? const <SiteModel>[];
    setState(() {
      _sites = sites;
      _selectedSiteIds
        ..clear()
        ..addAll(existing);
      if (_selectedSiteIds.isEmpty && currentId != null) {
        _selectedSiteIds.add(currentId);
      }
      _isLoadingSites = false;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _salaryController.dispose();
    _leaveController.dispose();
    super.dispose();
  }

  String get _photoInitials {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) return first[0].toUpperCase();
    return '?';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _pickDate({required bool isJoinDate}) async {
    final initial = isJoinDate
        ? (_dateOfJoin ?? DateTime.now())
        : (_dateSuspended ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: AppColors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isJoinDate) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select role.')));
      return;
    }
    if (_dateOfJoin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of join.')),
      );
      return;
    }

    if (widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee updated successfully.')),
      );
      Navigator.of(context).pop();
      return;
    }

    if (_selectedSiteIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one site.')),
      );
      return;
    }

    final siteIds = _selectedSiteIds.toList();
    final currentId = selectedSiteId();
    final siteId = (currentId != null && siteIds.contains(currentId))
        ? currentId
        : siteIds.first;

    final int roleId = _selectedRoleId!;
    final List<int> accessRoles = _selectedAccessRoleIds
        .where((id) => id != roleId)
        .toList();

    setState(() => _isSaving = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    try {
      final success = await createEmployeeApi(
        context,
        siteId: siteId,
        roleId: roleId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _phoneController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _passwordController.text,
        designation: _roles
            .where((role) => role.id == roleId)
            .firstOrNull
            ?.name ??
            '',
        dateOfJoin: _formatApiDate(_dateOfJoin!),
        dateOfSuspended: _dateSuspended != null
            ? _formatApiDate(_dateSuspended!)
            : null,
        monthlySalary: _salaryController.text.trim(),
        leaveAllocation: _leaveController.text.trim(),
        attendanceAllow: _attendanceAllowed,
        status: 'published',
        accessRoleIds: accessRoles,
        siteIds: siteIds,
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
    final hPad = _hPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: widget.isEditing ? 'Edit Employee' : 'Add Employee',
              onBack: () => Navigator.of(context).pop(),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildFormCard(),
                          const SizedBox(height: 24),
                          _buildSaveButton(),
                          const SizedBox(height: 12),
                          _buildCancelButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditing ? 'Update Employee' : 'New Employee',
          style: GoogleFonts.poppins(
            color: AppColors.headingBlack,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fill in the employee details below.',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhotoField(),
          const SizedBox(height: 20),
          _buildNameRow(),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email',
            controller: _emailController,
            hint: 'employee@company.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone',
            controller: _phoneController,
            hint: '+91 98765 43210',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Role',
            value: _selectedRoleId,
            items: _roles,
            onChanged: (value) => setState(() => _selectedRoleId = value),
          ),
          const SizedBox(height: 16),
          _buildAccessRolesField(),
          const SizedBox(height: 16),
          _buildSitesField(),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'Date of Join',
            value: _dateOfJoin,
            onTap: () => _pickDate(isJoinDate: true),
          ),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'Date of Suspended',
            value: _dateSuspended,
            onTap: () => _pickDate(isJoinDate: false),
            optional: true,
            onClear: _dateSuspended == null
                ? null
                : () => setState(() => _dateSuspended = null),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Monthly Salary',
            controller: _salaryController,
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: (value) {
              final t = (value ?? '').trim();
              if (t.isEmpty) return null;
              final n = double.tryParse(t);
              if (n == null || n < 0) return 'Enter a valid salary';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Leave Allocation',
            controller: _leaveController,
            hint: 'e.g. 12',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              final t = (value ?? '').trim();
              if (t.isEmpty) return null;
              final n = int.tryParse(t);
              if (n == null || n < 0 || n > 365) {
                return 'Enter leaves between 0 and 365';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildAttendanceField(),
        ],
      ),
    );
  }

  Widget _buildPhotoField() {
    return Column(
      children: [
        Text(
          'Photo',
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo upload will be available soon.'),
              ),
            );
          },
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryRed, width: 1.5),
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Text(
                    _photoInitials,
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryRed,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardWhite, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap to upload photo',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNameRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 420;
        final firstName = _buildTextField(
          label: 'First Name',
          controller: _firstNameController,
          hint: 'First name',
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'First name is required';
            }
            return null;
          },
        );
        final lastName = _buildTextField(
          label: 'Last Name',
          controller: _lastNameController,
          hint: 'Last name',
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Last name is required';
            }
            return null;
          },
        );

        if (stacked) {
          return Column(
            children: [firstName, const SizedBox(height: 16), lastName],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: firstName),
            const SizedBox(width: 12),
            Expanded(child: lastName),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            color: AppColors.headingBlack,
            fontSize: 14,
          ),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (value) {
            if (widget.isEditing && (value == null || value.isEmpty)) {
              return null;
            }
            if (value == null || value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
          style: GoogleFonts.poppins(
            color: AppColors.headingBlack,
            fontSize: 14,
          ),
          decoration: _inputDecoration('Min. 8 characters').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required int? value,
    required List<_EmployeeRole> items,
    required ValueChanged<int?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: ValueKey('add-role-${_roles.length}'),
          initialValue: items.any((item) => item.id == value) ? value : null,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(
                    item.name,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: _inputDecoration(
            _isLoadingRoles
                ? 'Loading roles...'
                : items.isEmpty
                    ? 'No roles available.'
                    : 'Select $label',
          ),
          style: GoogleFonts.poppins(
            color: AppColors.headingBlack,
            fontSize: 14,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          dropdownColor: AppColors.cardWhite,
        ),
      ],
    );
  }

  Widget _buildAccessRolesField() {
    final options = _accessRoles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Access Roles',
              style: GoogleFonts.poppins(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(Optional)',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingAccessRoles)
          Text(
            'Loading roles...',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          )
        else if (options.isEmpty)
          Text(
            'No extra roles available.',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          )
        else
          Wrap(
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSitesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sites',
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingSites)
          Text(
            'Loading sites...',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          )
        else if (_sites.isEmpty)
          Text(
            'No sites available.',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          )
        else
          Wrap(
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool optional = false,
    VoidCallback? onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Text(
                '(Optional)',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: _inputDecoration(_formatDate(value)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(value),
                          style: GoogleFonts.poppins(
                            color: value == null
                                ? AppColors.inputHint
                                : AppColors.headingBlack,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textSecondary,
                tooltip: 'Clear date',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Allow',
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _attendanceChip('Yes', true),
            const SizedBox(width: 10),
            _attendanceChip('No', false),
          ],
        ),
      ],
    );
  }

  Widget _attendanceChip(String label, bool value) {
    final selected = _attendanceAllowed == value;
    return Expanded(
      child: Material(
        color: selected
            ? AppColors.primaryRed.withValues(alpha: 0.1)
            : AppColors.operationsCardBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _attendanceAllowed = value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? AppColors.primaryRed
                    : AppColors.borderGray.withValues(alpha: 0.6),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: selected ? AppColors.primaryRed : AppColors.textDark,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 14),
      filled: true,
      fillColor: AppColors.operationsCardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.borderGray.withValues(alpha: 0.6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(
                widget.isEditing ? 'UPDATE EMPLOYEE' : 'SAVE EMPLOYEE',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'CANCEL',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _EmployeeRole {
  const _EmployeeRole({required this.id, required this.name});

  final int id;
  final String name;
}
