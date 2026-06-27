import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/contractors/add_contractor_screen.dart';
import 'package:grjoffice_apps/contractors/labour_contractor.dart';
import 'package:grjoffice_apps/contractors/view_contractor_screen.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/models/listcontractor.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

class ContractorsScreen extends StatefulWidget {
  const ContractorsScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ContractorsScreen> createState() => _ContractorsScreenState();
}

class _ContractorsScreenState extends State<ContractorsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<LabourContractor> _contractors = [];
  bool _isLoading = false;
  bool _startedLoad = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    if (widget.isActive) _scheduleInitialLoad();
  }

  @override
  void didUpdateWidget(ContractorsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleInitialLoad();
    }
  }

  void _scheduleInitialLoad() {
    if (_startedLoad) return;
    _startedLoad = true;
    setState(() => _isLoading = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadContractors();
    });
  }

  Future<void> _loadContractors() async {
    if (!_isLoading) setState(() => _isLoading = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final response = await getContractorListApi(context);
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
      masonRatePerDay: item.masonRateValue,
      beldarRatePerDay: item.beldarRateValue,
      coolieRatePerDay: item.coolieRateValue,
      masonOtRatePerHour: item.masonOverRateValue,
      beldarOtRatePerHour: item.beldarOverRateValue,
      coolieOtRatePerHour: item.coolieOverRateValue,
      status: item.status == 'published'
          ? ContractorStatus.published
          : ContractorStatus.unpublished,
    );
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

  List<LabourContractor> get _filteredContractors {
    if (_searchQuery.isEmpty) return _contractors;
    return _contractors.where((c) {
      final haystack = '${c.name} ${c.mobile} ${c.address}'.toLowerCase();
      return haystack.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: 4,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
              color: AppColors.cardWhite,
              child: _buildTopBar(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildCreateButton(),
                        const SizedBox(height: 16),
                        ..._filteredContractors.map(_buildContractorCard),
                        if (_filteredContractors.isEmpty) _buildEmptyState(),
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
    navigateFromDrawer(context, index);
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
            'Contractor List',
            style: GoogleFonts.poppins(
              color: AppColors.headingBlack,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
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
            child: const Icon(
              Icons.person_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      ],
    );
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
      MaterialPageRoute(builder: (_) => ViewContractorScreen(contractor: contractor)),
    );
  }

  Future<void> _editContractor(LabourContractor contractor) async {
    final result = await Navigator.of(context).push<LabourContractor>(
      MaterialPageRoute(builder: (_) => AddContractorScreen(contractor: contractor)),
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
          'Delete Contractor',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.headingBlack),
        ),
        content: Text(
          'Are you sure you want to delete "${contractor.name}"?',
          style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.primaryRed, fontWeight: FontWeight.w600),
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
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _openCreate,
        icon: const Icon(Icons.groups_outlined, size: 20),
        label: Text(
          'Create Contractor',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search contractors by name, mobile or address.',
        hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
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
                _buildMetaRow(Icons.location_on_outlined, contractor.address, maxLines: 2),
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
                InkWell(
                  onTap: () => _openViewContractor(contractor),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Contractor',
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
                  tooltip: 'Edit Contractor',
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
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Mason ₹${c.masonRatePerDay.toInt()} · Beldar ₹${c.beldarRatePerDay.toInt()} · Coolie ₹${c.coolieRatePerDay.toInt()}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'OT Rates / Hour',
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Mason ₹${c.masonOtRatePerHour.toInt()} · Beldar ₹${c.beldarOtRatePerHour.toInt()} · Coolie ₹${c.coolieOtRatePerHour.toInt()}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark),
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
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12),
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
            'No contractors found',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
