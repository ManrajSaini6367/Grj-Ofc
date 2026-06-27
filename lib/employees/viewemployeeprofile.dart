import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/employees/employee.dart';
import 'package:grjoffice_apps/models/getemployeemodal.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

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

  bool get _isActive => _profile?.isActiveStatus ?? widget.employee.status == EmployeeStatus.active;

  bool get _attendanceAllowed => _profile?.attendanceAllow ?? widget.employee.attendanceAllow;

  String get _name => _text(_profile?.name, fallback: widget.employee.name);

  String get _role => _text(_profile?.designation, fallback: widget.employee.role);

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
      body: Column(
        children: [
          _buildHeroHeader(hPad),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                  'Date Suspended',
                                  _text(_profile?.dateOfSuspended),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildSection(
                              title: 'Access & Status',
                              icon: Icons.verified_user_outlined,
                              children: [
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
        ],
      ),
    );
  }

  Widget _buildHeroHeader(double hPad) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B1D1D), Color(0xFF6B1515)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x338B1D1D), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 28),
          child: Column(
            children: [
              Row(
                children: [
                  _headerBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                  const Spacer(),
                  const AppLogo(size: 34),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                ),
                child: Center(
                  child: Text(
                    widget.employee.initials,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _isLoading ? widget.employee.name : _name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isLoading ? widget.employee.role : _role,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!_isLoading) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _heroChip('ID: $_employeeId'),
                    _heroChip(widget.employee.site),
                    _heroChip(_isActive ? 'ACTIVE' : 'INACTIVE'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
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
