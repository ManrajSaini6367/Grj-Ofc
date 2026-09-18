import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/models/attendance_model.dart';
import 'package:grjoffice_apps/models/getemployeemodal.dart';
import 'package:grjoffice_apps/models/my_attendance_calendar.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/attendance_service.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

enum _AttendanceViewMode { myAttendance, employees }

class _EmployeeOption {
  const _EmployeeOption({required this.id, required this.name});

  final int id;
  final String name;
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  MyAttendanceCalendarData? _calendarData;
  bool _loading = true;
  bool _apiLoaded = false;
  final AttendanceService _attendance = AttendanceService.instance;

  _AttendanceViewMode _viewMode = _AttendanceViewMode.myAttendance;
  List<_EmployeeOption> _employees = const [];
  int? _selectedEmployeeId;
  bool _loadingEmployees = false;
  bool _employeesLoaded = false;

  bool get _isMyAttendanceView => _viewMode == _AttendanceViewMode.myAttendance;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_today.year, _today.month);
    _selectedDate = _today;
    _attendance.addListener(_onLiveAttendanceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
  }

  @override
  void dispose() {
    _attendance.removeListener(_onLiveAttendanceChanged);
    super.dispose();
  }

  void _onLiveAttendanceChanged() {
    if (!mounted || _calendarData == null || !_isMyAttendanceView) return;
    _syncTodayIntoCalendar();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    if (width < 900) return 22;
    return 28;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInFocusedMonth(DateTime date) {
    return date.year == _focusedMonth.year && date.month == _focusedMonth.month;
  }

  bool _canTapDate(DateTime date) => _isInFocusedMonth(date);

  Future<void> _loadMonth() async {
    if (!_isMyAttendanceView && _selectedEmployeeId == null) {
      setState(() {
        _loading = false;
        _calendarData = null;
        _apiLoaded = false;
      });
      return;
    }

    setState(() => _loading = true);
    final monthKey =
        '${_focusedMonth.year.toString().padLeft(4, '0')}-'
        '${_focusedMonth.month.toString().padLeft(2, '0')}';

    final response = await getAttendanceCalendarApi(
      context,
      month: monthKey,
      userId: _isMyAttendanceView ? null : _selectedEmployeeId,
    );

    if (!mounted) return;
    setState(() {
      _calendarData = response?.toMyAttendanceCalendarData();
      _apiLoaded = response?.success == true;
    });
    if (_isMyAttendanceView) {
      await _syncTodayIntoCalendar();
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!_isSameMonth(_selectedDate, _focusedMonth)) {
        _selectedDate = _isSameMonth(_today, _focusedMonth)
            ? _today
            : _focusedMonth;
      }
    });
  }

  Future<void> _loadEmployees() async {
    if (_loadingEmployees) return;
    setState(() => _loadingEmployees = true);

    try {
      final response = await getEmployeesApi(
        context,
        perPage: 15,
        fetchAllPages: true,
      );
      final items = response?.data?.items ?? const <EmployeeListItem>[];
      final fetched = <_EmployeeOption>[];

      for (final item in items) {
        final id = item.id;
        if (id == null) continue;
        final displayName = (item.name?.trim().isNotEmpty == true)
            ? item.name!.trim()
            : '${item.firstName ?? ''} ${item.lastName ?? ''}'.trim();
        if (displayName.isEmpty) continue;
        fetched.add(_EmployeeOption(id: id, name: displayName));
      }

      fetched.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      if (!mounted) return;
      setState(() {
        _employees = fetched;
        _loadingEmployees = false;
        _employeesLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _employees = const [];
        _loadingEmployees = false;
        _employeesLoaded = true;
      });
    }
  }

  Future<void> _onViewModeChanged(_AttendanceViewMode mode) async {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      if (mode == _AttendanceViewMode.myAttendance) {
        _selectedEmployeeId = null;
      }
    });

    if (mode == _AttendanceViewMode.employees && !_employeesLoaded) {
      await _loadEmployees();
    }
    if (!mounted) return;
    await _loadMonth();
  }

  void _onEmployeeSelected(int? employeeId) {
    if (_selectedEmployeeId == employeeId) return;
    setState(() => _selectedEmployeeId = employeeId);
    _loadMonth();
  }

  Future<void> _syncTodayIntoCalendar() async {
    if (!_isMyAttendanceView) return;
    if (!_isSameMonth(_today, _focusedMonth)) return;

    final liveStatus = await getTodayAttendanceApi(context, showErrors: false);
    if (!mounted || liveStatus == null) return;

    final calendarDay = _calendarData?.dayFor(_today);
    final merged = mergeTodayWithLiveStatus(
      today: _today,
      liveStatus: liveStatus,
      calendarDay: calendarDay,
    );
    await _applyTodayDayToCalendar(merged);
  }

  Future<MyAttendanceDay?> _resolveDayForSheet(DateTime date) async {
    if (_isMyAttendanceView && _isSameDay(date, _today)) {
      final liveStatus = await getTodayAttendanceApi(
        context,
        showErrors: false,
      );
      if (!mounted) return _dayInfo(date);
      if (liveStatus != null) {
        final merged = mergeTodayWithLiveStatus(
          today: _today,
          liveStatus: liveStatus,
          calendarDay: _dayInfo(date),
        );
        await _applyTodayDayToCalendar(merged);
        return merged.hasRecord ? merged : null;
      }
    }

    return _dayInfo(date);
  }

  Future<void> _applyTodayDayToCalendar(MyAttendanceDay merged) async {
    final current = _calendarData;
    if (current == null) return;

    final todayKey = MyAttendanceCalendarData.dateKey(_today);
    final updatedDays = Map<String, MyAttendanceDay>.from(current.days);
    if (merged.hasRecord) {
      updatedDays[todayKey] = merged;
    } else {
      updatedDays.remove(todayKey);
    }

    if (!mounted) return;
    setState(() {
      _calendarData = MyAttendanceCalendarData(
        monthKey: current.monthKey,
        summary: current.summary,
        days: updatedDays,
      );
    });
  }

  void _onDrawerItemTap(int index) => navigateFromDrawer(context, index);

  void _changeMonth(int delta) {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    setState(() {
      _focusedMonth = next;
      if (_isSameMonth(_today, next)) {
        _selectedDate = _today;
      } else {
        _selectedDate = DateTime(next.year, next.month, 1);
      }
    });
    _loadMonth();
  }

  MyAttendanceDay? _dayInfo(DateTime date) => _calendarData?.dayFor(date);

  void _onDateTap(DateTime date) async {
    if (!_canTapDate(date)) return;

    setState(() => _selectedDate = date);
    final day = await _resolveDayForSheet(date);
    if (!mounted) return;
    _showActivityLogsSheet(date, day);
  }

  Future<void> _showActivityLogsSheet(
    DateTime date,
    MyAttendanceDay? day,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActivityLogsSheet(date: date, day: day),
    );
  }

  List<DateTime> _buildCalendarDays() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startOffset = first.weekday % 7;
    final start = first.subtract(Duration(days: startOffset));
    final endOffset = 6 - (last.weekday % 7);
    final end = last.add(Duration(days: endOffset));

    final days = <DateTime>[];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      days.add(DateTime(d.year, d.month, d.day));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final width = MediaQuery.sizeOf(context).width;
    final summary = _calendarData?.summary ?? const MyAttendanceMonthSummary();
    final hasApiDays = (_calendarData?.days.isNotEmpty ?? false);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      endDrawer: const AppEndDrawer(),
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.myAttendance,
        onItemTap: _onDrawerItemTap,
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Attendance',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryRed,
                onRefresh: _loadMonth,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildViewModeSelector(width),
                          if (!_isMyAttendanceView) ...[
                            const SizedBox(height: 12),
                            _buildEmployeeSelector(width),
                          ],
                          const SizedBox(height: 12),
                          _buildCalendarCard(width),
                          if (!_loading &&
                              !_isMyAttendanceView &&
                              _selectedEmployeeId == null) ...[
                            const SizedBox(height: 12),
                            _buildInfoBanner(
                              'Select an employee to view their attendance calendar.',
                            ),
                          ] else if (!_loading && !_apiLoaded) ...[
                            const SizedBox(height: 12),
                            _buildInfoBanner(
                              'Could not load attendance calendar. Pull down to refresh.',
                            ),
                          ] else if (!_loading && !hasApiDays) ...[
                            const SizedBox(height: 12),
                            _buildInfoBanner(
                              'No attendance records for this month yet.',
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            )
                          else if (_isMyAttendanceView ||
                              _selectedEmployeeId != null) ...[
                            _buildLegend(),
                            const SizedBox(height: 12),
                            _buildSummaryCard(summary, width),
                          ],
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

  Widget _buildViewModeSelector(double width) {
    final compact = width < 360;
    final fontSize = compact ? 13.0 : 14.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildViewModeTab(
              label: 'My Attendance',
              selected: _isMyAttendanceView,
              fontSize: fontSize,
              onTap: () => _onViewModeChanged(_AttendanceViewMode.myAttendance),
            ),
          ),
          Expanded(
            child: _buildViewModeTab(
              label: 'Employees',
              selected: !_isMyAttendanceView,
              fontSize: fontSize,
              onTap: () => _onViewModeChanged(_AttendanceViewMode.employees),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeTab({
    required String label,
    required bool selected,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primaryRed
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeSelector(double width) {
    final compact = width < 360;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Employee',
            style: GoogleFonts.poppins(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 10),
          if (_loadingEmployees)
            Container(
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.borderGray.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Loading employees...',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else if (_employees.isEmpty)
            Container(
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.borderGray.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'No employees found for this site.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            DropdownButtonHideUnderline(
              child: DropdownButtonFormField<int>(
                value: _selectedEmployeeId,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.backgroundGray,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.borderGray.withValues(alpha: 0.45),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.borderGray.withValues(alpha: 0.45),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.primaryRed.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                  ),
                ),
                hint: Text(
                  'Select Employee',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.headingBlack,
                  fontWeight: FontWeight.w500,
                ),
                items: _employees
                    .map(
                      (employee) => DropdownMenuItem<int>(
                        value: employee.id,
                        child: Text(
                          employee.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _onEmployeeSelected,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFEA580C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: const [
        _LegendDot(color: Color(0xFF4CAF50), label: 'Present'),
        _LegendDot(color: Color(0xFFE53935), label: 'Absent'),
        _LegendDot(color: Color(0xFFF59E0B), label: 'Leave'),
        _LegendDot(color: Color(0xFF2563EB), label: 'Holiday'),
        _LegendDot(color: Color(0xFFFFE5E5), label: 'Current'),
        _LegendDot(color: AppColors.primaryRed, label: 'Selected'),
      ],
    );
  }

  Widget _buildCalendarCard(double width) {
    final monthLabel = DateFormat('MMMM yyyy').format(_focusedMonth);
    final days = _buildCalendarDays();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.headingBlack,
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: width < 360 ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.headingBlack,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: _weekdays
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 0,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              final inMonth = date.month == _focusedMonth.month;
              final isSelected = inMonth && _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, _today);
              final dayInfo = inMonth ? _dayInfo(date) : null;
              final canTap = _canTapDate(date);

              return _CalendarDayCell(
                date: date,
                inMonth: inMonth,
                isSelected: isSelected,
                isToday: isToday,
                canTap: canTap,
                dotColor: dayInfo?.markerColor,
                showDot: dayInfo?.showMarker ?? false,
                onTap: canTap ? () => _onDateTap(date) : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(MyAttendanceMonthSummary summary, double width) {
    final gap = width < 360 ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(width < 360 ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          SizedBox(height: gap),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _SummaryTile(
                    width: itemWidth,
                    value: '${summary.presentDays}',
                    label: 'Present Days',
                    valueColor: const Color(0xFF059669),
                    background: const Color(0xFFECFDF5),
                  ),
                  _SummaryTile(
                    width: itemWidth,
                    value: '${summary.leaveDays}',
                    label: 'Leave Days',
                    valueColor: const Color(0xFFDC2626),
                    background: const Color(0xFFFEF2F2),
                  ),
                  _SummaryTile(
                    width: itemWidth,
                    value: '${summary.holidayDays}',
                    label: 'Holiday Days',
                    valueColor: const Color(0xFF2563EB),
                    background: const Color(0xFFEFF6FF),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.inMonth,
    required this.isSelected,
    required this.isToday,
    required this.canTap,
    required this.showDot,
    this.dotColor,
    this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final bool isSelected;
  final bool isToday;
  final bool canTap;
  final bool showDot;
  final Color? dotColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Use the same marker color that was previously shown as a dot.
    final Color? statusColor = showDot && inMonth ? dotColor : null;

    final textColor = !inMonth
        ? AppColors.textSecondary.withValues(alpha: 0.35)
        : isSelected
        ? Colors.white
        : statusColor != null
        ? Colors.white
        : AppColors.headingBlack;

    final cell = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // Priority:
            // 1. Selected date
            // 2. Status/marker color
            // 3. Today background
            // 4. Transparent
            color: isSelected
                ? AppColors.primaryRed
                : statusColor ??
                      (isToday
                          ? AppColors.primaryRed.withValues(alpha: 0.08)
                          : Colors.transparent),
            shape: BoxShape.circle,

            border: isToday && !isSelected && statusColor == null
                ? Border.all(color: AppColors.primaryRed, width: 1.2)
                : null,
          ),
          child: Text(
            '${date.day}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),

        // Dot removed because the color is now used
        // as the date background.
        const SizedBox(height: 3),
        const SizedBox(width: 6, height: 6),
      ],
    );

    if (!canTap) {
      return Opacity(opacity: 0.45, child: cell);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: AppColors.primaryRed.withValues(alpha: 0.08),
        child: cell,
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.width,
    required this.value,
    required this.label,
    required this.valueColor,
    required this.background,
  });

  final double width;
  final String value;
  final String label;
  final Color valueColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: valueColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLogsSheet extends StatelessWidget {
  const _ActivityLogsSheet({required this.date, this.day});

  final DateTime date;
  final MyAttendanceDay? day;

  bool get _hasApiData => day?.hasRecord ?? false;

  List<MyAttendanceActivity> get _visibleActivities {
    return (day?.activities ?? const <MyAttendanceActivity>[]).where((item) {
      final lower = item.title.toLowerCase();
      return !lower.contains('punch in') &&
          !lower.contains('punch out') &&
          !lower.contains('checked in') &&
          !lower.contains('checked out');
    }).toList();
  }

  Color _statusColor() {
    if (!_hasApiData) return AppColors.textSecondary;
    if (day!.isHoliday) return const Color(0xFF2563EB);
    return switch (day!.status) {
      AttendanceStatus.present => const Color(0xFF059669),
      AttendanceStatus.leave => const Color(0xFFF59E0B),
      AttendanceStatus.absent => const Color(0xFFDC2626),
    };
  }

  String get _statusTitle {
    if (!_hasApiData) return 'No Record';
    return day!.statusTitle;
  }

  String get _emptyMessage {
    if (!_hasApiData) return 'No attendance record for this date.';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.58;
    final statusColor = _statusColor();
    final activities = _visibleActivities;
    final hasActivities = activities.isNotEmpty;
    final emptyMessage = _emptyMessage;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Activity Logs',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy').format(date),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: hasActivities
                          ? ListView.separated(
                              itemCount: activities.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = activities[index];
                                final title = item.title.toLowerCase();
                                final icon =
                                    title.contains('out') ||
                                        title.contains('checked out')
                                    ? Icons.arrow_circle_up_outlined
                                    : title.contains('in') ||
                                          title.contains('checked in')
                                    ? Icons.arrow_circle_down_outlined
                                    : Icons.event_note_outlined;
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundGray,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.borderGray.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: AppColors.iconBgGray,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          icon,
                                          color: AppColors.textDark,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.headingBlack,
                                              ),
                                            ),
                                            if (item.subtitle
                                                    ?.trim()
                                                    .isNotEmpty ==
                                                true)
                                              Text(
                                                item.subtitle!.trim(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : emptyMessage.isNotEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  emptyMessage,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
}
