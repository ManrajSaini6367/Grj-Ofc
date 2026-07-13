import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
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
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

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
      perPage: 50,
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
        _buildDateFilterChips(),
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
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _openAddPurchase,
        icon: const Icon(Icons.add_shopping_cart_outlined, size: 20),
        label: Text('Create Purchase', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _viewVehicleImages(Purchase purchase) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Vehicle Images', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _imageRow(
                  purchase.isDirectPurchase ? 'Image' : 'Loading',
                  purchase.loadingVehicleImage,
                  purchase.loadingVehicleImageAt,
                ),
                if (!purchase.isDirectPurchase) ...[
                  const SizedBox(height: 12),
                  _imageRow('Unloading', purchase.unloadingVehicleImage, purchase.unloadingVehicleImageAt),
                ],
                if (purchase.isWithKanta) ...[
                  const SizedBox(height: 12),
                  _imageRow('Kanta Slip', purchase.kantaSlipImage, purchase.kantaSlipImageAt),
                  const SizedBox(height: 12),
                  _imageRow('Vehicle at Kanta', purchase.vehicleAtKantaImage, purchase.vehicleAtKantaImageAt),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imageRow(String label, String? fileName, DateTime? capturedAt) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.operationsCardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
          ),
          child: Icon(
            fileName != null ? Icons.image_outlined : Icons.hide_image_outlined,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                fileName ?? 'Not uploaded',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (fileName != null && capturedAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text(
                      formatPurchaseImageDateTime(capturedAt),
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _downloadChallan(Purchase purchase) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading challan for ${purchase.challanNo}…')),
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
