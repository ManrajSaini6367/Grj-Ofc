import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/Purchasescreen/add_purchase_screen.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/Purchasescreen/without_kanta_step2_screen.dart';
import 'package:grjoffice_apps/Purchasescreen/with_kanta_step2_screen.dart';
import 'package:grjoffice_apps/Purchasescreen/with_kanta_step3_screen.dart';
import 'package:grjoffice_apps/Purchasescreen/view_purchase_screen.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/services/purchase_image_download_service.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/permission_gate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  PurchaseStatus? _statusFilter;
  String? _supplierFilter;
  _KantaSlipFilter _kantaSlipFilter = _KantaSlipFilter.all;
  _PurchaseDateFilter _dateFilter = _PurchaseDateFilter.all;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  List<Purchase> _purchases = [];
  PurchasesSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPurchases());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final next = _searchController.text.trim().toLowerCase();
    if (next == _searchQuery) return;
    setState(() => _searchQuery = next);
  }

  String get _apiPeriod {
    if (_hasCustomDateRange) return 'all';
    return switch (_dateFilter) {
      _PurchaseDateFilter.all => 'all',
      _PurchaseDateFilter.today => 'today',
      _PurchaseDateFilter.last7 => 'last_7',
      _PurchaseDateFilter.last30 => 'last_30',
      _PurchaseDateFilter.thisMonth => 'this_month',
    };
  }

  String? get _apiStatus => null;

  Future<void> _loadPurchases({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);

    final response = await getPurchasesApi(
      context,
      period: _apiPeriod,
      status: _apiStatus,
      search: '',
      perPage: 15,
      fetchAllPages: true,
    );

    if (!mounted) return;
    setState(() {
      _purchases = response?.data?.items ?? [];
      _summary = response?.data?.summary;
      _isLoading = false;
    });
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  List<Purchase> get _filteredPurchases {
    return _purchases.where((p) {
      if (_statusFilter == PurchaseStatus.cancelled) return false;
      if (_statusFilter == PurchaseStatus.pending &&
          p.status != PurchaseStatus.pending) {
        return false;
      }
      if (_statusFilter == PurchaseStatus.received &&
          p.status != PurchaseStatus.received &&
          p.status != PurchaseStatus.approved) {
        return false;
      }
      if (_statusFilter == PurchaseStatus.approved &&
          p.status != PurchaseStatus.approved) {
        return false;
      }
      if (_supplierFilter != null && p.supplierName != _supplierFilter) return false;
      if (_kantaSlipFilter == _KantaSlipFilter.yes && !p.hasKantaSlip) return false;
      if (_kantaSlipFilter == _KantaSlipFilter.no && p.hasKantaSlip) return false;
      if (!_matchesDateFilter(p.date)) return false;
      if (_searchQuery.isNotEmpty) {
        final haystack =
            '${p.challanNo} ${p.invoiceNo} ${p.supplierName} ${p.vehicleNo ?? ''} ${p.itemName ?? ''} ${p.remark ?? ''} ${p.statusLabel}'
                .toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  bool _matchesDateFilter(DateTime date) {
    if (_hasCustomDateRange) {
      final purchaseDate = DateTime(date.year, date.month, date.day);
      if (_filterStartDate != null) {
        final start = DateTime(_filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day);
        if (purchaseDate.isBefore(start)) return false;
      }
      if (_filterEndDate != null) {
        final end = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day);
        if (purchaseDate.isAfter(end)) return false;
      }
      return true;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final purchaseDate = DateTime(date.year, date.month, date.day);

    switch (_dateFilter) {
      case _PurchaseDateFilter.all:
        return true;
      case _PurchaseDateFilter.today:
        return purchaseDate == today;
      case _PurchaseDateFilter.last7:
        return !purchaseDate.isBefore(today.subtract(const Duration(days: 6)));
      case _PurchaseDateFilter.last30:
        return !purchaseDate.isBefore(today.subtract(const Duration(days: 29)));
      case _PurchaseDateFilter.thisMonth:
        return date.year == now.year && date.month == now.month;
    }
  }

  bool get _hasCustomDateRange => _filterStartDate != null || _filterEndDate != null;

  List<String> get _supplierOptions {
    return _purchases.map((p) => p.supplierName).toSet().toList()..sort();
  }

  bool get _hasNonDateFilters =>
      _statusFilter != null ||
      _supplierFilter != null ||
      _kantaSlipFilter != _KantaSlipFilter.all;

  bool get _hasActiveFilters =>
      _hasNonDateFilters || _hasCustomDateRange || _dateFilter != _PurchaseDateFilter.all;

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _supplierFilter = null;
      _kantaSlipFilter = _KantaSlipFilter.all;
      _dateFilter = _PurchaseDateFilter.all;
      _filterStartDate = null;
      _filterEndDate = null;
    });
    _loadPurchases();
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final rows = _filteredPurchases;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(selectedIndex: DrawerIndex.purchase, onItemTap: _onDrawerItemTap),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar.tab(
              title: 'Purchase List',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToolbar(),
                  const SizedBox(height: 10),
                  _buildDateFilterSection(),
                  if (_hasNonDateFilters) ...[
                    const SizedBox(height: 10),
                    _buildActiveFilterChips(),
                  ],
                  const SizedBox(height: 12),
                  _buildCreateButton(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : RefreshIndicator(
                          color: AppColors.primaryRed,
                          onRefresh: () => _loadPurchases(showLoader: false),
                          child: rows.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
                                    _buildEmptyState(),
                                  ],
                                )
                              : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 16),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 640),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (_summary != null) ...[
                                      _buildSummaryRow(_summary!),
                                      const SizedBox(height: 12),
                                    ],
                                    ...rows.map(_buildPurchaseCard),
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

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 10),
          Material(
            color: _hasActiveFilters
                ? AppColors.primaryRed.withValues(alpha: 0.1)
                : AppColors.operationsCardBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _showFilterSheet,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _hasActiveFilters
                        ? AppColors.primaryRed.withValues(alpha: 0.4)
                        : AppColors.borderGray.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 22,
                  color: _hasActiveFilters ? AppColors.primaryRed : AppColors.textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: 'Search purchases...',
        hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
        filled: true,
        fillColor: AppColors.operationsCardBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.5), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_statusFilter != null)
          _activeChip(_statusLabel(_statusFilter!), () => setState(() => _statusFilter = null)),
        if (_supplierFilter != null)
          _activeChip(_supplierFilter!, () => setState(() => _supplierFilter = null)),
        if (_kantaSlipFilter != _KantaSlipFilter.all)
          _activeChip(
            'Kanta: ${_kantaSlipFilter == _KantaSlipFilter.yes ? 'Yes' : 'No'}',
            () => setState(() => _kantaSlipFilter = _KantaSlipFilter.all),
          ),
        GestureDetector(
          onTap: _clearFilters,
          child: Text(
            'Clear all',
            style: GoogleFonts.poppins(color: AppColors.primaryRed, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // _buildDateFilterChips(),
        const SizedBox(height: 10),
        _buildDateRangeFields(),
      ],
    );
  }

  Widget _buildDateFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _dateFilterChip('All', _PurchaseDateFilter.all),
          const SizedBox(width: 8),
          _dateFilterChip('Today', _PurchaseDateFilter.today),
          const SizedBox(width: 8),
          _dateFilterChip('7 Days', _PurchaseDateFilter.last7),
          const SizedBox(width: 8),
          _dateFilterChip('30 Days', _PurchaseDateFilter.last30),
          const SizedBox(width: 8),
          _dateFilterChip('This Month', _PurchaseDateFilter.thisMonth),
        ],
      ),
    );
  }

  Widget _dateFilterChip(String label, _PurchaseDateFilter value) {
    final selected = !_hasCustomDateRange && _dateFilter == value;
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
      onSelected: (_) {
        setState(() {
          _dateFilter = value;
          _filterStartDate = null;
          _filterEndDate = null;
        });
        _loadPurchases();
      },
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

  Widget _buildDateRangeFields() {
    return Row(
      children: [
        Expanded(
          child: _buildDatePickerField(
            label: 'Start Date',
            date: _filterStartDate,
            onTap: () => _pickFilterDate(isStart: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDatePickerField(
            label: 'End Date',
            date: _filterEndDate,
            onTap: () => _pickFilterDate(isStart: false),
          ),
        ),
        if (_hasCustomDateRange) ...[
          const SizedBox(width: 6),
          IconButton(
            onPressed: () {
              setState(() {
                _filterStartDate = null;
                _filterEndDate = null;
              });
              _loadPurchases();
            },
            icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
            tooltip: 'Clear dates',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final hasDate = date != null;
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasDate
                  ? AppColors.primaryRed.withValues(alpha: 0.4)
                  : AppColors.borderGray.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: hasDate ? AppColors.primaryRed : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      hasDate ? _formatDate(date) : 'Select',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: hasDate ? FontWeight.w600 : FontWeight.w500,
                        color: hasDate ? AppColors.textDark : AppColors.inputHint,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFilterDate({required bool isStart}) async {
    final initial = isStart
        ? (_filterStartDate ?? DateTime.now())
        : (_filterEndDate ?? _filterStartDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;

    if (!isStart && _filterStartDate != null) {
      final start = DateTime(_filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day);
      final end = DateTime(picked.year, picked.month, picked.day);
      if (end.isBefore(start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('End date cannot be before start date.', style: GoogleFonts.poppins())),
        );
        return;
      }
    }

    setState(() {
      _dateFilter = _PurchaseDateFilter.all;
      if (isStart) {
        _filterStartDate = picked;
        if (_filterEndDate != null) {
          final start = DateTime(picked.year, picked.month, picked.day);
          final end = DateTime(_filterEndDate!.year, _filterEndDate!.month, _filterEndDate!.day);
          if (end.isBefore(start)) _filterEndDate = null;
        }
      } else {
        _filterEndDate = picked;
      }
    });
    _loadPurchases();
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return InputChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryRed)),
      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primaryRed),
      onDeleted: onRemove,
      backgroundColor: AppColors.primaryRed.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.25)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderGray.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppColors.primaryRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Filter Purchases',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              _clearFilters();
                              Navigator.pop(context);
                            },
                            child: Text('Clear', style: GoogleFonts.poppins(color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _filterSection('Status', Icons.flag_outlined, [
                      _filterChip('All', _statusFilter == null, () {
                        setState(() => _statusFilter = null);
                        Navigator.pop(context);
                      }),
                      ...PurchaseStatus.values.map((s) => _filterChip(_statusLabel(s), _statusFilter == s, () {
                        setState(() => _statusFilter = s);
                        Navigator.pop(context);
                      })),
                    ]),
                    const SizedBox(height: 16),
                    _filterSection('Date', Icons.date_range_outlined, [
                      ..._PurchaseDateFilter.values.map((f) => _filterChip(
                            f.label,
                            !_hasCustomDateRange && _dateFilter == f,
                            () {
                              setState(() {
                                _dateFilter = f;
                                _filterStartDate = null;
                                _filterEndDate = null;
                              });
                              Navigator.pop(context);
                              _loadPurchases();
                            },
                          )),
                      const SizedBox(height: 12),
                      _buildDateRangeFields(),
                    ]),
                    const SizedBox(height: 16),
                    _filterSection('Kanta Slip', Icons.receipt_long_outlined, [
                      _filterChip('All', _kantaSlipFilter == _KantaSlipFilter.all, () {
                        setState(() => _kantaSlipFilter = _KantaSlipFilter.all);
                        Navigator.pop(context);
                      }),
                      _filterChip('Yes', _kantaSlipFilter == _KantaSlipFilter.yes, () {
                        setState(() => _kantaSlipFilter = _KantaSlipFilter.yes);
                        Navigator.pop(context);
                      }),
                      _filterChip('No', _kantaSlipFilter == _KantaSlipFilter.no, () {
                        setState(() => _kantaSlipFilter = _KantaSlipFilter.no);
                        Navigator.pop(context);
                      }),
                    ]),
                    const SizedBox(height: 16),
                    _filterSection('Supplier', Icons.storefront_outlined, [
                      _filterChip('All', _supplierFilter == null, () {
                        setState(() => _supplierFilter = null);
                        Navigator.pop(context);
                      }),
                      ..._supplierOptions.map((name) => _filterChip(name, _supplierFilter == name, () {
                        setState(() => _supplierFilter = name);
                        Navigator.pop(context);
                      })),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _filterSection(String title, IconData icon, List<Widget> chips) {
    return Container(
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
              Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
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
        color: selected ? AppColors.primaryRed.withValues(alpha: 0.4) : AppColors.borderGray.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  String _statusLabel(PurchaseStatus status) => switch (status) {
        PurchaseStatus.pending => 'Pending',
        PurchaseStatus.approved => 'Approved',
        PurchaseStatus.received => 'Received',
        PurchaseStatus.cancelled => 'Cancelled',
      };

  Future<void> _openAddPurchase() async {
    final result = await Navigator.of(context).push<Purchase>(
      MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
    );
    if (result != null && mounted) {
      final msg = result.withKantaStage == WithKantaStage.initial
          ? 'Purchase saved (Initial). Complete Step 2 from the list.'
          : result.withoutKantaStage == WithoutKantaStage.initial
              ? 'Purchase saved (Initial). Complete Step 2 from the list.'
              : result.isDirectPurchase
                  ? 'Purchase ${result.challanNo} saved (Completed).'
                  : 'Purchase ${result.challanNo} created.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _loadPurchases();
    }
  }

  Widget _buildSummaryRow(PurchasesSummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _summaryCell('Total', summary.total.toString()),
          _summaryCell('Initial', summary.initial.toString()),
          _summaryCell('Processing', summary.processing.toString()),
          _summaryCell('Completed', summary.completed.toString()),
        ],
      ),
    );
  }

  Widget _summaryCell(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return PermissionGate(
      permission: AppPermissions.purchasesCreate,
      child: SizedBox(
        height: 46,
        child: ElevatedButton.icon(
          onPressed: _openAddPurchase,
          icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
          label: Text(
            'Create Purchase',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
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

  Widget _buildPurchaseCard(Purchase purchase) {
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
                        Icons.shopping_cart_outlined,
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
                                  purchase.supplierName,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.headingBlack,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _buildCardBadge(purchase),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            purchase.hasFlowStage
                                ? (purchase.vehicleNo ?? purchase.challanNo)
                                : purchase.challanNo,
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
                if ((purchase.itemName ?? '').isNotEmpty) ...[
                  _buildMetaRow(Icons.inventory_2_outlined, purchase.materialsSummary),
                  const SizedBox(height: 6),
                ],
                if (purchase.withKantaStage != null && purchase.flowStageLabel != null) ...[
                  _buildMetaRow(
                    Icons.flag_outlined,
                    'Status: ${purchase.flowStageLabel}',
                  ),
                  const SizedBox(height: 6),
                ] else if (purchase.withoutKantaStage != null && purchase.flowStageLabel != null) ...[
                  _buildMetaRow(
                    Icons.flag_outlined,
                    'Status: ${purchase.flowStageLabel}',
                  ),
                  const SizedBox(height: 6),
                ] else if (purchase.directPurchaseStage != null && purchase.flowStageLabel != null) ...[
                  _buildMetaRow(
                    Icons.flag_outlined,
                    'Status: ${purchase.flowStageLabel}',
                  ),
                  const SizedBox(height: 6),
                ],
                _buildMetaRow(Icons.calendar_today_outlined, _formatDate(purchase.date)),
                const SizedBox(height: 6),
                _buildMetaRow(Icons.receipt_long_outlined, 'Invoice: ${purchase.invoiceNo}'),
                const SizedBox(height: 6),
                _buildMetaRow(
                  Icons.description_outlined,
                  'Kanta Slip: ${purchase.isDirectPurchase ? 'Direct' : purchase.hasKantaSlip ? 'Yes' : 'No'}',
                ),
                if ((purchase.remark ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildMetaRow(Icons.notes_outlined, purchase.remark!, maxLines: 2),
                ],
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
                if (_cardFlowActionLabel(purchase) != null)
                  InkWell(
                    onTap: () => _openCardFlowAction(purchase),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _cardFlowActionLabel(purchase)!,
                            style: GoogleFonts.poppins(
                              color: AppColors.primaryRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, color: AppColors.primaryRed, size: 18),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => _showDetails(purchase),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Purchase',
                            style: GoogleFonts.poppins(
                              color: AppColors.primaryRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, color: AppColors.primaryRed, size: 18),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showPurchaseMenu(purchase),
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseMenu(Purchase purchase) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final withKantaFlow = purchase.isWithKanta && purchase.withKantaStage != null;
        final withoutKantaFlow = purchase.isWithoutKanta && purchase.withoutKantaStage != null;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (withKantaFlow) ...[
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.textDark),
                  title: Text('View Vehicle Images', style: GoogleFonts.poppins(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    _viewVehicleImages(purchase);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined, color: AppColors.textDark),
                  title: Text('Download Challan', style: GoogleFonts.poppins(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadChallan(purchase);
                  },
                ),
                if (_canOpenWithKantaStep3(purchase))
                  ListTile(
                    leading: const Icon(Icons.playlist_add_check_outlined, color: AppColors.primaryRed),
                    title: Text(
                      'Step 3',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _openWithKantaStep3(purchase);
                    },
                  ),
                if (_canOpenWithKantaStep3(purchase)) const Divider(height: 1),
              ] else if (withoutKantaFlow) ...[
                if (_canOpenStep2(purchase))
                  ListTile(
                    leading: const Icon(Icons.playlist_add_check_outlined, color: AppColors.primaryRed),
                    title: Text(
                      'Step 2',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _openFlowStep2(purchase);
                    },
                  ),
                if (_canOpenStep2(purchase)) const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.textDark),
                title: Text('Edit Purchase', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit ${purchase.challanNo}')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.primaryRed),
                title: Text(
                  'Delete Purchase',
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primaryRed),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(purchase);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _viewVehicleImages(Purchase purchase) async {
    final purchaseId = int.tryParse(purchase.id);
    var detail = purchase;

    if (purchaseId != null) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
        ),
      );
      try {
        final fetched = await getPurchaseApi(context, purchaseId);
        if (fetched != null) detail = fetched;
      } finally {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }

    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _VehicleImagesScreen(purchase: detail),
      ),
    );
  }

  Future<void> _downloadChallan(Purchase purchase) async {
    final purchaseId = int.tryParse(purchase.id);
    var detail = purchase;

    if (purchaseId != null) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
        ),
      );
      try {
        final fetched = await getPurchaseApi(context, purchaseId);
        if (fetched != null) detail = fetched;
      } finally {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }

    if (!mounted) return;

    final challanUrl = resolveChallanWebUrl(detail);
    if (challanUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Challan URL is not available for ${detail.challanNo}.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (isLikelyPdfUrl(challanUrl)) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
        ),
      );
      try {
        final response = await http
            .get(Uri.parse(challanUrl), headers: authHeaders)
            .timeout(const Duration(seconds: 60));
        final bytes = response.bodyBytes;
        final looksPdf = bytes.length >= 4 &&
            String.fromCharCodes(bytes.sublist(0, 4)) == '%PDF';
        if (response.statusCode == 200 && looksPdf) {
          final fileName = PurchaseImageDownloadService.sanitizePdfFileName(
            'challan_${detail.challanNo}.pdf',
          );
          final savedPath = await PurchaseImageDownloadService.downloadToDownloadsFolder(
            bytes: bytes,
            fileName: fileName,
          );
          if (!mounted) return;
          final result = await OpenFilex.open(savedPath);
          if (result.type != ResultType.done) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Saved to Downloads/GRJ_Purchases/$fileName',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('[Challan] pdf download error: $e');
      } finally {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ChallanWebViewPage(
          title: 'Challan — ${detail.challanNo}',
          url: challanUrl,
          challanNo: detail.challanNo,
        ),
      ),
    );
  }
  String? _cardFlowActionLabel(Purchase purchase) {
    final next = purchase.nextAction?.toLowerCase();
    if (next == 'step_2') return 'Step 2';
    if (next == 'step_3') return 'Step 3';
    if (purchase.withoutKantaStage == WithoutKantaStage.initial) return 'Step 2';
    if (purchase.withKantaStage == WithKantaStage.initial) return 'Step 2';
    if (purchase.withKantaStage == WithKantaStage.processing) return 'Step 3';
    return null;
  }

  void _openCardFlowAction(Purchase purchase) {
    final next = purchase.nextAction?.toLowerCase();
    if (next == 'step_3' || purchase.withKantaStage == WithKantaStage.processing) {
      _openWithKantaStep3(purchase);
      return;
    }
    _openFlowStep2(purchase);
  }

  bool _canOpenWithKantaStep3(Purchase purchase) =>
      purchase.nextAction?.toLowerCase() == 'step_3' ||
      purchase.withKantaStage == WithKantaStage.processing;

  bool _canOpenStep2(Purchase purchase) {
    if (purchase.nextAction?.toLowerCase() == 'step_2') return true;
    if (purchase.withoutKantaStage == WithoutKantaStage.initial) return true;
    if (purchase.withKantaStage == WithKantaStage.initial) return true;
    return false;
  }

  Future<void> _openFlowStep2(Purchase purchase) async {
    if (purchase.isWithoutKanta) {
      await _openWithoutKantaStep2(purchase);
      return;
    }
    await _openWithKantaStep2(purchase);
  }

  Future<void> _openWithKantaStep2(Purchase purchase) async {
    final updated = await Navigator.of(context).push<Purchase>(
      MaterialPageRoute(builder: (_) => WithKantaStep2Screen(purchase: purchase)),
    );
    if (updated == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Step 2 saved. Complete Step 3 from the list.')),
    );
    await _loadPurchases();
  }

  Future<void> _openWithKantaStep3(Purchase purchase) async {
    final updated = await Navigator.of(context).push<Purchase>(
      MaterialPageRoute(builder: (_) => WithKantaStep3Screen(purchase: purchase)),
    );
    if (updated == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Purchase ${updated.challanNo} marked completed.')),
    );
    await _loadPurchases();
  }

  Future<void> _openWithoutKantaStep2(Purchase purchase) async {
    final updated = await Navigator.of(context).push<Purchase>(
      MaterialPageRoute(builder: (_) => WithoutKantaStep2Screen(purchase: purchase)),
    );
    if (updated == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Purchase ${updated.challanNo} marked completed.')),
    );
    await _loadPurchases();
  }

  Widget _buildCardBadge(Purchase purchase) {
    if (purchase.withKantaStage != null) {
      return _buildFlowStageBadge(purchase.withKantaStageLabel!);
    }
    if (purchase.withoutKantaStage != null) {
      return _buildFlowStageBadge(purchase.withoutKantaStageLabel!);
    }
    if (purchase.directPurchaseStage != null) {
      return _buildFlowStageBadge(purchase.directPurchaseStageLabel!);
    }
    return _buildStatusBadge(purchase.status);
  }

  Widget _buildFlowStageBadge(String label) {
    final normalized = label.toLowerCase();
    final color = switch (normalized) {
      'initial' => const Color(0xFFD97706),
      'processing' => const Color(0xFF2563EB),
      'completed' => const Color(0xFF059669),
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PurchaseStatus status) {
    final color = switch (status) {
      PurchaseStatus.pending => const Color(0xFFD97706),
      PurchaseStatus.approved => const Color(0xFF2563EB),
      PurchaseStatus.received => AppColors.primaryRed,
      PurchaseStatus.cancelled => const Color(0xFFDC2626),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status).toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
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
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _showDetails(Purchase purchase) async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(builder: (_) => ViewPurchaseScreen(purchase: purchase)),
    );
    if (!mounted || result == null) return;

    if (result == 'deleted') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase "${purchase.challanNo}" deleted')),
      );
      await _loadPurchases();
    }
  }

  Future<void> _confirmDelete(Purchase purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete Purchase', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete purchase "${purchase.challanNo}"?',
          style: GoogleFonts.poppins(fontSize: 14),
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
              style: GoogleFonts.poppins(color: AppColors.primaryRed, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final purchaseId = int.tryParse(purchase.id);
    if (purchaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid purchase id.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final ok = await deletePurchaseApi(context, purchaseId);
    if (!mounted || !ok) return;

    setState(() => _purchases.removeWhere((p) => p.id == purchase.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Purchase "${purchase.challanNo}" deleted')),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('No purchases found', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          if (_hasActiveFilters || _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _clearFilters();
              },
              child: Text('Reset filters', style: GoogleFonts.poppins(color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

class _VehicleImagesScreen extends StatefulWidget {
  const _VehicleImagesScreen({required this.purchase});

  final Purchase purchase;

  @override
  State<_VehicleImagesScreen> createState() => _VehicleImagesScreenState();
}

class _VehicleImagesScreenState extends State<_VehicleImagesScreen> {
  bool _loadingImages = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preloadImages());
  }

  double _hPad(double width) {
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  List<_VehicleImageItem> _imageItems() {
    final p = widget.purchase;
    final items = <_VehicleImageItem>[
      _VehicleImageItem(
        label: p.isDirectPurchase ? 'Image' : 'Loading',
        imageRef: p.loadingVehicleImage,
        capturedAt: p.loadingVehicleImageAt,
      ),
    ];

    if (!p.isDirectPurchase) {
      items.add(
        _VehicleImageItem(
          label: 'Unloading',
          imageRef: p.unloadingVehicleImage,
          capturedAt: p.unloadingVehicleImageAt,
        ),
      );
    }

    if (p.isWithKanta) {
      items.add(
        _VehicleImageItem(
          label: 'Kanta Slip',
          imageRef: p.kantaSlipImage,
          capturedAt: p.kantaSlipImageAt,
        ),
      );
      items.add(
        _VehicleImageItem(
          label: 'Vehicle at Kanta',
          imageRef: p.vehicleAtKantaImage,
          capturedAt: p.vehicleAtKantaImageAt,
        ),
      );
    }

    return items;
  }

  Future<void> _preloadImages() async {
    final urls = _imageItems()
        .map((item) => resolvePurchaseImageUrl(item.imageRef))
        .where((url) => url.isNotEmpty)
        .toList();

    if (urls.isEmpty) {
      if (mounted) setState(() => _loadingImages = false);
      return;
    }

    await Future.wait(
      urls.map((url) async {
        try {
          await precacheImage(NetworkImage(url), context);
        } catch (_) {}
      }),
    );

    if (mounted) setState(() => _loadingImages = false);
  }

  void _openFullImage(String label, String imageUrl) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _VehicleImageViewerPage(
          title: label,
          imageUrl: imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = _hPad(width);
    final items = _imageItems();

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Vehicle Images',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView.separated(
                    padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _VehicleImageListTile(
                        item: item,
                        onTap: (url) => _openFullImage(item.label, url),
                      );
                    },
                  ),
                  if (_loadingImages)
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.backgroundGray.withValues(alpha: 0.88),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppColors.primaryRed,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Loading images…',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
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
    );
  }
}

class _VehicleImageItem {
  const _VehicleImageItem({
    required this.label,
    required this.imageRef,
    required this.capturedAt,
  });

  final String label;
  final String? imageRef;
  final DateTime? capturedAt;
}

class _VehicleImageListTile extends StatelessWidget {
  const _VehicleImageListTile({
    required this.item,
    required this.onTap,
  });

  final _VehicleImageItem item;
  final ValueChanged<String> onTap;

  static const _thumbSize = 72.0;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolvePurchaseImageUrl(item.imageRef);
    final hasImage = imageUrl.isNotEmpty;

    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasImage ? () => onTap(imageUrl) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderGray.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: _thumbSize,
                  height: _thumbSize,
                  child: hasImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => _emptyThumb(
                            icon: Icons.broken_image_outlined,
                            text: 'Error',
                          ),
                        )
                      : _emptyThumb(
                          icon: Icons.image_not_supported_outlined,
                          text: 'No image',
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headingBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasImage
                          ? (item.capturedAt != null
                              ? formatPurchaseImageDateTime(item.capturedAt!)
                              : 'Tap to view full size')
                          : 'Not uploaded',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasImage)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyThumb({required IconData icon, required String text}) {
    return Container(
      color: AppColors.operationsCardBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary.withValues(alpha: 0.65)),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleImageViewerPage extends StatelessWidget {
  const _VehicleImageViewerPage({
    required this.title,
    required this.imageUrl,
  });

  final String title;
  final String imageUrl;

  double _hPad(double width) {
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = _hPad(width);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar.page(
              title: title,
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.borderGray.withValues(alpha: 0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InteractiveViewer(
                          minScale: 0.9,
                          maxScale: 4,
                          boundaryMargin: const EdgeInsets.all(24),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return SizedBox(
                                    height: 180,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(
                                            color: AppColors.primaryRed,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Loading image…',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        size: 42,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.55),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Unable to load image',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderGray.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 16,
                            color: AppColors.textSecondary.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pinch to zoom • Drag to move',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallanWebViewPage extends StatefulWidget {
  const _ChallanWebViewPage({
    required this.title,
    required this.url,
    required this.challanNo,
  });

  final String title;
  final String url;
  final String challanNo;

  @override
  State<_ChallanWebViewPage> createState() => _ChallanWebViewPageState();
}

class _ChallanWebViewPageState extends State<_ChallanWebViewPage> {
  late final WebViewController _controller;
  bool _loadingPage = true;
  bool _downloadingPdf = false;
  double _progress = 0;
  final Map<int, String> _pdfChunks = {};
  int? _pdfChunkTotal;

  double _hPad(double width) {
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  String get _pdfFileName => 'challan_${widget.challanNo}.pdf';

  @override
  void initState() {
    super.initState();
    final token = Preference.pref.getString('token');
    final headers = <String, String>{
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.cardWhite)
      ..addJavaScriptChannel(
        'GrjChallan',
        onMessageReceived: (message) => _onJsMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress / 100);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _loadingPage = true);
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            setState(() => _loadingPage = false);
            await _injectPdfBridge();
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() => _loadingPage = false);
          },
          onNavigationRequest: (request) {
            final lower = request.url.toLowerCase();
            if (lower.endsWith('.pdf') ||
                lower.endsWith('/pdf') ||
                lower.contains('application/pdf')) {
              _downloadPdfFromUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url), headers: headers);
  }

  Future<void> _injectPdfBridge() async {
    final script = _buildPdfBridgeScript(_pdfFileName);
    for (final delay in [0, 400, 1200]) {
      if (delay > 0) {
        await Future<void>.delayed(Duration(milliseconds: delay));
      }
      if (!mounted) return;
      try {
        await _controller.runJavaScript(script);
      } catch (e) {
        debugPrint('[ChallanWebView] inject bridge failed: $e');
      }
    }
  }

  Future<void> _triggerPdfDownload() async {
    await _captureChallanPdfNative();
  }

  Future<void> _prepareWebViewForCapture() async {
    await _controller.runJavaScript('''
      window.scrollTo(0, 0);
      var btnWrap = document.querySelector('.btn-container');
      if (btnWrap) btnWrap.style.display = 'none';
    ''');
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _restoreWebViewAfterCapture() async {
    try {
      await _controller.runJavaScript(
        "var btnWrap = document.querySelector('.btn-container'); if (btnWrap) btnWrap.style.display = '';",
      );
    } catch (_) {}
  }

  Future<void> _captureChallanPdfNative() async {
    if (_downloadingPdf) return;
    setState(() => _downloadingPdf = true);
    try {
      await _prepareWebViewForCapture();

      if (Platform.isAndroid) {
        final path = await PurchaseImageDownloadService.captureWebViewPdf(
          fileName: _pdfFileName,
        );
        if (!mounted) return;
        final result = await OpenFilex.open(path);
        if (result.type != ResultType.done) {
          _showSnack('Saved to Downloads/GRJ_Purchases/$_pdfFileName');
        }
        return;
      }

      await _controller.runJavaScript(
        'window.grjGeneratePdfFallback && window.grjGeneratePdfFallback();',
      );
    } catch (e) {
      debugPrint('[ChallanWebView] native capture error: $e');
      _showSnack('Could not save PDF.');
      if (mounted) setState(() => _downloadingPdf = false);
    } finally {
      await _restoreWebViewAfterCapture();
      if (mounted && Platform.isAndroid) {
        setState(() => _downloadingPdf = false);
      }
    }
  }

  Future<void> _onJsMessage(String raw) async {
    Map<dynamic, dynamic>? map;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      map = decoded;

      if (map['action'] == 'captureNative') {
        await _captureChallanPdfNative();
        return;
      }

      final error = map['error']?.toString();
      if (error != null && error.isNotEmpty) {
        debugPrint('[ChallanWebView] pdf error: $error');
        _showSnack('PDF download failed.');
        if (mounted) setState(() => _downloadingPdf = false);
        return;
      }

      if (map['chunk'] == true) {
        if (map['done'] == true) {
          final total = (map['total'] as num?)?.toInt() ?? _pdfChunkTotal ?? 0;
          final fileName = (map['filename']?.toString().trim().isNotEmpty ?? false)
              ? map['filename'].toString().trim()
              : _pdfFileName;
          final buffer = StringBuffer();
          for (var i = 0; i < total; i++) {
            buffer.write(_pdfChunks[i] ?? '');
          }
          _pdfChunks.clear();
          _pdfChunkTotal = null;
          try {
            await _saveAndOpenPdf(base64Decode(buffer.toString()), fileName);
          } catch (e) {
            debugPrint('[ChallanWebView] chunk assemble error: $e');
            _showSnack('Could not save PDF.');
          } finally {
            if (mounted) setState(() => _downloadingPdf = false);
          }
          return;
        }

        final index = (map['index'] as num?)?.toInt();
        final total = (map['total'] as num?)?.toInt();
        final data = map['data']?.toString();
        if (index == null || data == null) return;
        _pdfChunks[index] = data;
        _pdfChunkTotal = total;
        if (!_downloadingPdf && mounted) {
          setState(() => _downloadingPdf = true);
        }
        return;
      }

      final data = map['data']?.toString();
      if (data == null || data.isEmpty) return;

      final fileName = (map['filename']?.toString().trim().isNotEmpty ?? false)
          ? map['filename'].toString().trim()
          : _pdfFileName;

      setState(() => _downloadingPdf = true);
      final bytes = base64Decode(data);
      await _saveAndOpenPdf(bytes, fileName);
    } catch (e) {
      debugPrint('[ChallanWebView] js message error: $e');
      _showSnack('Could not save PDF.');
    } finally {
      if (mounted && map?['chunk'] != true) {
        setState(() => _downloadingPdf = false);
      }
    }
  }

  Future<void> _downloadPdfFromUrl(String url) async {
    if (_downloadingPdf) return;
    setState(() => _downloadingPdf = true);
    try {
      final response = await http
          .get(Uri.parse(url), headers: authHeaders)
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await _saveAndOpenPdf(response.bodyBytes, _pdfFileName);
      } else {
        _showSnack('Could not download PDF.');
      }
    } catch (e) {
      debugPrint('[ChallanWebView] url download error: $e');
      _showSnack('Could not download PDF.');
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  Future<void> _saveAndOpenPdf(Uint8List bytes, String fileName) async {
    final safeName = fileName.toLowerCase().endsWith('.pdf') ? fileName : '$fileName.pdf';
    final savedPath = await PurchaseImageDownloadService.downloadToDownloadsFolder(
      bytes: bytes,
      fileName: safeName,
    );

    if (!mounted) return;

    final result = await OpenFilex.open(savedPath);
    if (result.type != ResultType.done) {
      _showSnack('Saved to Downloads/GRJ_Purchases/$safeName');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _buildPdfBridgeScript(String fileName) {
    final escapedName = fileName.replaceAll("'", "\\'");
    return '''
(function() {
  function postError(msg) {
    if (window.GrjChallan) {
      GrjChallan.postMessage(JSON.stringify({ error: msg }));
    }
  }

  function requestNativeCapture() {
    if (window.GrjChallan) {
      GrjChallan.postMessage(JSON.stringify({ action: 'captureNative' }));
    }
  }

  function sendPdfBlob(blob) {
    if (!blob || !blob.size) {
      postError('empty pdf blob');
      return;
    }
    var reader = new FileReader();
    reader.onerror = function() { postError('read blob failed'); };
    reader.onloadend = function() {
      var parts = (reader.result || '').toString().split(',');
      if (parts.length < 2) {
        postError('invalid blob encoding');
        return;
      }
      GrjChallan.postMessage(JSON.stringify({
        filename: '$escapedName',
        data: parts[1]
      }));
    };
    reader.readAsDataURL(blob);
  }

  function generatePdfFallback() {
    var element = document.getElementById('content');
    if (!element || typeof html2pdf !== 'function') {
      postError('html2pdf missing');
      return;
    }
    var pdfH = Math.max(element.scrollHeight, element.offsetHeight, 660);
    var opt = {
      margin: [0, 0, 0, 0],
      filename: '$escapedName',
      image: { type: 'jpeg', quality: 1 },
      html2canvas: {
        scale: 2,
        scrollY: 0,
        scrollX: 0,
        width: 400,
        height: pdfH,
        windowWidth: 400,
        windowHeight: pdfH
      },
      jsPDF: { unit: 'px', format: [400, pdfH] }
    };
    html2pdf().set(opt).from(element).output('blob').then(sendPdfBlob).catch(function(err) {
      postError(String(err));
    });
  }

  function overrideSubmitButton() {
    var btn = document.getElementById('submit');
    if (!btn) return false;
    if (btn.dataset.grjOverridden === '1') return true;

    var newBtn = btn.cloneNode(true);
    newBtn.dataset.grjOverridden = '1';
    btn.parentNode.replaceChild(newBtn, btn);
    newBtn.addEventListener('click', function(e) {
      e.preventDefault();
      requestNativeCapture();
    });
    return true;
  }

  overrideSubmitButton();

  if (!window.__grjPdfHookInterval) {
    var tries = 0;
    window.__grjPdfHookInterval = setInterval(function() {
      overrideSubmitButton();
      tries++;
      if (tries > 30) {
        clearInterval(window.__grjPdfHookInterval);
        window.__grjPdfHookInterval = null;
      }
    }, 200);
  }

  window.grjGeneratePdfFallback = generatePdfFallback;
  window.grjDownloadChallanPdf = requestNativeCapture;
})();
''';
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: widget.title,
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            if (_loadingPage)
              LinearProgressIndicator(
                minHeight: 2,
                value: _progress > 0 ? _progress : null,
                color: AppColors.primaryRed,
                backgroundColor: AppColors.borderGray.withValues(alpha: 0.25),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_downloadingPdf)
                        ColoredBox(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    color: AppColors.primaryRed,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Saving PDF…',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_loadingPage || _downloadingPdf)
                      ? null
                      : _triggerPdfDownload,
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    _downloadingPdf ? 'Downloading…' : 'Download PDF',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor:
                        const Color(0xFF16A34A).withValues(alpha: 0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

enum _KantaSlipFilter { all, yes, no }

enum _PurchaseDateFilter {
  all('All'),
  today('Today'),
  last7('Last 7 days'),
  last30('Last 30 days'),
  thisMonth('This month');

  const _PurchaseDateFilter(this.label);

  final String label;
}
