import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/leavescreens/leave_models.dart';
import 'package:grjoffice_apps/leavescreens/leave_service.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _service = LeaveService.instance;
  late final TabController _tabController;

  final _descriptionController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  LeaveType _leaveType = LeaveType.casual;
  bool _submitting = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service.addListener(_onLeaveUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await _service.ensureLoaded();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _onLeaveUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onLeaveUpdated);
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    if (width < 900) return 24;
    return 32;
  }

  int get _durationDays {
    if (_fromDate == null || _toDate == null) return 0;
    return LeaveService.calculateDurationDays(_fromDate!, _toDate!);
  }

  String get _durationLabel {
    final days = _durationDays;
    if (days <= 0) return 'Select From & To dates';
    if (days == 1) return '1 Day';
    return '$days Days';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final today = _today;
    final lastDate = DateTime(today.year + 2, 12, 31);

    final DateTime firstDate;
    DateTime initial;

    if (isFrom) {
      firstDate = today;
      initial = _fromDate != null && !_fromDate!.isBefore(today)
          ? _dateOnly(_fromDate!)
          : today;
    } else {
      if (_fromDate == null) {
        _snack('Please select From Date first.');
        return;
      }
      firstDate = _dateOnly(_fromDate!);
      initial = _toDate != null && !_toDate!.isBefore(firstDate)
          ? _dateOnly(_toDate!)
          : firstDate;
    }

    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (day) {
        final d = _dateOnly(day);
        return !d.isBefore(firstDate) && !d.isAfter(lastDate);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: AppColors.white,
              surface: AppColors.cardWhite,
              onSurface: AppColors.headingBlack,
            ),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              headerBackgroundColor: AppColors.primaryRed,
              headerForegroundColor: AppColors.white,
              dayStyle: GoogleFonts.poppins(fontSize: 13),
              weekdayStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;

    final selected = _dateOnly(picked);
    setState(() {
      if (isFrom) {
        _fromDate = selected;
        if (_toDate != null && _toDate!.isBefore(selected)) {
          _toDate = selected;
        }
      } else {
        _toDate = selected;
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_fromDate == null || _toDate == null) {
      _snack('Please select From and To dates.');
      return;
    }
    if (_dateOnly(_fromDate!).isBefore(_today)) {
      _snack('From date cannot be in the past.');
      return;
    }
    if (_toDate!.isBefore(_fromDate!)) {
      _snack('To date cannot be before From date.');
      return;
    }
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      _snack('Please enter a description.');
      return;
    }
    if (desc.length < 5) {
      _snack('Description should be at least 5 characters.');
      return;
    }

    setState(() => _submitting = true);
    await _service.applyLeave(
      fromDate: _fromDate!,
      toDate: _toDate!,
      type: _leaveType,
      description: desc,
    );
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _fromDate = null;
      _toDate = null;
      _leaveType = LeaveType.casual;
      _descriptionController.clear();
    });

    _snack('Leave applied successfully.');
    _tabController.animateTo(1);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.headingBlack,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final width = MediaQuery.sizeOf(context).width;
    final contentMax = width >= 1100
        ? 780.0
        : width >= 900
            ? 720.0
            : double.infinity;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.leave,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Leave',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMax),
                  child: _LeaveTabBar(controller: _tabController),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildApplyTab(hPad, contentMax),
                        _buildMyLeaveTab(hPad, contentMax),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyTab(double hPad, double contentMax) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final cardPad = isWide ? 28.0 : (hPad < 16 ? 16.0 : 20.0);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 24 + bottomInset),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: Container(
                padding: EdgeInsets.all(cardPad),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.borderGray.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.045),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: AppColors.primaryRed,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apply for Leave',
                                style: GoogleFonts.poppins(
                                  fontSize: isWide ? 20 : 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.headingBlack,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose your dates, leave type, and reason to submit a request.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isWide ? 28 : 22),
                    _sectionLabel('Leave Duration'),
                    const SizedBox(height: 10),
                    _DurationBadge(label: _durationLabel, days: _durationDays),
                    SizedBox(height: isWide ? 22 : 18),
                    LayoutBuilder(
                      builder: (context, c) {
                        final stack = c.maxWidth < 460;
                        final fromField = _DateField(
                          label: 'From Date',
                          hint: 'Select start date',
                          value: _fromDate,
                          onTap: () => _pickDate(isFrom: true),
                        );
                        final toField = _DateField(
                          label: 'To Date',
                          hint: _fromDate == null
                              ? 'Select From Date first'
                              : 'Select end date',
                          value: _toDate,
                          enabled: _fromDate != null,
                          onTap: () => _pickDate(isFrom: false),
                        );
                        if (stack) {
                          return Column(
                            children: [
                              fromField,
                              const SizedBox(height: 16),
                              toField,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: fromField),
                            const SizedBox(width: 14),
                            Expanded(child: toField),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: isWide ? 22 : 18),
                    _sectionLabel('Leave Type'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<LeaveType>(
                      value: _leaveType,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                      dropdownColor: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.headingBlack,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderGray.withValues(alpha: 0.55),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryRed,
                            width: 1.4,
                          ),
                        ),
                      ),
                      items: LeaveType.values
                          .map(
                            (type) => DropdownMenuItem<LeaveType>(
                              value: type,
                              child: Text(
                                type.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.headingBlack,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _leaveType = value);
                      },
                    ),
                    SizedBox(height: isWide ? 22 : 18),
                    _sectionLabel('Description'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textDark,
                        height: 1.45,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write the reason for your leave…',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.inputHint,
                          fontSize: 13.5,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppColors.borderGray.withValues(alpha: 0.55),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primaryRed,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isWide ? 28 : 24),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          disabledBackgroundColor:
                              AppColors.primaryRed.withValues(alpha: 0.45),
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                'Apply Leave',
                                style: GoogleFonts.poppins(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyLeaveTab(double hPad, double contentMax) {
    final items = _service.leaves;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad + 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryRed.withValues(alpha: 0.12),
                        AppColors.primaryRed.withValues(alpha: 0.04),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work_off_outlined,
                    color: AppColors.primaryRed,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No leave requests yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apply for leave and track approval status here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                TextButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Apply Leave',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                    backgroundColor:
                        AppColors.primaryRed.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24 + bottomInset),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMax),
            child: _LeaveCard(request: items[index]),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppColors.headingBlack,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _LeaveTabBar extends StatelessWidget {
  const _LeaveTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primaryRed,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.textDark,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Apply Leave'),
          Tab(text: 'My Leave'),
        ],
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.label, required this.days});

  final String label;
  final int days;

  @override
  Widget build(BuildContext context) {
    final hasDates = days > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: hasDates
            ? AppColors.primaryRed.withValues(alpha: 0.07)
            : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasDates
              ? AppColors.primaryRed.withValues(alpha: 0.2)
              : AppColors.borderGray.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasDates
                  ? AppColors.primaryRed.withValues(alpha: 0.12)
                  : AppColors.iconBgGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.timelapse_rounded,
              color: hasDates ? AppColors.primaryRed : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total duration',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: hasDates
                        ? AppColors.primaryRed
                        : AppColors.headingBlack,
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final DateTime? value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? hint : DateFormat('dd MMM yyyy').format(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Material(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: value != null
                        ? AppColors.primaryRed.withValues(alpha: 0.35)
                        : AppColors.borderGray.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: value == null
                              ? AppColors.inputHint
                              : AppColors.headingBlack,
                          fontWeight:
                              value == null ? FontWeight.w400 : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 22,
                      color: value != null
                          ? AppColors.primaryRed
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.request});

  final LeaveRequest request;

  Color get _statusColor {
    switch (request.status) {
      case LeaveStatus.pending:
        return const Color(0xFFD97706);
      case LeaveStatus.approved:
        return const Color(0xFF059669);
      case LeaveStatus.rejected:
        return const Color(0xFFDC2626);
    }
  }

  Color get _statusBg {
    switch (request.status) {
      case LeaveStatus.pending:
        return const Color(0xFFFFF7ED);
      case LeaveStatus.approved:
        return const Color(0xFFECFDF5);
      case LeaveStatus.rejected:
        return const Color(0xFFFEF2F2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final width = MediaQuery.sizeOf(context).width;
    final pad = width < 360 ? 12.0 : 14.0;
    final durationLabel = request.durationDays == 1
        ? '1 Day'
        : '${request.durationDays} Days';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.primaryRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.type.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      durationLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  request.status.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final stack = c.maxWidth < 320;
                final from = _MetaItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'From',
                  value: dateFmt.format(request.fromDate),
                );
                final to = _MetaItem(
                  icon: Icons.event_rounded,
                  label: 'To',
                  value: dateFmt.format(request.toDate),
                );
                if (stack) {
                  return Column(
                    children: [
                      from,
                      const SizedBox(height: 8),
                      to,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: from),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: AppColors.borderGray.withValues(alpha: 0.55),
                    ),
                    Expanded(child: to),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Description',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primaryRed),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
