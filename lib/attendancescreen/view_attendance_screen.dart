import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/attendance_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key, required this.attendance});

  final Attendance attendance;

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  bool _isLoading = true;
  Attendance? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAttendance());
  }

  Future<void> _loadAttendance() async {
    final attendanceId = int.tryParse(widget.attendance.id);
    if (attendanceId == null) {
      if (!mounted) return;
      setState(() {
        _detail = widget.attendance;
        _isLoading = false;
      });
      return;
    }

    final attendance = await getAttendanceApi(context, attendanceId);
    if (!mounted) return;
    setState(() {
      _detail = attendance ?? widget.attendance;
      _isLoading = false;
    });
  }

  Attendance get _attendance => _detail ?? widget.attendance;

  String _text(String? value, {String fallback = '—'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  String _formatTime(DateTime? time, {String? label}) {
    if (label != null && label.trim().isNotEmpty) {
      try {
        final parts = label.trim().split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final period = hour >= 12 ? 'PM' : 'AM';
          final h12 = hour % 12 == 0 ? 12 : hour % 12;
          return '${h12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
        }
      } catch (_) {}
      return label;
    }
    if (time == null) return '—';
    return DateFormat('hh:mm a').format(time);
  }

  String _statusLabel(AttendanceStatus status) => switch (status) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.leave => 'On Leave',
      };

  Color _statusColor(AttendanceStatus status) => switch (status) {
        AttendanceStatus.present => const Color(0xFF10B981),
        AttendanceStatus.absent => const Color(0xFFEF4444),
        AttendanceStatus.leave => const Color(0xFFF59E0B),
      };

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final attendance = _attendance;
    final statusColor = _statusColor(attendance.status);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Attendance Details',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () async {
                        setState(() => _isLoading = true);
                        await _loadAttendance();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(attendance, statusColor),
                                const SizedBox(height: 14),
                                _buildSection(
                                  title: 'Employee',
                                  icon: Icons.person_outline,
                                  children: [
                                    _infoTile(Icons.badge_outlined, 'Name', attendance.employeeName),
                                    _infoTile(Icons.tag_rounded, 'Attendance ID', '#${attendance.id}'),
                                    _infoTile(
                                      Icons.person_pin_outlined,
                                      'User ID',
                                      attendance.userId?.toString() ?? '—',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildSection(
                                  title: 'Attendance',
                                  icon: Icons.fact_check_outlined,
                                  children: [
                                    _infoTile(
                                      Icons.calendar_today_outlined,
                                      'Date',
                                      _formatDate(attendance.date),
                                    ),
                                    _infoTile(
                                      Icons.verified_outlined,
                                      'Status',
                                      _statusLabel(attendance.status),
                                    ),
                                    _infoTile(
                                      Icons.code_rounded,
                                      'Code',
                                      _text(attendance.attendanceCode),
                                    ),
                                    _infoTile(
                                      Icons.login_rounded,
                                      'Punch In',
                                      _formatTime(
                                        attendance.punchInTime,
                                        label: attendance.punchInTimeLabel,
                                      ),
                                    ),
                                    _infoTile(
                                      Icons.logout_rounded,
                                      'Punch Out',
                                      _formatTime(
                                        attendance.punchOutTime,
                                        label: attendance.punchOutTimeLabel,
                                      ),
                                    ),
                                    _infoTile(
                                      Icons.timer_outlined,
                                      'Total Hours',
                                      attendance.totalHours,
                                    ),
                                    _infoTile(
                                      Icons.hourglass_bottom_rounded,
                                      'Total Minutes',
                                      '${attendance.totalMinutes}',
                                    ),
                                    _infoTile(
                                      Icons.sensors_rounded,
                                      'Currently Punched In',
                                      attendance.isPunchedIn ? 'Yes' : 'No',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildSection(
                                  title: 'Site',
                                  icon: Icons.location_on_outlined,
                                  children: [
                                    _infoTile(
                                      Icons.apartment_outlined,
                                      'Site',
                                      _text(attendance.siteName),
                                    ),
                                    _infoTile(
                                      Icons.tag_outlined,
                                      'Site ID',
                                      attendance.siteId?.toString() ?? '—',
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

  Widget _buildHeader(Attendance attendance, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.backgroundGray,
            backgroundImage: attendance.employeeAvatarUrl != null
                ? NetworkImage(attendance.employeeAvatarUrl!)
                : null,
            child: attendance.employeeAvatarUrl == null
                ? Text(
                    attendance.employeeName.trim().isEmpty
                        ? '?'
                        : attendance.employeeName.trim().substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: AppColors.headingBlack,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.employeeName,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(attendance.date),
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(attendance.status),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingBlack,
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
