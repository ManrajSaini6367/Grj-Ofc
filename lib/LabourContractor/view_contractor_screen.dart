import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/LabourContractor/labour_contractor.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/getcontractor.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ViewContractorScreen extends StatefulWidget {
  const ViewContractorScreen({super.key, required this.contractor});

  final LabourContractor contractor;

  @override
  State<ViewContractorScreen> createState() => _ViewContractorScreenState();
}

class _ViewContractorScreenState extends State<ViewContractorScreen> {
  bool _isLoading = true;
  ContractorDetailData? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContractor());
  }

  Future<void> _loadContractor() async {
    final contractorId = int.tryParse(widget.contractor.id);
    if (contractorId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final response = await getContractorApi(context, contractorId);
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

  String _rate(double fromDetail, double fallback) {
    final value = fromDetail > 0 ? fromDetail : fallback;
    return '₹${value.toStringAsFixed(0)}';
  }

  String get _mobile => _text(_detail?.mobile, fallback: widget.contractor.mobile);

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final c = widget.contractor;
    final d = _detail;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Contractor Details',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: _loadContractor,
                      child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildQuickStats(d, c),
                              const SizedBox(height: 16),
                              _buildSection(
                                title: 'Contact',
                                icon: Icons.phone_in_talk_outlined,
                                children: [
                                  _infoTile(Icons.phone_outlined, 'Mobile', _mobile),
                                  _infoTile(
                                    Icons.location_on_outlined,
                                    'Address',
                                    _text(d?.address, fallback: c.address),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSection(
                                title: 'Daily Rates',
                                icon: Icons.payments_outlined,
                                children: [
                                  _infoTile(Icons.engineering_outlined, 'Mason / Day', _rate(d?.masonRateValue ?? 0, c.masonRatePerDay)),
                                  _infoTile(Icons.construction_outlined, 'Beldar / Day', _rate(d?.beldarRateValue ?? 0, c.beldarRatePerDay)),
                                  _infoTile(Icons.work_outline, 'Coolie / Day', _rate(d?.coolieRateValue ?? 0, c.coolieRatePerDay)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSection(
                                title: 'Overtime Rates (per hour)',
                                icon: Icons.access_time_outlined,
                                children: [
                                  _infoTile(Icons.engineering_outlined, 'Mason OT', _rate(d?.masonOverRateValue ?? 0, c.masonOtRatePerHour)),
                                  _infoTile(Icons.construction_outlined, 'Beldar OT', _rate(d?.beldarOverRateValue ?? 0, c.beldarOtRatePerHour)),
                                  _infoTile(Icons.work_outline, 'Coolie OT', _rate(d?.coolieOverRateValue ?? 0, c.coolieOtRatePerHour)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildDocsSection(d, c),
                              if (d?.site?.name != null) ...[
                                const SizedBox(height: 14),
                                _buildSection(
                                  title: 'Site',
                                  icon: Icons.apartment_outlined,
                                  children: [
                                    _infoTile(Icons.business_outlined, 'Site Name', _text(d?.site?.name)),
                                    _infoTile(Icons.map_outlined, 'Site Address', _text(d?.site?.address)),
                                  ],
                                ),
                              ],
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

  Widget _buildDocsSection(ContractorDetailData? d, LabourContractor c) {
    final agreements = d?.agreements?.isNotEmpty == true ? d!.agreements! : c.agreements;
    final documents = d?.documents?.isNotEmpty == true ? d!.documents! : c.documents;
    final cancelCheque = (d?.cancelCheque != null && d!.cancelCheque!.trim().isNotEmpty)
        ? d.cancelCheque
        : c.cancelCheque;

    return _buildSection(
      title: 'Documents',
      icon: Icons.folder_open_outlined,
      children: [
        _imageRow('Agreements', agreements),
        _imageRow('Documents', documents),
        _imageRow(
          'Cancel Cheque',
          cancelCheque == null || cancelCheque.trim().isEmpty ? const [] : [cancelCheque],
        ),
      ],
    );
  }

  Widget _imageRow(String label, List<String> urls) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          if (urls.isEmpty)
            Text('—', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final url in urls)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      mediaUrl(url),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: AppColors.operationsCardBg,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ContractorDetailData? d, LabourContractor c) {
    final mason = d?.masonRateValue ?? c.masonRatePerDay;
    final beldar = d?.beldarRateValue ?? c.beldarRatePerDay;
    final coolie = d?.coolieRateValue ?? c.coolieRatePerDay;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _statCard('Mason/Day', _rate(mason, mason), const Color(0xFF2563EB)),
          _statCard('Beldar/Day', _rate(beldar, beldar), const Color(0xFF059669)),
          _statCard('Coolie/Day', _rate(coolie, coolie), const Color(0xFFD97706)),
        ];

        if (constraints.maxWidth < 340) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), const SizedBox(width: 10), Expanded(child: cards[1])]),
              const SizedBox(height: 10),
              cards[2],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
            const SizedBox(width: 10),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
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
            child: Icon(Icons.currency_rupee, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.headingBlack),
          ),
        ],
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
