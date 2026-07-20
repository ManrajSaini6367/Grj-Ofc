import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/models/getsupplierlist.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/SupplierList/add_supplier_screen.dart';
import 'package:grjoffice_apps/SupplierList/supplier.dart';
import 'package:grjoffice_apps/SupplierList/view_supplier_screen.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

enum _SupplierStatusFilter { all, published, unpublished }

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _searchQuery = '';
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  bool _startedLoad = false;

  _SupplierStatusFilter _statusFilter = _SupplierStatusFilter.all;
  String? _materialFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scheduleInitialLoad();
  }

  @override
  void didUpdateWidget(SuppliersScreen oldWidget) {
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
      _loadSuppliers(showLoader: false, search: q);
    });
  }

  void _scheduleInitialLoad() {
    if (_startedLoad) return;
    _startedLoad = true;
    setState(() => _isLoading = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSuppliers();
    });
  }

  Future<void> _loadSuppliers({
    bool showLoader = true,
    String? search,
  }) async {
    if (showLoader && !_isLoading) setState(() => _isLoading = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final response = await getSuppliersApi(
      context,
      search: search ?? _searchController.text.trim(),
      perPage: 100,
    );
    if (!mounted) return;
    setState(() {
      _suppliers = response?.data?.items?.map(_toSupplier).toList() ?? [];
      _isLoading = false;
    });
  }

  Supplier _toSupplier(SupplierListItem item) {
    final materials = item.items
            ?.map((m) => m.name ?? '')
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];

    return Supplier(
      id: (item.id ?? 0).toString(),
      name: item.name ?? '',
      mobile: item.mobile ?? '',
      materials: materials,
      gstNo: item.gstNo ?? '-',
      panNo: item.panNo ?? '-',
      address: item.address ?? '-',
      status: item.status == 'published'
          ? SupplierStatus.published
          : SupplierStatus.unpublished,
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

  List<String> get _materialOptions {
    final names = <String>{};
    for (final s in _suppliers) {
      names.addAll(s.materials.where((m) => m.trim().isNotEmpty));
    }
    final list = names.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  bool get _hasActiveFilters =>
      _statusFilter != _SupplierStatusFilter.all || _materialFilter != null;

  int get _activeFilterCount {
    var n = 0;
    if (_statusFilter != _SupplierStatusFilter.all) n++;
    if (_materialFilter != null) n++;
    return n;
  }

  List<Supplier> get _filteredSuppliers {
    return _suppliers.where((supplier) {
      if (_statusFilter == _SupplierStatusFilter.published &&
          supplier.status != SupplierStatus.published) {
        return false;
      }
      if (_statusFilter == _SupplierStatusFilter.unpublished &&
          supplier.status != SupplierStatus.unpublished) {
        return false;
      }
      if (_materialFilter != null) {
        final match = supplier.materials.any(
          (m) => m.toLowerCase() == _materialFilter!.toLowerCase(),
        );
        if (!match) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final haystack =
            '${supplier.name} ${supplier.mobile} ${supplier.gstNo} '
            '${supplier.panNo} ${supplier.address} '
            '${supplier.materials.join(' ')}'.toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = _SupplierStatusFilter.all;
      _materialFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.suppliers,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Supplier List',
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
                      onRefresh: () => _loadSuppliers(showLoader: false),
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
                                _buildCreateSupplierButton(),
                                const SizedBox(height: 16),
                                ..._filteredSuppliers.map(_buildSupplierCard),
                                if (_filteredSuppliers.isEmpty)
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

  void _openCreateSupplier() async {
    final result = await Navigator.of(context).push<Supplier>(
      MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
    );
    if (result != null && mounted) {
      setState(() => _suppliers.add(result));
    }
  }

  void _openViewSupplier(Supplier supplier) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ViewSupplierScreen(supplier: supplier)),
    );
  }

  Future<void> _editSupplier(Supplier supplier) async {
    final result = await Navigator.of(context).push<Supplier>(
      MaterialPageRoute(builder: (_) => AddSupplierScreen(supplier: supplier)),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) _suppliers[index] = result;
    });
  }

  Future<void> _confirmDeleteSupplier(Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Supplier',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${supplier.name}"?',
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

    final supplierId = int.tryParse(supplier.id);
    if (supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid supplier id.')),
      );
      return;
    }

    final deleted = await deleteSupplierApi(context, supplierId);
    if (!mounted || !deleted) return;

    setState(() => _suppliers.removeWhere((s) => s.id == supplier.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${supplier.name} deleted successfully.')),
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
                      border: Border.all(color: AppColors.primaryRed, width: 1.5),
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
        if (_statusFilter != _SupplierStatusFilter.all)
          _activeChip(
            'Status: ${_statusLabel(_statusFilter)}',
            () => setState(() => _statusFilter = _SupplierStatusFilter.all),
          ),
        if (_materialFilter != null)
          _activeChip(
            'Material: $_materialFilter',
            () => setState(() => _materialFilter = null),
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
    var draftMaterial = _materialFilter;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final materials = _materialOptions;
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.78,
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
                                draftStatus = _SupplierStatusFilter.all;
                                draftMaterial = null;
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
                                  draftStatus == _SupplierStatusFilter.all,
                                  () => setSheetState(
                                    () => draftStatus =
                                        _SupplierStatusFilter.all,
                                  ),
                                ),
                                _filterChip(
                                  'Published',
                                  draftStatus ==
                                      _SupplierStatusFilter.published,
                                  () => setSheetState(
                                    () => draftStatus =
                                        _SupplierStatusFilter.published,
                                  ),
                                ),
                                _filterChip(
                                  'Unpublished',
                                  draftStatus ==
                                      _SupplierStatusFilter.unpublished,
                                  () => setSheetState(
                                    () => draftStatus =
                                        _SupplierStatusFilter.unpublished,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _filterSection(
                              'Material',
                              Icons.inventory_2_outlined,
                              [
                                _filterChip(
                                  'All',
                                  draftMaterial == null,
                                  () => setSheetState(
                                    () => draftMaterial = null,
                                  ),
                                ),
                                if (materials.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'No materials available yet.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                else
                                  ...materials.map(
                                    (name) => _filterChip(
                                      name,
                                      draftMaterial?.toLowerCase() ==
                                          name.toLowerCase(),
                                      () => setSheetState(
                                        () => draftMaterial = name,
                                      ),
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
                              onPressed: () => Navigator.pop(sheetContext),
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
                            flex: 1,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _statusFilter = draftStatus;
                                  _materialFilter = draftMaterial;
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
            );
          },
        );
      },
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

  String _statusLabel(_SupplierStatusFilter filter) => switch (filter) {
        _SupplierStatusFilter.all => 'All',
        _SupplierStatusFilter.published => 'Published',
        _SupplierStatusFilter.unpublished => 'Unpublished',
      };

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

  Widget _buildCreateSupplierButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _openCreateSupplier,
        icon: const Icon(Icons.add_business_outlined, size: 20),
        label: Text(
          'Create Supplier',
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
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search name, mobile, GST, PAN, address…',
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
                onPressed: () {
                  _searchController.clear();
                },
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
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
    final isPublished = supplier.status == SupplierStatus.published;

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
                        Icons.storefront_outlined,
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
                                  supplier.name,
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
                            supplier.mobile,
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
                  Icons.inventory_2_outlined,
                  supplier.materials.join(', '),
                ),
                const SizedBox(height: 6),
                _buildMetaRow(
                  Icons.receipt_long_outlined,
                  'GST: ${supplier.gstNo}',
                ),
                const SizedBox(height: 6),
                _buildMetaRow(
                  Icons.location_on_outlined,
                  supplier.address,
                  maxLines: 2,
                ),
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
                  onTap: () => _openViewSupplier(supplier),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Supplier',
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
                _buildCardActionIcon(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit Supplier',
                  onTap: () => _editSupplier(supplier),
                ),
                _buildCardActionIcon(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete',
                  onTap: () => _confirmDeleteSupplier(supplier),
                ),
              ],
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
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No suppliers found',
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
                _loadSuppliers(showLoader: false);
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
