import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/AmaniLabour/add_amani_labour_screen.dart';
import 'package:grjoffice_apps/AmaniLabour/amani_labour.dart';
import 'package:grjoffice_apps/AmaniLabour/view_amani_labour_screen.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/models/listcontractor.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/permission_gate.dart';

enum _ContractorStatusFilter { all, published, unpublished }

enum _ContractorSort {
  nameAsc,
  masonRateAsc,
  masonRateDesc,
}

class ContractorsScreen extends StatefulWidget {
  const ContractorsScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ContractorsScreen> createState() => _ContractorsScreenState();
}

class _ContractorsScreenState extends State<ContractorsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _searchQuery = '';
  List<LabourContractor> _contractors = [];
  bool _isLoading = false;
  bool _startedLoad = false;

  _ContractorStatusFilter _statusFilter = _ContractorStatusFilter.all;
  _ContractorSort _sort = _ContractorSort.nameAsc;
  double? _masonMinRate;
  double? _masonMaxRate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scheduleInitialLoad();
  }

  @override
  void didUpdateWidget(ContractorsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleInitialLoad();
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    setState(() => _searchQuery = q.toLowerCase());
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _loadContractors(showLoader: false, search: q);
    });
  }

  void _scheduleInitialLoad() {
    if (_startedLoad) return;
    _startedLoad = true;
    setState(() => _isLoading = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadContractors();
    });
  }

  Future<void> _loadContractors({
    bool showLoader = true,
    String? search,
  }) async {
    if (showLoader && !_isLoading) setState(() => _isLoading = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final response = await getContractorListApi(
      context,
      search: search ?? _searchController.text.trim(),
      perPage: 100,
    );
    if (!mounted) return;
    setState(() {
      _contractors = response?.data?.items?.map(_toContractor).toList() ?? [];
      _isLoading = false;
    });
  }

  LabourContractor _toContractor(ContractorListItem item) {
    return LabourContractor(
      id: (item.id ?? 0).toString(),
      name: item.name ?? '',
      mobile: item.mobile ?? '',
      address: item.address ?? '',
      remarks: item.remarks ?? '',
      masonRatePerDay: item.masonRateValue,
      beldarRatePerDay: item.beldarRateValue,
      coolieRatePerDay: item.coolieRateValue,
      masonOtRatePerHour: item.masonOverRateValue,
      beldarOtRatePerHour: item.beldarOverRateValue,
      coolieOtRatePerHour: item.coolieOverRateValue,
      status: item.status == 'published'
          ? ContractorStatus.published
          : ContractorStatus.unpublished,
      agreements: item.agreements ?? const [],
      documents: item.documents ?? const [],
      cancelCheque: item.cancelCheque,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  bool get _hasRateFilter => _masonMinRate != null || _masonMaxRate != null;

  bool get _hasActiveFilters =>
      _statusFilter != _ContractorStatusFilter.all ||
      _hasRateFilter ||
      _sort != _ContractorSort.nameAsc;

  int get _activeFilterCount {
    var n = 0;
    if (_statusFilter != _ContractorStatusFilter.all) n++;
    if (_hasRateFilter) n++;
    if (_sort != _ContractorSort.nameAsc) n++;
    return n;
  }

  List<LabourContractor> get _filteredContractors {
    final list = _contractors.where((c) {
      if (_statusFilter == _ContractorStatusFilter.published &&
          c.status != ContractorStatus.published) {
        return false;
      }
      if (_statusFilter == _ContractorStatusFilter.unpublished &&
          c.status != ContractorStatus.unpublished) {
        return false;
      }
      if (_masonMinRate != null && c.masonRatePerDay < _masonMinRate!) {
        return false;
      }
      if (_masonMaxRate != null && c.masonRatePerDay > _masonMaxRate!) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final haystack = '${c.name} ${c.mobile} ${c.address}'.toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case _ContractorSort.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _ContractorSort.masonRateAsc:
          return a.masonRatePerDay.compareTo(b.masonRatePerDay);
        case _ContractorSort.masonRateDesc:
          return b.masonRatePerDay.compareTo(a.masonRatePerDay);
      }
    });
    return list;
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = _ContractorStatusFilter.all;
      _sort = _ContractorSort.nameAsc;
      _masonMinRate = null;
      _masonMaxRate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.labourContractors,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Amani Labour List',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () => _loadContractors(showLoader: false),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSearchAndFilterRow(),
                                if (_hasActiveFilters) ...[
                                  const SizedBox(height: 10),
                                  _buildActiveFilterChips(),
                                ],
                                const SizedBox(height: 12),
                                _buildCreateButton(),
                                const SizedBox(height: 16),
                                ..._filteredContractors
                                    .map(_buildContractorCard),
                                if (_filteredContractors.isEmpty)
                                  _buildEmptyState(),
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

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }

  Future<void> _openCreate() async {
    final result = await Navigator.of(context).push<LabourContractor>(
      MaterialPageRoute(builder: (_) => const AddContractorScreen()),
    );
    if (result != null && mounted) {
      setState(() => _contractors.add(result));
    }
  }

  void _openViewContractor(LabourContractor contractor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ViewContractorScreen(contractor: contractor),
      ),
    );
  }

  Future<void> _editContractor(LabourContractor contractor) async {
    final result = await Navigator.of(context).push<LabourContractor>(
      MaterialPageRoute(
        builder: (_) => AddContractorScreen(contractor: contractor),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        final index = _contractors.indexWhere((c) => c.id == contractor.id);
        if (index != -1) _contractors[index] = result;
      });
    }
    await _loadContractors();
  }

  Future<void> _confirmDelete(LabourContractor contractor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Amani Labour',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${contractor.name}"?',
          style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final contractorId = int.tryParse(contractor.id);
    if (contractorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid contractor id.')),
      );
      return;
    }

    final deleted = await deleteContractorApi(context, contractorId);
    if (!mounted || !deleted) return;

    setState(() => _contractors.removeWhere((c) => c.id == contractor.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${contractor.name} deleted successfully.')),
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: [
        Expanded(child: _buildSearchBar()),
        const SizedBox(width: 10),
        _buildFilterButton(),
      ],
    );
  }

  Widget _buildFilterButton() {
    final active = _hasActiveFilters;
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
                color: active ? AppColors.white : AppColors.textDark,
                size: 22,
              ),
              if (active)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryRed,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
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

  Widget _buildActiveFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_statusFilter != _ContractorStatusFilter.all)
          _activeChip(
            'Status: ${_statusLabel(_statusFilter)}',
            () => setState(
              () => _statusFilter = _ContractorStatusFilter.all,
            ),
          ),
        if (_hasRateFilter)
          _activeChip(
            'Mason: ${_rateRangeLabel(_masonMinRate, _masonMaxRate)}',
            () => setState(() {
              _masonMinRate = null;
              _masonMaxRate = null;
            }),
          ),
        if (_sort != _ContractorSort.nameAsc)
          _activeChip(
            'Sort: ${_sortLabel(_sort)}',
            () => setState(() => _sort = _ContractorSort.nameAsc),
          ),
        _activeChip('Clear all', _clearFilters, showDelete: false),
      ],
    );
  }

  Widget _activeChip(
    String label,
    VoidCallback onTap, {
    bool showDelete = true,
  }) {
    return InputChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryRed),
      ),
      deleteIcon: showDelete
          ? const Icon(Icons.close, size: 16, color: AppColors.primaryRed)
          : null,
      onDeleted: showDelete ? onTap : null,
      onPressed: showDelete ? null : onTap,
      backgroundColor: AppColors.primaryRed.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.25)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showFilterSheet() {
    var draftStatus = _statusFilter;
    var draftSort = _sort;
    var draftMin = _masonMinRate;
    var draftMax = _masonMaxRate;
    final minController = TextEditingController(
      text: draftMin?.toInt().toString() ?? '',
    );
    final maxController = TextEditingController(
      text: draftMax?.toInt().toString() ?? '',
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void syncRateFromFields() {
              draftMin = double.tryParse(minController.text.trim());
              draftMax = double.tryParse(maxController.text.trim());
            }

            void applyRatePreset(double? min, double? max) {
              setSheetState(() {
                draftMin = min;
                draftMax = max;
                minController.text = min?.toInt().toString() ?? '';
                maxController.text = max?.toInt().toString() ?? '';
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                        child: Row(
                          children: [
                            Text(
                              'Filters',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.headingBlack,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  draftStatus = _ContractorStatusFilter.all;
                                  draftSort = _ContractorSort.nameAsc;
                                  draftMin = null;
                                  draftMax = null;
                                  minController.clear();
                                  maxController.clear();
                                });
                              },
                              child: Text(
                                'Reset',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _filterSection(
                                'Status',
                                Icons.flag_outlined,
                                [
                                  _filterChip(
                                    'All',
                                    draftStatus ==
                                        _ContractorStatusFilter.all,
                                    () => setSheetState(
                                      () => draftStatus =
                                          _ContractorStatusFilter.all,
                                    ),
                                  ),
                                  _filterChip(
                                    'Published',
                                    draftStatus ==
                                        _ContractorStatusFilter.published,
                                    () => setSheetState(
                                      () => draftStatus =
                                          _ContractorStatusFilter.published,
                                    ),
                                  ),
                                  _filterChip(
                                    'Unpublished',
                                    draftStatus ==
                                        _ContractorStatusFilter.unpublished,
                                    () => setSheetState(
                                      () => draftStatus =
                                          _ContractorStatusFilter
                                              .unpublished,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _filterSection(
                                'Mason rate / day',
                                Icons.currency_rupee_rounded,
                                [
                                  _filterChip(
                                    'Any',
                                    draftMin == null && draftMax == null,
                                    () => applyRatePreset(null, null),
                                  ),
                                  _filterChip(
                                    'Under ₹700',
                                    draftMin == null && draftMax == 700,
                                    () => applyRatePreset(null, 700),
                                  ),
                                  _filterChip(
                                    '₹700 – ₹900',
                                    draftMin == 700 && draftMax == 900,
                                    () => applyRatePreset(700, 900),
                                  ),
                                  _filterChip(
                                    'Above ₹900',
                                    draftMin == 900 && draftMax == null,
                                    () => applyRatePreset(900, null),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _rateField(
                                      controller: minController,
                                      label: 'Min ₹',
                                      onChanged: (_) => setSheetState(
                                        syncRateFromFields,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _rateField(
                                      controller: maxController,
                                      label: 'Max ₹',
                                      onChanged: (_) => setSheetState(
                                        syncRateFromFields,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _filterSection(
                                'Sort by',
                                Icons.sort_rounded,
                                [
                                  _filterChip(
                                    'Name A–Z',
                                    draftSort == _ContractorSort.nameAsc,
                                    () => setSheetState(
                                      () => draftSort =
                                          _ContractorSort.nameAsc,
                                    ),
                                  ),
                                  _filterChip(
                                    'Mason rate ↑',
                                    draftSort ==
                                        _ContractorSort.masonRateAsc,
                                    () => setSheetState(
                                      () => draftSort =
                                          _ContractorSort.masonRateAsc,
                                    ),
                                  ),
                                  _filterChip(
                                    'Mason rate ↓',
                                    draftSort ==
                                        _ContractorSort.masonRateDesc,
                                    () => setSheetState(
                                      () => draftSort =
                                          _ContractorSort.masonRateDesc,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.pop(sheetContext),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  side: BorderSide(
                                    color: AppColors.borderGray
                                        .withValues(alpha: 0.7),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  syncRateFromFields();
                                  if (draftMin != null &&
                                      draftMax != null &&
                                      draftMin! > draftMax!) {
                                    final t = draftMin;
                                    draftMin = draftMax;
                                    draftMax = t;
                                  }
                                  setState(() {
                                    _statusFilter = draftStatus;
                                    _sort = draftSort;
                                    _masonMinRate = draftMin;
                                    _masonMaxRate = draftMax;
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
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      minController.dispose();
      maxController.dispose();
    });
  }

  Widget _rateField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.6),
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
    );
  }

  Widget _filterSection(String title, IconData icon, List<Widget> chips) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.operationsCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryRed),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
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
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryRed,
      backgroundColor: AppColors.cardWhite,
      side: BorderSide(
        color: selected
            ? AppColors.primaryRed.withValues(alpha: 0.4)
            : AppColors.borderGray.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  String _statusLabel(_ContractorStatusFilter filter) => switch (filter) {
        _ContractorStatusFilter.all => 'All',
        _ContractorStatusFilter.published => 'Published',
        _ContractorStatusFilter.unpublished => 'Unpublished',
      };

  String _sortLabel(_ContractorSort sort) => switch (sort) {
        _ContractorSort.nameAsc => 'Name A–Z',
        _ContractorSort.masonRateAsc => 'Mason rate ↑',
        _ContractorSort.masonRateDesc => 'Mason rate ↓',
      };

  String _rateRangeLabel(double? min, double? max) {
    if (min == null && max == null) return 'Any';
    if (min == null) return '≤ ₹${max!.toInt()}';
    if (max == null) return '≥ ₹${min.toInt()}';
    return '₹${min.toInt()} – ₹${max.toInt()}';
  }

  Widget _buildCardActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = AppColors.primaryRed,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 22),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
    );
  }

  Widget _buildCreateButton() {
    return PermissionGate(
      permission: AppPermissions.contractorsCreate,
      child: SizedBox(
        height: 46,
        child: ElevatedButton.icon(
          onPressed: _openCreate,
          icon: const Icon(Icons.groups_outlined, size: 20),
          label: Text(
            'Create Amani Labour',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search name, mobile or address…',
        hintStyle: GoogleFonts.poppins(
          color: AppColors.inputHint,
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
          size: 22,
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                onPressed: () => _searchController.clear(),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderGray.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryRed,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildContractorCard(LabourContractor contractor) {
    final isPublished = contractor.status == ContractorStatus.published;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.primaryRed.withValues(alpha: 0.08),
                      ),
                      child: const Icon(
                        Icons.groups_outlined,
                        color: AppColors.primaryRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contractor.name,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.headingBlack,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(isPublished),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contractor.mobile,
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
                const SizedBox(height: 10),
                _buildMetaRow(
                  Icons.location_on_outlined,
                  contractor.address,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                _buildRateSummary(contractor),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderGray.withValues(alpha: 0.4),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                PermissionGate(
                  permission: AppPermissions.contractorsView,
                  child: InkWell(
                    onTap: () => _openViewContractor(contractor),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Amani Labour',
                            style: GoogleFonts.poppins(
                              color: AppColors.primaryRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.primaryRed,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                PermissionGate(
                  permission: AppPermissions.contractorsUpdate,
                  child: _buildCardActionIcon(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit Amani Labour',
                    onTap: () => _editContractor(contractor),
                  ),
                ),
                PermissionGate(
                  permission: AppPermissions.contractorsDelete,
                  child: _buildCardActionIcon(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    onTap: () => _confirmDelete(contractor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateSummary(LabourContractor c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.operationsCardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Rates',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mason ₹${c.masonRatePerDay.toInt()} · Beldar ₹${c.beldarRatePerDay.toInt()} · Coolie ₹${c.coolieRatePerDay.toInt()}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'OT Rates / Hour',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mason ₹${c.masonOtRatePerHour.toInt()} · Beldar ₹${c.beldarOtRatePerHour.toInt()} · Coolie ₹${c.coolieOtRatePerHour.toInt()}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPublished ? 'PUBLISHED' : 'UNPUBLISHED',
        style: GoogleFonts.poppins(
          color: AppColors.primaryRed,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No amani labour found',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_hasActiveFilters || _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _clearFilters();
                _loadContractors(showLoader: false);
              },
              child: Text(
                'Clear filters',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
