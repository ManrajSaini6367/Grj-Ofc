import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/items/items.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/purchases/purchase.dart';
import 'package:grjoffice_apps/store/store.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

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
  late List<Purchase> _purchases;

  @override
  void initState() {
    super.initState();
    _purchases = List<Purchase>.from(kMockPurchases);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  List<Purchase> get _filteredPurchases {
    return _purchases.where((p) {
      if (_statusFilter != null && p.status != _statusFilter) return false;
      if (_supplierFilter != null && p.supplierName != _supplierFilter) return false;
      if (_kantaSlipFilter == _KantaSlipFilter.yes && !p.hasKantaSlip) return false;
      if (_kantaSlipFilter == _KantaSlipFilter.no && p.hasKantaSlip) return false;
      if (!_matchesDateFilter(p.date)) return false;
      if (_searchQuery.isNotEmpty) {
        final haystack =
            '${p.challanNo} ${p.invoiceNo} ${p.supplierName} ${p.remark ?? ''} ${p.statusLabel}'
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
      drawer: AppDrawer(selectedIndex: 9, onItemTap: _onDrawerItemTap),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
              color: AppColors.cardWhite,
              child: _buildTopBar(),
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
              child: rows.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...rows.map(_buildPurchaseCard),
                            ],
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
    if (index == 0) {
      navigateToMainTab(context, 0);
    } else if (index == 1) {
      navigateToMainTab(context, 1);
    } else if (index == 3) {
      navigateToMainTab(context, 2);
    } else if (index == 4) {
      navigateToMainTab(context, 3);
    } else if (index == 5) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ItemsScreen()));
    } else if (index == 6) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StoreScreen()));
    }
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: const AppLogo(size: 38),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Purchase List',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.headingBlack),
          ),
        ),
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.iconBgGray,
              border: Border.all(color: AppColors.borderGray),
            ),
            child: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
          ),
        ),
      ],
    );
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
      onSelected: (_) => setState(() {
        _dateFilter = value;
        _filterStartDate = null;
        _filterEndDate = null;
      }),
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
            onPressed: () => setState(() {
              _filterStartDate = null;
              _filterEndDate = null;
            }),
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

  Widget _buildCreateButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Purchase — coming soon.')),
          );
        },
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
                              _buildStatusBadge(purchase.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            purchase.challanNo,
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
                _buildMetaRow(Icons.calendar_today_outlined, _formatDate(purchase.date)),
                const SizedBox(height: 6),
                _buildMetaRow(Icons.receipt_long_outlined, 'Invoice: ${purchase.invoiceNo}'),
                const SizedBox(height: 6),
                _buildMetaRow(
                  Icons.description_outlined,
                  'Kanta Slip: ${purchase.hasKantaSlip ? 'Yes' : 'No'}',
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
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.primaryRed,
                          size: 18,
                        ),
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
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

  void _showDetails(Purchase purchase) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Purchase Details', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _detailRow('Date', _formatDate(purchase.date)),
                _detailRow('Challan No', purchase.challanNo),
                _detailRow('Invoice No', purchase.invoiceNo),
                _detailRow('Supplier', purchase.supplierName),
                _detailRow('Status', purchase.statusLabel),
                _detailRow('Kanta Slip', purchase.hasKantaSlip ? 'Yes' : 'No'),
                _detailRow('Remark', purchase.remark ?? '—'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Purchase purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete Purchase', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete purchase "${purchase.challanNo}"?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.poppins(color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _purchases.removeWhere((p) => p.id == purchase.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${purchase.challanNo} deleted.')),
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
