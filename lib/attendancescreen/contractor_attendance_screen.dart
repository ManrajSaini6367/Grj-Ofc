import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:grjoffice_apps/attendancescreen/add_contractor_attendance_screen.dart';
import 'package:grjoffice_apps/AmaniLabour/amani_labour.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/models/labourattendancereport.dart';
import 'package:grjoffice_apps/models/listcontractor.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/permission_gate.dart';
import 'package:intl/intl.dart';

enum _DatePreset { today, thisWeek, thisMonth, custom }

class ContractorAttendanceScreen extends StatefulWidget {
  const ContractorAttendanceScreen({super.key});

  @override
  State<ContractorAttendanceScreen> createState() =>
      _ContractorAttendanceScreenState();
}

class _ContractorAttendanceScreenState
    extends State<ContractorAttendanceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<LabourContractor> _contractors = [];

  String? _selectedContractorId;

  DateTime? _startDate;
  DateTime? _endDate;

  _DatePreset _datePreset = _DatePreset.thisMonth;

  bool _loadingContractors = true;
  bool _searching = false;
  bool _hasSearched = false;
  bool _publishedOnly = false;

  List<_AttendanceDayRow> _rows = [];

  _AttendanceRates? _rates;

  Amounts? _apiTotals;
  Amounts? _apiAmounts;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _startDate = DateTime(now.year, now.month, 1);

    _endDate = DateTime(now.year, now.month, now.day);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContractors());
  }

  @override
  void dispose() {
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 360) return 14;
    if (width < 600) return 18;

    return 20;
  }

  bool get _isWide => MediaQuery.sizeOf(context).width >= 700;

  LabourContractor? get _selectedContractor {
    final id = _selectedContractorId;

    if (id == null) return null;

    for (final contractor in _contractors) {
      if (contractor.id == id) {
        return contractor;
      }
    }

    return null;
  }

  String _fmtDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _loadContractors() async {
    if (mounted) {
      setState(() {
        _loadingContractors = true;
      });
    }

    final response = await getContractorListApi(context, perPage: 100);

    if (!mounted) return;

    final contractors =
        response?.data?.items
            ?.map(_toContractor)
            .where((c) => c.name.trim().isNotEmpty)
            .toList() ??
        [];

    setState(() {
      _contractors = contractors;
      _loadingContractors = false;

      if (_selectedContractorId != null &&
          !_contractors.any((c) => c.id == _selectedContractorId)) {
        _selectedContractorId = null;
      }
    });
  }

  LabourContractor _toContractor(ContractorListItem item) {
    return LabourContractor(
      id: (item.id ?? 0).toString(),
      name: item.name ?? '',
      mobile: item.mobile ?? '',
      address: item.address ?? '',
      masonRatePerDay: item.masonRateValue,
      beldarRatePerDay: item.beldarRateValue,
      coolieRatePerDay: item.coolieRateValue,
      masonOtRatePerHour: item.masonOverRateValue,
      beldarOtRatePerHour: item.beldarOverRateValue,
      coolieOtRatePerHour: item.coolieOverRateValue,
      status: (item.status ?? '').toLowerCase() == 'unpublished'
          ? ContractorStatus.unpublished
          : ContractorStatus.published,
    );
  }

  Future<void> _applyDatePreset(_DatePreset preset) async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    DateTime start;
    DateTime end = today;

    switch (preset) {
      case _DatePreset.today:
        start = today;
        break;

      case _DatePreset.thisWeek:
        start = today.subtract(Duration(days: today.weekday - 1));
        break;

      case _DatePreset.thisMonth:
        start = DateTime(today.year, today.month, 1);
        break;

      case _DatePreset.custom:
        setState(() {
          _datePreset = _DatePreset.custom;
        });
        return;
    }

    final shouldRefresh =
        _hasSearched && _selectedContractor != null && !_searching;

    setState(() {
      _datePreset = preset;
      _startDate = start;
      _endDate = end;
    });

    if (shouldRefresh) {
      await _onSearch();
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
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

    if (picked == null || !mounted) {
      return;
    }

    final pickedDate = DateTime(picked.year, picked.month, picked.day);

    final shouldRefresh =
        _hasSearched && _selectedContractor != null && !_searching;

    setState(() {
      _datePreset = _DatePreset.custom;

      if (isStart) {
        _startDate = pickedDate;

        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = pickedDate;

        if (_startDate != null && _startDate!.isAfter(_endDate!)) {
          _startDate = _endDate;
        }
      }
    });

    if (shouldRefresh) {
      await _onSearch();
    }
  }

  Future<void> _onSearch() async {
    final contractor = _selectedContractor;

    if (contractor == null) {
      _showMsg('Search and select a contractor first.');
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showMsg('Please select start and end date.');
      return;
    }

    final siteId = selectedSiteId();

    if (siteId == null) {
      _showMsg('Please select a site first.');
      return;
    }

    setState(() {
      _searching = true;
      _hasSearched = true;
    });

    final report = await getLabourAttendanceReportApi(
      context,
      siteId: siteId.toString(),
      contractorId: contractor.id,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
    );

    if (!mounted) return;

    if (report == null || report.success == false) {
      setState(() {
        _rows = [];
        _rates = null;
        _apiTotals = null;
        _apiAmounts = null;
        _searching = false;
      });

      if (report?.message != null && report!.message!.trim().isNotEmpty) {
        _showMsg(report.message!);
      }

      return;
    }

    final data = report.data;
    final apiRates = data?.rates;

    final rows =
        (data?.items ?? [])
            .where((item) => item.date != null)
            .map(
              (item) => _AttendanceDayRow(
                date: item.date!,
                mason: item.mason?.round() ?? 0,
                beldar: item.beldar?.round() ?? 0,
                coolie: item.coolie?.round() ?? 0,
                masonOver: item.masonOver?.round() ?? 0,
                beldarOver: item.beldarOver?.round() ?? 0,
                coolieOver: item.coolieOver?.round() ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    setState(() {
      _rates = _AttendanceRates(
        mason: apiRates?.mason ?? contractor.masonRatePerDay,
        beldar: apiRates?.beldar ?? contractor.beldarRatePerDay,
        coolie: apiRates?.coolie ?? contractor.coolieRatePerDay,
        masonOver: apiRates?.masonOver ?? contractor.masonOtRatePerHour,
        beldarOver: apiRates?.beldarOver ?? contractor.beldarOtRatePerHour,
        coolieOver: apiRates?.coolieOver ?? contractor.coolieOtRatePerHour,
      );

      _apiTotals = data?.totals;
      _apiAmounts = data?.amounts;
      _rows = rows;
      _searching = false;
    });
  }

  void _selectContractor(String? contractorId) {
    if (contractorId == null) {
      return;
    }

    final contractor = _contractors.firstWhere(
      (c) => c.id == contractorId,
      orElse: () => _contractors.first,
    );

    setState(() {
      _selectedContractorId = contractor.id;

      _hasSearched = false;
      _rows = [];
      _rates = null;
      _apiTotals = null;
      _apiAmounts = null;
    });
  }

  void _clearSelectedContractor() {
    setState(() {
      _selectedContractorId = null;

      _hasSearched = false;
      _rows = [];
      _rates = null;
      _apiTotals = null;
      _apiAmounts = null;
    });
  }

  void _onClear() {
    final now = DateTime.now();

    setState(() {
      _selectedContractorId = null;

      _datePreset = _DatePreset.thisMonth;

      _startDate = DateTime(now.year, now.month, 1);

      _endDate = DateTime(now.year, now.month, now.day);

      _hasSearched = false;
      _rows = [];
      _rates = null;
      _apiTotals = null;
      _apiAmounts = null;
      _searching = false;
      _publishedOnly = false;
    });
  }

  void _showMsg(String text) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text, style: GoogleFonts.poppins())));
  }

  _AttendanceDayRow get _totalRow {
    final totals = _apiTotals;

    if (totals != null) {
      return _AttendanceDayRow(
        date: DateTime(0),
        mason: totals.mason?.round() ?? 0,
        beldar: totals.beldar?.round() ?? 0,
        coolie: totals.coolie?.round() ?? 0,
        masonOver: totals.masonOver?.round() ?? 0,
        beldarOver: totals.beldarOver?.round() ?? 0,
        coolieOver: totals.coolieOver?.round() ?? 0,
      );
    }

    return _AttendanceDayRow(
      date: DateTime(0),
      mason: _rows.fold(0, (sum, row) => sum + row.mason),
      beldar: _rows.fold(0, (sum, row) => sum + row.beldar),
      coolie: _rows.fold(0, (sum, row) => sum + row.coolie),
      masonOver: _rows.fold(0, (sum, row) => sum + row.masonOver),
      beldarOver: _rows.fold(0, (sum, row) => sum + row.beldarOver),
      coolieOver: _rows.fold(0, (sum, row) => sum + row.coolieOver),
    );
  }

  _AttendanceDayRow get _amountRow {
    final amounts = _apiAmounts;

    if (amounts != null) {
      return _AttendanceDayRow(
        date: DateTime(0),
        mason: amounts.mason?.round() ?? 0,
        beldar: amounts.beldar?.round() ?? 0,
        coolie: amounts.coolie?.round() ?? 0,
        masonOver: amounts.masonOver?.round() ?? 0,
        beldarOver: amounts.beldarOver?.round() ?? 0,
        coolieOver: amounts.coolieOver?.round() ?? 0,
      );
    }

    final rates = _rates ?? const _AttendanceRates();

    final total = _totalRow;

    return _AttendanceDayRow(
      date: DateTime(0),
      mason: (total.mason * rates.mason).round(),
      beldar: (total.beldar * rates.beldar).round(),
      coolie: (total.coolie * rates.coolie).round(),
      masonOver: (total.masonOver * rates.masonOver).round(),
      beldarOver: (total.beldarOver * rates.beldarOver).round(),
      coolieOver: (total.coolieOver * rates.coolieOver).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.contractorAttendances,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Attendances',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
              titleFontSize: 15,
              centerTitle: false,
              actions: [
                PermissionGate(
                  permission: AppPermissions.labourAttendancesCreate,
                  child: Material(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 0,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const AddContractorAttendanceScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Add',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
                children: [
                  _buildContractorFilterCard(),

                  const SizedBox(height: 14),

                  _buildDatePresets(),

                  const SizedBox(height: 10),

                  _buildDateSection(),

                  const SizedBox(height: 14),

                  _buildActionButtons(),

                  const SizedBox(height: 18),

                  if (_searching)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryRed,
                        ),
                      ),
                    )
                  else if (!_hasSearched)
                    _buildEmptyState(
                      icon: Icons.groups_outlined,
                      title: 'Find contractor attendance',
                      subtitle:
                          'Select a contractor from Filter, set dates, then tap Search.',
                    )
                  else if (_rows.isEmpty)
                    _buildEmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No records found',
                      subtitle:
                          'No attendance data for this contractor and date range.',
                    )
                  else
                    _buildResults(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractorFilterCard() {
    final contractor = _selectedContractor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 18,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contractor',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contractor == null
                          ? 'Select contractor to view attendance'
                          : 'Selected contractor',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (contractor != null)
                IconButton(
                  tooltip: 'Clear contractor',
                  onPressed: _clearSelectedContractor,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          if (_loadingContractors)
            Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.operationsCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.borderGray.withValues(alpha: 0.55),
                ),
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryRed,
                ),
              ),
            )
          else if (_contractors.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.operationsCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.borderGray.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No contractors found.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadContractors,
                    child: Text(
                      'Retry',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedContractorId,
              isExpanded: true,
              menuMaxHeight: 320,

              // Selected contractor ke liye compact UI
              selectedItemBuilder: (context) {
                final contractors = _contractors.where((contractor) {
                  if (_publishedOnly &&
                      contractor.status != ContractorStatus.published) {
                    return false;
                  }

                  return true;
                }).toList();

                return contractors.map((contractor) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      contractor.name.isEmpty
                          ? 'Unnamed contractor'
                          : contractor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headingBlack,
                      ),
                    ),
                  );
                }).toList();
              },

              decoration: InputDecoration(
                hintText: 'Select contractor',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.inputHint,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.cardWhite,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.borderGray.withValues(alpha: 0.7),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.borderGray.withValues(alpha: 0.7),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryRed,
                    width: 1.4,
                  ),
                ),
              ),

              items: _contractors
                  .where((contractor) {
                    if (_publishedOnly &&
                        contractor.status != ContractorStatus.published) {
                      return false;
                    }

                    return true;
                  })
                  .map(
                    (contractor) => DropdownMenuItem<String>(
                      value: contractor.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.primaryRed.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              contractor.name.isNotEmpty
                                  ? contractor.name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // IMPORTANT
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contractor.name.isEmpty
                                      ? 'Unnamed contractor'
                                      : contractor.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.headingBlack,
                                  ),
                                ),
                                if (contractor.mobile.trim().isNotEmpty)
                                  Text(
                                    contractor.mobile,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),

              onChanged: _selectContractor,
            ),
        ],
      ),
    );
  }

  Widget _buildDatePresets() {
    Widget chip(String label, _DatePreset preset) {
      final selected = _datePreset == preset;

      return FilterChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primaryRed : AppColors.textDark,
          ),
        ),
        selected: selected,
        onSelected: (_) => _applyDatePreset(preset),
        selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
        checkmarkColor: AppColors.primaryRed,
        backgroundColor: AppColors.cardWhite,
        side: BorderSide(
          color: selected
              ? AppColors.primaryRed.withValues(alpha: 0.4)
              : AppColors.borderGray.withValues(alpha: 0.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Today', _DatePreset.today),
        chip('This Week', _DatePreset.thisWeek),
        chip('This Month', _DatePreset.thisMonth),
        chip('Custom', _DatePreset.custom),
      ],
    );
  }

  Widget _buildDateSection() {
    final start = _dateCard(
      label: 'Start date',
      value: _fmtDate(_startDate),
      onTap: () => _pickDate(isStart: true),
    );

    final end = _dateCard(
      label: 'End date',
      value: _fmtDate(_endDate),
      onTap: () => _pickDate(isStart: false),
    );

    if (_isWide) {
      return Row(
        children: [
          Expanded(child: start),
          const SizedBox(width: 12),
          Expanded(child: end),
        ],
      );
    }

    return Column(children: [start, const SizedBox(height: 10), end]);
  }

  Widget _dateCard({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderGray.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headingBlack,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final searchBtn = SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _searching ? null : _onSearch,
        icon: _searching
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.search_rounded, size: 18),
        label: Text(
          'Search',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );

    final clearBtn = SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _onClear,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(
          'Clear',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.8)),
          backgroundColor: AppColors.cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );

    if (_isWide) {
      return Row(
        children: [
          Expanded(child: searchBtn),
          const SizedBox(width: 12),
          Expanded(child: clearBtn),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchBtn),
        const SizedBox(width: 10),
        Expanded(child: clearBtn),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final rates = _rates ?? const _AttendanceRates();

    final total = _totalRow;
    final amount = _amountRow;

    final width = MediaQuery.sizeOf(context).width;

    final isCompact = width < 420;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReportBanner(),

          ..._rows.asMap().entries.map((entry) {
            final isLastDay = entry.key == _rows.length - 1;

            return _buildDayRow(entry.value, showDivider: !isLastDay);
          }),

          _buildSummarySection(
            rates: rates,
            total: total,
            amount: amount,
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildReportBanner() {
    final range =
        '${DateFormat('dd MMM').format(_startDate!)} – '
        '${DateFormat('dd MMM yyyy').format(_endDate!)}';

    return Container(
      padding: EdgeInsets.fromLTRB(
        _isWide ? 20 : 16,
        16,
        _isWide ? 20 : 16,
        16,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATTENDANCE REPORT',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedContractor?.name ?? 'Contractor',
                  style: GoogleFonts.poppins(
                    fontSize: _isWide ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  range,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderGray.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '${_rows.length} ${_rows.length == 1 ? 'day' : 'days'}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(_AttendanceDayRow row, {required bool showDivider}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _isWide ? 20 : 16,
        16,
        _isWide ? 20 : 16,
        16,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: AppColors.borderGray.withValues(alpha: 0.3),
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(row.date),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingBlack,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEE').format(row.date).toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildValueStrip(
            labels: const ['Mason', 'Beldar', 'Coolie'],
            values: [row.mason, row.beldar, row.coolie],
          ),
          const SizedBox(height: 10),
          _buildValueStrip(
            labels: const ['Mason OT', 'Beldar OT', 'Coolie OT'],
            values: [row.masonOver, row.beldarOver, row.coolieOver],
            muted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildValueStrip({
    required List<String> labels,
    required List<int> values,
    bool muted = false,
  }) {
    return Row(
      children: List.generate(labels.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels[i],
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${values[i]}',
                  style: GoogleFonts.poppins(
                    fontSize: muted ? 15 : 20,
                    fontWeight: FontWeight.w700,
                    color: muted ? AppColors.textDark : AppColors.headingBlack,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummarySection({
    required _AttendanceRates rates,
    required _AttendanceDayRow total,
    required _AttendanceDayRow amount,
    required bool isCompact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        _isWide ? 20 : 16,
        18,
        _isWide ? 20 : 16,
        18,
      ),
      color: AppColors.operationsCardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUMMARY',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.primaryRed,
            ),
          ),
          const SizedBox(height: 14),
          if (isCompact) ...[
            _buildCompactSummaryBlock(
              title: 'Workers',
              columns: const ['Mason', 'Beldar', 'Coolie'],
              total: [total.mason, total.beldar, total.coolie],
              rate: [
                rates.mason.round(),
                rates.beldar.round(),
                rates.coolie.round(),
              ],
              amount: [amount.mason, amount.beldar, amount.coolie],
            ),
            const SizedBox(height: 14),
            _buildCompactSummaryBlock(
              title: 'Overtime',
              columns: const ['Mason', 'Beldar', 'Coolie'],
              total: [total.masonOver, total.beldarOver, total.coolieOver],
              rate: [
                rates.masonOver.round(),
                rates.beldarOver.round(),
                rates.coolieOver.round(),
              ],
              amount: [amount.masonOver, amount.beldarOver, amount.coolieOver],
            ),
          ] else
            _buildWideSummaryMatrix(rates: rates, total: total, amount: amount),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryBlock({
    required String title,
    required List<String> columns,
    required List<int> total,
    required List<int> rate,
    required List<int> amount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 12),
          _summaryHeaderRow(['', ...columns]),
          const SizedBox(height: 8),
          _summaryDataRow('Total', total, highlight: true),
          const SizedBox(height: 6),
          _summaryDataRow('Rate', rate),
          const SizedBox(height: 6),
          _summaryDataRow('Amount', amount),
        ],
      ),
    );
  }

  Widget _buildWideSummaryMatrix({
    required _AttendanceRates rates,
    required _AttendanceDayRow total,
    required _AttendanceDayRow amount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          _summaryHeaderRow(const [
            '',
            'Mason',
            'Beldar',
            'Coolie',
            'Mason OT',
            'Beldar OT',
            'Coolie OT',
          ]),
          const SizedBox(height: 10),
          _summaryDataRow('Total', [
            total.mason,
            total.beldar,
            total.coolie,
            total.masonOver,
            total.beldarOver,
            total.coolieOver,
          ], highlight: true),
          const SizedBox(height: 8),
          _summaryDataRow('Rate', [
            rates.mason.round(),
            rates.beldar.round(),
            rates.coolie.round(),
            rates.masonOver.round(),
            rates.beldarOver.round(),
            rates.coolieOver.round(),
          ]),
          const SizedBox(height: 8),
          _summaryDataRow('Amount', [
            amount.mason,
            amount.beldar,
            amount.coolie,
            amount.masonOver,
            amount.beldarOver,
            amount.coolieOver,
          ]),
        ],
      ),
    );
  }

  Widget _summaryHeaderRow(List<String> cells) {
    return Row(
      children: List.generate(cells.length, (i) {
        return Expanded(
          flex: i == 0 ? 11 : 10,
          child: Text(
            cells[i],
            textAlign: i == 0 ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }),
    );
  }

  Widget _summaryDataRow(
    String label,
    List<int> values, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryRed.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: highlight
                    ? AppColors.primaryRed
                    : AppColors.headingBlack,
              ),
            ),
          ),
          ...values.map(
            (value) => Expanded(
              flex: 10,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.headingBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceDayRow {
  const _AttendanceDayRow({
    required this.date,
    required this.mason,
    required this.beldar,
    required this.coolie,
    required this.masonOver,
    required this.beldarOver,
    required this.coolieOver,
  });

  final DateTime date;

  final int mason;
  final int beldar;
  final int coolie;

  final int masonOver;
  final int beldarOver;
  final int coolieOver;
}

class _AttendanceRates {
  const _AttendanceRates({
    this.mason = 0,
    this.beldar = 0,
    this.coolie = 0,
    this.masonOver = 0,
    this.beldarOver = 0,
    this.coolieOver = 0,
  });

  final double mason;
  final double beldar;
  final double coolie;

  final double masonOver;
  final double beldarOver;
  final double coolieOver;
}
