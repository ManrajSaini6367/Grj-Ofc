import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/EmployeeListscreen/employee.dart';
import 'package:grjoffice_apps/models/getemployeemodal.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ViewEmployeeProfileScreen extends StatefulWidget {
  const ViewEmployeeProfileScreen({super.key, required this.employee});

  final Employee employee;

  @override
  State<ViewEmployeeProfileScreen> createState() => _ViewEmployeeProfileScreenState();
}

class _ViewEmployeeProfileScreenState extends State<ViewEmployeeProfileScreen> {
  bool _isLoading = true;
  EmployeeListItem? _profile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final employeeId = widget.employee.employeeId;
    if (employeeId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final response = await viewProfileOfEmployeeApi(context, employeeId);
    if (!mounted) return;

    setState(() {
      _profile = response?.data;
      _isLoading = false;
    });
  }

  String _text(String? value, {String fallback = '-'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateString(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return _formatDate(DateTime.tryParse(value.trim()));
  }

  bool get _isActive => _profile?.isActiveStatus ?? widget.employee.status == EmployeeStatus.active;

  bool get _attendanceAllowed => _profile?.attendanceAllow ?? widget.employee.attendanceAllow;

  String get _accessRolesLabel {
    final fromProfile = _profile?.accessRoles ?? const <String>[];
    final names = fromProfile.isNotEmpty ? fromProfile : widget.employee.accessRoles;
    if (names.isEmpty) return '-';
    return names.map(_titleCase).join(', ');
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String get _employeeId => _text(_profile?.username, fallback: widget.employee.id);

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
              title: 'Employee Profile',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: _loadProfile,
                      child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildProfileHeader(),
                              const SizedBox(height: 16),
                              _buildQuickStats(),
                              const SizedBox(height: 16),
                              _buildSection(
                                title: 'Contact',
                                icon: Icons.contact_mail_outlined,
                                children: [
                                  _infoTile(Icons.email_outlined, 'Email', _text(_profile?.email)),
                                  _infoTile(Icons.phone_outlined, 'Phone', _text(_profile?.mobile)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSection(
                                title: 'Employment',
                                icon: Icons.work_outline_rounded,
                                children: [
                                  _infoTile(Icons.badge_outlined, 'Employee ID', _employeeId),
                                  _infoTile(Icons.apartment_outlined, 'Site', widget.employee.site),
                                  _infoTile(Icons.calendar_today_outlined, 'Date of Join', _formatDate(_profile?.dateOfJoin)),
                                  _infoTile(
                                    Icons.event_busy_outlined,
                                    'Date of Suspended',
                                    _formatDateString(_profile?.dateOfSuspended),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSection(
                                title: 'Access & Status',
                                icon: Icons.verified_user_outlined,
                                children: [
                                  _infoTile(
                                    Icons.admin_panel_settings_outlined,
                                    'Access Roles',
                                    _accessRolesLabel,
                                  ),
                                  _infoTile(
                                    Icons.fingerprint_outlined,
                                    'Attendance',
                                    _attendanceAllowed ? 'Allowed' : 'Not Allowed',
                                    valueColor: _attendanceAllowed ? const Color(0xFF059669) : AppColors.textSecondary,
                                  ),
                                  _infoTile(
                                    Icons.circle,
                                    'Status',
                                    _isActive ? 'Active' : 'Inactive',
                                    valueColor: _isActive ? AppColors.primaryRed : AppColors.textSecondary,
                                    leadingIconSize: 10,
                                  ),
                                ],
                              ),
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

  Widget _buildProfileHeader() {
    final name = _text(
      _profile?.name ??
          '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}'.trim(),
      fallback: widget.employee.name,
    );
    final role = _text(
      _profile?.designation,
      fallback: widget.employee.role.isEmpty ? 'Employee' : widget.employee.role,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'E',
              style: GoogleFonts.poppins(
                color: AppColors.primaryRed,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.verified_outlined,
            label: 'Status',
            value: _isActive ? 'Active' : 'Inactive',
            color: AppColors.primaryRed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.how_to_reg_outlined,
            label: 'Attendance',
            value: _attendanceAllowed ? 'Yes' : 'No',
            color: const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.calendar_month_outlined,
            label: 'Joined',
            value: _formatDate(_profile?.dateOfJoin).length > 8
                ? _formatDate(_profile?.dateOfJoin).substring(0, 5)
                : _formatDate(_profile?.dateOfJoin),
            color: const Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderGray.withValues(alpha: 0.35)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    double leadingIconSize = 18,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.operationsCardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: leadingIconSize, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.headingBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
