import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/PetiContractor/peti_contractor.dart';
import 'package:grjoffice_apps/PetiContractor/peti_contractor_screen.dart';
import 'package:grjoffice_apps/PetiContractor/peti_contractor_view_screen.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/permission_gate.dart';

enum _StatusFilter { all, published, unpublished }

class OriginalContractorsListScreen extends StatefulWidget {
  const OriginalContractorsListScreen({super.key});

  @override
  State<OriginalContractorsListScreen> createState() =>
      _OriginalContractorsListScreenState();
}

class _OriginalContractorsListScreenState
    extends State<OriginalContractorsListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _searchQuery = '';
  List<OriginalContractor> _contractors = [];
  bool _isLoading = true;
  _StatusFilter _statusFilter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    final response = await getOriginalContractorsApi(
      context,
      search: _searchController.text.trim(),
      perPage: 100,
    );
    if (!mounted) return;
    setState(() {
      _contractors = (response?.data?.items ?? [])
          .map(OriginalContractor.fromApiItem)
          .toList();
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() => _searchQuery = query.toLowerCase());
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _load(showLoader: false);
    });
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

  bool get _hasActiveFilters => _statusFilter != _StatusFilter.all;

  List<OriginalContractor> get _filtered {
    final list = _contractors.where((contractor) {
      if (_statusFilter == _StatusFilter.published && !contractor.isPublished) {
        return false;
      }
      if (_statusFilter == _StatusFilter.unpublished && contractor.isPublished) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final haystack =
            '${contractor.name} ${contractor.worksSummary}'.toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      return true;
    }).toList();

    list.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return list;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<Object>(
      MaterialPageRoute(builder: (_) => const OriginalContractorScreen()),
    );
    if (!mounted || created == null) return;
    if (created is OriginalContractor) {
      setState(() => _contractors.insert(0, created));
    }
    await _load(showLoader: false);
  }

  Future<void> _editContractor(OriginalContractor contractor) async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => OriginalContractorScreen(contractor: contractor),
      ),
    );
    if (!mounted) return;
    if (result is OriginalContractor) {
      setState(() {
        final index = _contractors.indexWhere((item) => item.id == contractor.id);
        if (index != -1) _contractors[index] = result;
      });
    }
    await _load(showLoader: false);
  }

  void _openView(OriginalContractor contractor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OriginalContractorViewScreen(contractor: contractor),
      ),
    );
  }

  Future<void> _confirmDelete(OriginalContractor contractor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Peti Contractor',
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

    final deleted = await deleteOriginalContractorApi(
      context,
      originalContractorId: contractorId,
    );
    if (!mounted || !deleted) return;

    setState(() => _contractors.removeWhere((item) => item.id == contractor.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${contractor.name} deleted successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final filtered = _filtered;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.originalContractors,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Peti Contractor List',
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
                      onRefresh: () => _load(showLoader: false),
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
                                ...filtered.map(_buildContractorCard),
                                if (filtered.isEmpty) _buildEmptyState(),
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

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: [
        Expanded(child: _buildSearchBar()),
        const SizedBox(width: 10),
        _buildFilterButton(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search name or work…',
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
          child: Icon(
            Icons.tune_rounded,
            color: active ? AppColors.white : AppColors.textDark,
            size: 22,
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
        InputChip(
          label: Text(
            'Status: ${_statusFilter == _StatusFilter.published ? 'Published' : 'Unpublished'}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryRed),
          ),
          deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primaryRed),
          onDeleted: () => setState(() => _statusFilter = _StatusFilter.all),
          backgroundColor: AppColors.primaryRed.withValues(alpha: 0.08),
          side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.25)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        InputChip(
          label: Text(
            'Clear all',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryRed),
          ),
          onPressed: () => setState(() => _statusFilter = _StatusFilter.all),
          backgroundColor: AppColors.primaryRed.withValues(alpha: 0.08),
          side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.25)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  void _showFilterSheet() {
    var draftStatus = _statusFilter;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Filters',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip(
                          'All',
                          draftStatus == _StatusFilter.all,
                          () => setSheetState(
                            () => draftStatus = _StatusFilter.all,
                          ),
                        ),
                        _filterChip(
                          'Published',
                          draftStatus == _StatusFilter.published,
                          () => setSheetState(
                            () => draftStatus = _StatusFilter.published,
                          ),
                        ),
                        _filterChip(
                          'Unpublished',
                          draftStatus == _StatusFilter.unpublished,
                          () => setSheetState(
                            () => draftStatus = _StatusFilter.unpublished,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _statusFilter = draftStatus);
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      labelStyle: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? AppColors.primaryRed : AppColors.textDark,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.primaryRed
            : AppColors.borderGray.withValues(alpha: 0.6),
      ),
      backgroundColor: AppColors.cardWhite,
    );
  }

  Widget _buildCreateButton() {
    return PermissionGate(
      permission: AppPermissions.contractorsCreate,
      child: SizedBox(
        height: 46,
        child: ElevatedButton.icon(
          onPressed: _openCreate,
          icon: const Icon(Icons.engineering_outlined, size: 20),
          label: Text(
            'Create Peti Contractor',
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

  Widget _buildContractorCard(OriginalContractor contractor) {
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
                        Icons.engineering_outlined,
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
                              _buildStatusBadge(contractor.isPublished),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
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
                                  'Work according to rate',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contractor.worksSummary,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  onTap: () => _openView(contractor),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Peti Contractor',
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
                  tooltip: 'Edit Peti Contractor',
                  onTap: () => _editContractor(contractor),
                ),
                _buildCardActionIcon(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete',
                  onTap: () => _confirmDelete(contractor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.primaryRed, size: 22),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.engineering_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No peti contractors found',
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
                setState(() => _statusFilter = _StatusFilter.all);
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
