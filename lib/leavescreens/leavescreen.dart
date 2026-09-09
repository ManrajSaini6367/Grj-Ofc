import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/models/getleavetypemodal.dart';
import 'package:grjoffice_apps/models/getmyleavemodal.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';
import 'package:intl/intl.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tabController;
  final _myLeavesScrollController = ScrollController();

  final _descriptionController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  List<LeaveTypeItem> _leaveTypes = const [];
  LeaveTypeItem? _selectedLeaveType;
  List<MyLeaveItem> _myLeaves = [];
  bool _loadingTypes = false;
  bool _loadingMyLeaves = false;
  bool _loadingMoreMyLeaves = false;
  bool _submitting = false;
  bool _loading = true;
  String? _deletingLeaveId;
  int _myLeavesPage = 1;
  int _myLeavesLastPage = 1;
  static const int _myLeavesPerPage = 20;

  bool get _hasMoreMyLeaves => _myLeavesPage < _myLeavesLastPage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _myLeavesScrollController.addListener(_onMyLeavesScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _loadLeaveTypes(),
      _loadMyLeaves(reset: true),
    ]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1 &&
        _myLeaves.isEmpty &&
        !_loadingMyLeaves) {
      _loadMyLeaves(reset: true);
    }
  }

  void _onMyLeavesScroll() {
    if (!_hasMoreMyLeaves || _loadingMyLeaves || _loadingMoreMyLeaves) return;
    final pos = _myLeavesScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 140) {
      _loadMyLeaves(reset: false);
    }
  }

  Future<void> _loadLeaveTypes() async {
    setState(() => _loadingTypes = true);
    final result = await getLeaveTypeApi(context);
    if (!mounted) return;

    final items = result?.data?.items
            ?.where((e) => (e.value ?? '').trim().isNotEmpty)
            .toList() ??
        const <LeaveTypeItem>[];

    setState(() {
      _leaveTypes = items;
      if (_selectedLeaveType == null && items.isNotEmpty) {
        _selectedLeaveType = items.first;
      } else if (_selectedLeaveType != null) {
        final stillExists = items.any(
          (e) => e.value == _selectedLeaveType!.value,
        );
        if (!stillExists) {
          _selectedLeaveType = items.isNotEmpty ? items.first : null;
        }
      }
      _loadingTypes = false;
    });
  }

  Future<void> _loadMyLeaves({bool reset = true}) async {
    if (reset) {
      if (_loadingMyLeaves) return;
      setState(() {
        _loadingMyLeaves = true;
        _myLeavesPage = 1;
        _myLeavesLastPage = 1;
      });
    } else {
      if (!_hasMoreMyLeaves || _loadingMoreMyLeaves || _loadingMyLeaves) {
        return;
      }
      setState(() => _loadingMoreMyLeaves = true);
    }

    final pageToLoad = reset ? 1 : _myLeavesPage + 1;
    final result = await getMyLeaveApi(
      context,
      page: pageToLoad,
      perPage: _myLeavesPerPage,
    );
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loadingMyLeaves = false;
        _loadingMoreMyLeaves = false;
      });
      return;
    }

    final items = result.data?.items ?? const <MyLeaveItem>[];
    final pagination = result.data?.pagination;
    final currentPage = pagination?.currentPage ?? pageToLoad;
    final lastPage = pagination?.lastPage ??
        (items.length < _myLeavesPerPage ? pageToLoad : pageToLoad + 1);

    setState(() {
      if (reset) {
        _myLeaves = List<MyLeaveItem>.from(items);
      } else {
        final existingIds = _myLeaves.map((e) => e.id).toSet();
        _myLeaves.addAll(
          items.where((e) => e.id == null || !existingIds.contains(e.id)),
        );
      }
      _myLeavesPage = currentPage;
      _myLeavesLastPage = lastPage;
      _loadingMyLeaves = false;
      _loadingMoreMyLeaves = false;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _myLeavesScrollController.removeListener(_onMyLeavesScroll);
    _myLeavesScrollController.dispose();
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _calcDurationDays(DateTime from, DateTime to) {
    final start = _dateOnly(from);
    final end = _dateOnly(to);
    if (end.isBefore(start)) return 0;
    return end.difference(start).inDays + 1;
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    if (width < 900) return 24;
    return 32;
  }

  int get _durationDays {
    if (_fromDate == null || _toDate == null) return 0;
    return _calcDurationDays(_fromDate!, _toDate!);
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

  Future<void> _confirmDeleteLeave(MyLeaveItem item) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty || _deletingLeaveId != null) return;

    final typeLabel = (item.typeLabel ?? item.type ?? 'leave').trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Leave',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete this $typeLabel request?',
            style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingLeaveId = id);
    final ok = await deleteLeaveApi(context, id);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _myLeaves.removeWhere((e) => e.id == id);
        _deletingLeaveId = null;
      });
    } else {
      setState(() => _deletingLeaveId = null);
    }
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

    final siteId = selectedSiteId();
    if (siteId == null) {
      _snack('Please select a site first.');
      return;
    }
    final leaveTypeValue = _selectedLeaveType?.value?.trim();
    if (leaveTypeValue == null || leaveTypeValue.isEmpty) {
      _snack('Please select a leave type.');
      return;
    }

    final dateFmt = DateFormat('yyyy-MM-dd');

    setState(() => _submitting = true);
    final success = await applyLeaveApi(
      context,
      siteId: siteId,
      type: leaveTypeValue,
      fromDate: dateFmt.format(_fromDate!),
      toDate: dateFmt.format(_toDate!),
      description: desc,
    );
    if (!mounted) return;

    if (!success) {
      setState(() => _submitting = false);
      return;
    }

    setState(() {
      _submitting = false;
      _fromDate = null;
      _toDate = null;
      _selectedLeaveType = _leaveTypes.isNotEmpty ? _leaveTypes.first : null;
      _descriptionController.clear();
    });

    _tabController.animateTo(1);
    await _loadMyLeaves(reset: true);
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
                          isRequired: true,
                          onTap: () => _pickDate(isFrom: true),
                        );
                        final toField = _DateField(
                          label: 'To Date',
                          hint: _fromDate == null
                              ? 'Select From Date first'
                              : 'Select end date',
                          value: _toDate,
                          enabled: _fromDate != null,
                          isRequired: true,
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
                    _sectionLabel('Leave Type', isRequired: true),
                    const SizedBox(height: 8),
                    if (_loadingTypes)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        ),
                      )
                    else if (_leaveTypes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'No leave types found.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadLeaveTypes,
                              child: Text(
                                'Retry',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedLeaveType?.value,
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
                              color:
                                  AppColors.borderGray.withValues(alpha: 0.55),
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
                        items: _leaveTypes
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type.value,
                                child: Text(
                                  type.label ?? type.value ?? '',
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
                          setState(() {
                            _selectedLeaveType = _leaveTypes.firstWhere(
                              (e) => e.value == value,
                            );
                          });
                        },
                      ),
                    SizedBox(height: isWide ? 22 : 18),
                    _sectionLabel('Description', isRequired: true),
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (_loadingMyLeaves && _myLeaves.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (_myLeaves.isEmpty) {
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
                TextButton(
                  onPressed:
                      _loadingMyLeaves ? null : () => _loadMyLeaves(reset: true),
                  child: Text(
                    'Refresh',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final showFooter = _loadingMoreMyLeaves || _hasMoreMyLeaves;

    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () => _loadMyLeaves(reset: true),
      child: ListView.separated(
        controller: _myLeavesScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24 + bottomInset),
        itemCount: _myLeaves.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _myLeaves.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _loadingMoreMyLeaves
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primaryRed,
                        ),
                      )
                    : TextButton(
                        onPressed: () => _loadMyLeaves(reset: false),
                        child: Text(
                          'Load more',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: _LeaveCard(
                item: _myLeaves[index],
                deleting: _deletingLeaveId == _myLeaves[index].id,
                onDelete: () => _confirmDeleteLeave(_myLeaves[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text, {bool isRequired = false}) {
    return fieldLabelText(
      text,
      isRequired: isRequired,
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
    this.isRequired = false,
  });

  final String label;
  final String hint;
  final DateTime? value;
  final VoidCallback onTap;
  final bool enabled;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? hint : DateFormat('dd MMM yyyy').format(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabelText(
          label,
          isRequired: isRequired,
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
  const _LeaveCard({
    required this.item,
    required this.onDelete,
    this.deleting = false,
  });

  final MyLeaveItem item;
  final VoidCallback onDelete;
  final bool deleting;

  String get _statusKey => (item.status ?? 'pending').trim().toLowerCase();

  bool get _canDelete =>
      _statusKey == 'pending' || _statusKey.isEmpty;

  String get _statusLabel {
    final key = _statusKey;
    if (key.isEmpty) return 'Pending';
    return key[0].toUpperCase() + key.substring(1);
  }

  Color get _statusColor {
    switch (_statusKey) {
      case 'approved':
        return const Color(0xFF059669);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  Color get _statusBg {
    switch (_statusKey) {
      case 'approved':
        return const Color(0xFFECFDF5);
      case 'rejected':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFFFF7ED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final width = MediaQuery.sizeOf(context).width;
    final pad = width < 360 ? 12.0 : 14.0;
    final days = item.durationDays ?? 0;
    final durationLabel = days == 1 ? '1 Day' : '$days Days';
    final typeLabel = (item.typeLabel ?? item.type ?? 'Leave').trim();
    final description = (item.description ?? '').trim();
    final fromText = item.fromDate == null
        ? '—'
        : dateFmt.format(item.fromDate!);
    final toText =
        item.toDate == null ? '—' : dateFmt.format(item.toDate!);

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
                      typeLabel,
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
              const SizedBox(width: 6),
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
                  _statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
              if (_canDelete) ...[
                const SizedBox(width: 4),
                Material(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: deleting ? null : onDelete,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Center(
                        child: deleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryRed,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.primaryRed,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
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
                  value: fromText,
                );
                final to = _MetaItem(
                  icon: Icons.event_rounded,
                  label: 'To',
                  value: toText,
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
          if (description.isNotEmpty) ...[
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
              description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ],
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
