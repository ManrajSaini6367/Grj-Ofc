import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/attendancescreen/view_attendance_screen.dart';
import 'package:grjoffice_apps/models/attendance_model.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Present', 'Absent', 'Leave'
  DateTime _selectedDate = DateTime.now();
  List<Attendance> _attendances = [];
  AttendancesSummary? _summary;
  bool _isLoading = true;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAttendances());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _apiDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  String? get _apiStatus {
    return switch (_selectedFilter) {
      'Present' => 'present',
      'Absent' => 'absent',
      'Leave' => 'leave',
      _ => null,
    };
  }

  int get _totalCount => _summary?.total ?? _attendances.length;
  int get _presentCount =>
      _summary?.present ??
      _attendances.where((a) => a.status == AttendanceStatus.present).length;
  int get _absentCount =>
      _summary?.absent ??
      _attendances.where((a) => a.status == AttendanceStatus.absent).length;
  int get _leaveCount =>
      _summary?.leave ??
      _attendances.where((a) => a.status == AttendanceStatus.leave).length;

  List<Attendance> get _filteredAttendances {
    if (_searchQuery.isEmpty) return _attendances;
    final query = _searchQuery.toLowerCase();
    return _attendances
        .where((a) => a.employeeName.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _loadAttendances({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isLoading = true);
    }

    final response = await getAttendancesApi(
      context,
      date: _apiDate,
      status: _apiStatus,
      search: _searchQuery,
      perPage: 50,
    );

    if (!mounted) return;
    setState(() {
      _attendances = response?.data?.items ?? [];
      _summary = response?.data?.summary;
      _isLoading = false;
    });
  }

  Future<void> _onSearchChanged(String value) async {
    final next = value.trim();
    setState(() => _searchQuery = next);

    final token = ++_searchToken;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || token != _searchToken) return;

    final response = await getAttendancesApi(
      context,
      date: _apiDate,
      status: _apiStatus,
      search: next,
      perPage: 50,
    );
    if (!mounted || token != _searchToken) return;

    setState(() {
      _attendances = response?.data?.items ?? [];
      _summary = response?.data?.summary;
    });
  }

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              onSurface: AppColors.headingBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    await _loadAttendances();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

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
    }
    if (time == null) return '--:--';
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredAttendances;
    final hPad = _hPad(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.employeeAttendances,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Employee Attendances',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search employees...',
                    hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            _buildDateSelector(hPad),
            _buildFilterChips(),
            _buildSummaryCards(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : filteredList.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.primaryRed,
                          onRefresh: () => _loadAttendances(showLoader: false),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildAttendanceCard(filteredList[index]);
                            },
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

  Widget _buildDateSelector(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Date:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.headingBlack,
            ),
          ),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primaryRed),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(_selectedDate),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = [
      _FilterChipItem('All', Icons.group_outlined),
      _FilterChipItem('Present', Icons.check_circle_outline),
      _FilterChipItem('Absent', Icons.cancel_outlined),
      _FilterChipItem('Leave', Icons.directions_walk_outlined),
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = _selectedFilter == chip.label;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() => _selectedFilter = chip.label);
                _loadAttendances();
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRed : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey.shade200.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      chip.icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip.label,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      height: 96,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _buildStatCard(
            title: 'Total',
            count: _totalCount,
            icon: Icons.groups_outlined,
            iconColor: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildStatCard(
            title: 'Present',
            count: _presentCount,
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
          _buildStatCard(
            title: 'Absent',
            count: _absentCount,
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
          ),
          _buildStatCard(
            title: 'Leave',
            count: _leaveCount,
            icon: Icons.directions_walk_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFF7ED),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Attendance att) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (att.status) {
      case AttendanceStatus.present:
        statusColor = const Color(0xFF10B981);
        statusText = 'Present';
        statusIcon = Icons.check_circle;
        break;
      case AttendanceStatus.absent:
        statusColor = const Color(0xFFEF4444);
        statusText = 'Absent';
        statusIcon = Icons.cancel;
        break;
      case AttendanceStatus.leave:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'On Leave';
        statusIcon = Icons.directions_walk;
        break;
    }

    final avatar = mediaUrl(att.employeeAvatarUrl);

    return InkWell(
      onTap: () => _openAttendanceDetails(att),
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.backgroundGray,
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty || att.employeeName.trim().isEmpty
                      ? Text(
                          att.employeeName.trim().isEmpty
                              ? '?'
                              : att.employeeName.trim().substring(0, 1).toUpperCase(),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textDark),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        att.employeeName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headingBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onPressed: () => _openAttendanceDetails(att),
                ),
              ],
            ),
            
            if (att.status == AttendanceStatus.present) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTimeColumn(
                      'Punch In',
                      _formatTime(att.punchInTime, label: att.punchInTimeLabel),
                      Icons.login_rounded,
                      const Color(0xFF3B82F6),
                    ),
                    Container(width: 1, height: 30, color: AppColors.borderGray),
                    _buildTimeColumn(
                      'Punch Out',
                      _formatTime(att.punchOutTime, label: att.punchOutTimeLabel),
                      Icons.logout_rounded,
                      const Color(0xFFF59E0B),
                    ),
                    Container(width: 1, height: 30, color: AppColors.borderGray),
                    _buildTimeColumn('Total Hrs', att.totalHours, Icons.timer_outlined, const Color(0xFF8B5CF6)),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _openAttendanceDetails(Attendance attendance) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ViewAttendanceScreen(attendance: attendance),
      ),
    );
  }

  Widget _buildTimeColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.headingBlack),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.how_to_reg_outlined, size: 64, color: AppColors.borderGray),
          const SizedBox(height: 16),
          Text(
            'No attendances found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the filter or searching.',
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

class _FilterChipItem {
  final String label;
  final IconData icon;

  _FilterChipItem(this.label, this.icon);
}
