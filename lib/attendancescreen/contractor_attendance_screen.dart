import 'dart:async';

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
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  List<LabourContractor> _contractors = [];
  List<LabourContractor> _suggestions = [];
  String? _selectedContractorId;
  DateTime? _startDate;
  DateTime? _endDate;
  _DatePreset _datePreset = _DatePreset.thisMonth;

  bool _loadingContractors = true;
  bool _showSuggestions = false;
  bool _suppressSearchListener = false;
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
    _endDate = now;
    _searchController.addListener(_onSearchTextChanged);
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        // Delay hide so tap on suggestion still registers.
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (mounted && !_searchFocus.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContractors());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  bool get _isWide => MediaQuery.sizeOf(context).width >= 700;

  // bool get _hasData => _hasSearched && _rows.isNotEmpty;

  LabourContractor? get _selectedContractor {
    final id = _selectedContractorId;
    if (id == null) return null;
    for (final c in _contractors) {
      if (c.id == id) return c;
    }
    return null;
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Select date';
    return DateFormat('dd MMM yyyy').format(d);
  }

  int get _activeFilterCount => _publishedOnly ? 1 : 0;

  List<LabourContractor> _matchContractors(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _contractors.where((c) {
      if (_publishedOnly && c.status != ContractorStatus.published) {
        return false;
      }
      final name = c.name.toLowerCase();
      final mobile = c.mobile.toLowerCase().replaceAll(' ', '');
      final qMobile = q.replaceAll(' ', '');
      return name.contains(q) || mobile.contains(qMobile);
    }).toList();
  }

  Future<void> _applyDatePreset(_DatePreset preset) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end = today;

    switch (preset) {
      case _DatePreset.today:
        start = today;
      case _DatePreset.thisWeek:
        start = today.subtract(Duration(days: today.weekday - 1));
      case _DatePreset.thisMonth:
        start = DateTime(today.year, today.month, 1);
      case _DatePreset.custom:
        setState(() => _datePreset = _DatePreset.custom);
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

  void _onSearchTextChanged() {
    if (_suppressSearchListener) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      final q = _searchController.text.trim();
      setState(() {
        if (q.isEmpty) {
          _suggestions = [];
          _showSuggestions = false;
          if (_selectedContractorId != null) {
            _selectedContractorId = null;
            _hasSearched = false;
            _rows = [];
            _rates = null;
            _apiTotals = null;
            _apiAmounts = null;
          }
        } else {
          _suggestions = _matchContractors(q);
          _showSuggestions = true;
        }
      });
    });
  }

  void _setSearchText(String value) {
    _suppressSearchListener = true;
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(offset: value.length);
    _suppressSearchListener = false;
  }

  Future<void> _loadContractors() async {
    setState(() => _loadingContractors = true);
    final response = await getContractorListApi(context, perPage: 100);
    if (!mounted) return;
    setState(() {
      _contractors =
          response?.data?.items?.map(_toContractor).toList() ?? [];
      _loadingContractors = false;
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

  void _selectContractor(LabourContractor contractor) {
    _debounce?.cancel();
    setState(() {
      _selectedContractorId = contractor.id;
      _suggestions = [];
      _showSuggestions = false;
      _hasSearched = false;
      _rows = [];
      _rates = null;
      _apiTotals = null;
      _apiAmounts = null;
    });
    _setSearchText(contractor.name);
    _searchFocus.unfocus();
  }

  void _clearSelectedContractor() {
    _debounce?.cancel();
    setState(() {
      _selectedContractorId = null;
      _suggestions = [];
      _showSuggestions = false;
      _hasSearched = false;
      _rows = [];
      _rates = null;
      _apiTotals = null;
      _apiAmounts = null;
    });
    _setSearchText('');
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
    if (picked == null || !mounted) return;

    final shouldRefresh =
        _hasSearched && _selectedContractor != null && !_searching;

    setState(() {
      _datePreset = _DatePreset.custom;
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day);
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
    if (_selectedContractor == null) {
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
      _showSuggestions = false;
    });
    _searchFocus.unfocus();

    final c = _selectedContractor!;
    final report = await getLabourAttendanceReportApi(
      context,
      siteId: siteId.toString(),
      contractorId: c.id,
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
    final rows = (data?.items ?? [])
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
        mason: apiRates?.mason ?? c.masonRatePerDay,
        beldar: apiRates?.beldar ?? c.beldarRatePerDay,
        coolie: apiRates?.coolie ?? c.coolieRatePerDay,
        masonOver: apiRates?.masonOver ?? c.masonOtRatePerHour,
        beldarOver: apiRates?.beldarOver ?? c.beldarOtRatePerHour,
        coolieOver: apiRates?.coolieOver ?? c.coolieOtRatePerHour,
      );
      _apiTotals = data?.totals;
      _apiAmounts = data?.amounts;
      _rows = rows;
      _searching = false;
    });
  }

  void _onClear() {
    final now = DateTime.now();
    _debounce?.cancel();
    setState(() {
      _selectedContractorId = null;
      _suggestions = [];
      _showSuggestions = false;
      _datePreset = _DatePreset.thisMonth;
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
      _hasSearched = false;
      _rows = [];
      _rates = null;
      _apiTotals = null;
      _apiAmounts = null;
      _searching = false;
      _publishedOnly = false;
    });
    _setSearchText('');
    _searchFocus.unfocus();
  }

  // void _onExport(String type) => _showMsg('Export $type coming soon.');

  void _showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: GoogleFonts.poppins())),
    );
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
      mason: _rows.fold(0, (s, r) => s + r.mason),
      beldar: _rows.fold(0, (s, r) => s + r.beldar),
      coolie: _rows.fold(0, (s, r) => s + r.coolie),
      masonOver: _rows.fold(0, (s, r) => s + r.masonOver),
      beldarOver: _rows.fold(0, (s, r) => s + r.beldarOver),
      coolieOver: _rows.fold(0, (s, r) => s + r.coolieOver),
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
                  _buildSearchAndFilterRow(),
                  if (_showSuggestions) ...[
                    const SizedBox(height: 8),
                    _buildSuggestionsPanel(),
                  ],
                  if (_selectedContractor != null && !_showSuggestions) ...[
                    const SizedBox(height: 10),
                    _buildSelectedChip(),
                  ],
                  const SizedBox(height: 14),
                  _buildDatePresets(),
                  const SizedBox(height: 10),
                  _buildDateSection(),
                  const SizedBox(height: 14),
                  _buildActionButtons(),
                  // Export PDF / Excel — enable when functionality is ready.
                  // if (_hasData) ...[
                  //   const SizedBox(height: 10),
                  //   _buildExportButtons(),
                  // ],
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
                          'Search a contractor, set dates, then tap Search.',
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

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: [
        Expanded(child: _buildSearchField()),
        const SizedBox(width: 10),
        _buildOptionsButton(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.55)),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
        onTap: () {
          final q = _searchController.text.trim();
          if (q.isNotEmpty) {
            setState(() {
              _suggestions = _matchContractors(q);
              _showSuggestions = true;
            });
          }
        },
        decoration: InputDecoration(
          hintText: 'Search by name or mobile…',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.inputHint,
          ),
          prefixIcon: _loadingContractors
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryRed,
                    ),
                  ),
                )
              : const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: _clearSelectedContractor,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsPanel() {
    if (_suggestions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
        ),
        child: Text(
          'No contractor found.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppColors.borderGray.withValues(alpha: 0.35),
        ),
        itemBuilder: (context, index) {
          final c = _suggestions[index];
          final selected = c.id == _selectedContractorId;
          return InkWell(
            onTap: () => _selectContractor(c),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                    child: Text(
                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: AppColors.headingBlack,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (c.mobile.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            c.mobile,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.primaryRed,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedChip() {
    final name = _selectedContractor?.name ?? '';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.primaryRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryRed.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: AppColors.primaryRed,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.55,
              ),
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryRed,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: _clearSelectedContractor,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildOptionsButton() {
    final active = _publishedOnly;
    return Material(
      color: active ? AppColors.primaryRed : AppColors.cardWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _showFilterSheet,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppColors.primaryRed
                  : AppColors.borderGray.withValues(alpha: 0.6),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: active ? AppColors.white : AppColors.textDark,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryRed,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    var draftPublishedOnly = _publishedOnly;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Attendance filters',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.headingBlack,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.operationsCardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Published contractors only',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.headingBlack,
                            ),
                          ),
                          subtitle: Text(
                            'Hide unpublished names in search results',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          value: draftPublishedOnly,
                          activeThumbColor: AppColors.primaryRed,
                          onChanged: (v) =>
                              setSheetState(() => draftPublishedOnly = v),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final publishedChanged =
                                    draftPublishedOnly != _publishedOnly;
                                setState(() {
                                  _publishedOnly = draftPublishedOnly;
                                  if (publishedChanged &&
                                      _searchController.text
                                          .trim()
                                          .isNotEmpty) {
                                    _suggestions = _matchContractors(
                                      _searchController.text,
                                    );
                                  }
                                });
                                Navigator.pop(sheetContext);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Apply',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

    return Column(
      children: [
        start,
        const SizedBox(height: 10),
        end,
      ],
    );
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
        icon: const Icon(Icons.search_rounded, size: 18),
        label: Text(
          'Search',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // Export PDF / Excel — uncomment when export is implemented.
  // Widget _buildExportButtons() {
  //   Widget btn(String label, IconData icon, VoidCallback onTap) {
  //     return SizedBox(
  //       height: 42,
  //       child: ElevatedButton.icon(
  //         onPressed: onTap,
  //         icon: Icon(icon, size: 16),
  //         label: Text(
  //           label,
  //           style: GoogleFonts.poppins(
  //             fontSize: 12,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //         style: ElevatedButton.styleFrom(
  //           elevation: 0,
  //           backgroundColor: AppColors.headingBlack,
  //           foregroundColor: AppColors.white,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  //
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: btn(
  //           'Export PDF',
  //           Icons.picture_as_pdf_outlined,
  //           () => _onExport('PDF'),
  //         ),
  //       ),
  //       const SizedBox(width: 10),
  //       Expanded(
  //         child: btn(
  //           'Export Excel',
  //           Icons.grid_on_outlined,
  //           () => _onExport('Excel'),
  //         ),
  //       ),
  //     ],
  //   );
  // }

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
        '${DateFormat('dd MMM').format(_startDate!)} – ${DateFormat('dd MMM yyyy').format(_endDate!)}';

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
                    color: muted
                        ? AppColors.textDark
                        : AppColors.headingBlack,
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
            _buildWideSummaryMatrix(
              rates: rates,
              total: total,
              amount: amount,
            ),
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
          _summaryDataRow(
            'Total',
            [
              total.mason,
              total.beldar,
              total.coolie,
              total.masonOver,
              total.beldarOver,
              total.coolieOver,
            ],
            highlight: true,
          ),
          const SizedBox(height: 8),
          _summaryDataRow(
            'Rate',
            [
              rates.mason.round(),
              rates.beldar.round(),
              rates.coolie.round(),
              rates.masonOver.round(),
              rates.beldarOver.round(),
              rates.coolieOver.round(),
            ],
          ),
          const SizedBox(height: 8),
          _summaryDataRow(
            'Amount',
            [
              amount.mason,
              amount.beldar,
              amount.coolie,
              amount.masonOver,
              amount.beldarOver,
              amount.coolieOver,
            ],
          ),
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
                color: highlight ? AppColors.primaryRed : AppColors.headingBlack,
              ),
            ),
          ),
          ...values.map(
            (v) => Expanded(
              flex: 10,
              child: Text(
                '$v',
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
