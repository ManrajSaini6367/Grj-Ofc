import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/getsupplier.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/SupplierList/supplier.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ViewSupplierScreen extends StatefulWidget {
  const ViewSupplierScreen({super.key, required this.supplier});

  final Supplier supplier;

  @override
  State<ViewSupplierScreen> createState() => _ViewSupplierScreenState();
}

class _ViewSupplierScreenState extends State<ViewSupplierScreen> {
  bool _isLoading = true;
  SupplierData? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSupplier());
  }

  Future<void> _loadSupplier() async {
    final supplierId = int.tryParse(widget.supplier.id);
    if (supplierId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final response = await getSupplierApi(context, supplierId);
    if (!mounted) return;

    setState(() {
      _detail = response?.data;
      _isLoading = false;
    });
  }

  String _text(String? value, {String fallback = '-'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  bool get _isPublished {
    final status = _detail?.status ?? widget.supplier.status.name;
    return status == 'published';
  }

  String get _mobile => _text(_detail?.mobile, fallback: widget.supplier.mobile);

  List<SupplierItem> get _items => _detail?.items ?? [];

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Supplier Details',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildQuickStats(),
                              const SizedBox(height: 16),
                              _buildSection(
                                title: 'Contact',
                                icon: Icons.phone_in_talk_outlined,
                                children: [
                                  _infoTile(Icons.phone_outlined, 'Mobile', _mobile),
                                  _infoTile(
                                    Icons.location_on_outlined,
                                    'Address',
                                    _text(_detail?.address, fallback: widget.supplier.address),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSection(
                                title: 'Tax Details',
                                icon: Icons.receipt_long_outlined,
                                children: [
                                  _infoTile(
                                    Icons.numbers_outlined,
                                    'GST No',
                                    _text(_detail?.gstNo, fallback: widget.supplier.gstNo),
                                  ),
                                  _infoTile(
                                    Icons.credit_card_outlined,
                                    'PAN No',
                                    _text(_detail?.panNo, fallback: widget.supplier.panNo),
                                  ),
                                ],
                              ),
                              if (_items.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _buildMaterialsSection(),
                              ],
                              if (_detail?.site?.name != null) ...[
                                const SizedBox(height: 14),
                                _buildSection(
                                  title: 'Site',
                                  icon: Icons.apartment_outlined,
                                  children: [
                                    _infoTile(Icons.business_outlined, 'Site Name', _text(_detail?.site?.name)),
                                    _infoTile(
                                      Icons.map_outlined,
                                      'Site Address',
                                      _text(_detail?.site?.address),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _buildQuickStats() {
    final materialCount = _items.isNotEmpty ? _items.length : widget.supplier.materials.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 340;
        final children = [
          _statCard(
            icon: Icons.inventory_2_outlined,
            label: 'Materials',
            value: materialCount.toString(),
            color: const Color(0xFF2563EB),
          ),
          _statCard(
            icon: Icons.receipt_outlined,
            label: 'GST',
            value: _text(_detail?.gstNo, fallback: widget.supplier.gstNo).length > 10
                ? 'Added'
                : _text(_detail?.gstNo, fallback: widget.supplier.gstNo),
            color: const Color(0xFF059669),
          ),
          _statCard(
            icon: Icons.verified_outlined,
            label: 'Status',
            value: _isPublished ? 'Live' : 'Draft',
            color: AppColors.primaryRed,
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              Row(children: [Expanded(child: children[0]), const SizedBox(width: 10), Expanded(child: children[1])]),
              const SizedBox(height: 10),
              children[2],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 10),
            Expanded(child: children[1]),
            const SizedBox(width: 10),
            Expanded(child: children[2]),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.headingBlack),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                Text(
                  'Materials / Items',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.headingBlack),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderGray.withValues(alpha: 0.35)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _items.map(_materialChip).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _materialChip(SupplierItem item) {
    final label = item.unit != null && item.unit!.isNotEmpty
        ? '${item.name} (${item.unit})'
        : _text(item.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primaryRed),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.headingBlack),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderGray.withValues(alpha: 0.35)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.operationsCardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.headingBlack),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
