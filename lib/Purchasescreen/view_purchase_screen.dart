import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ViewPurchaseScreen extends StatefulWidget {
  const ViewPurchaseScreen({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<ViewPurchaseScreen> createState() => _ViewPurchaseScreenState();
}

class _ViewPurchaseScreenState extends State<ViewPurchaseScreen> {
  bool _isLoading = true;
  Purchase? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPurchase());
  }

  Future<void> _loadPurchase() async {
    final purchaseId = int.tryParse(widget.purchase.id);
    if (purchaseId == null) {
      if (!mounted) return;
      setState(() {
        _detail = widget.purchase;
        _isLoading = false;
      });
      return;
    }

    final purchase = await getPurchaseApi(context, purchaseId);
    if (!mounted) return;
    setState(() {
      _detail = purchase ?? widget.purchase;
      _isLoading = false;
    });
  }

  Purchase get _purchase => _detail ?? widget.purchase;

  Future<void> _deletePurchase() async {
    final purchase = _purchase;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Delete Purchase',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${purchase.challanNo}"?',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
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

    Navigator.pop(context, 'deleted');
  }

  String _text(String? value, {String fallback = '—'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _flowLabel(Purchase purchase) {
    if (purchase.isDirectPurchase) return 'Direct / Other';
    if (purchase.isWithKanta) return 'With Kanta';
    return 'Without Kanta';
  }

  bool _isNetworkImage(String? value) =>
      value != null && (value.startsWith('http://') || value.startsWith('https://'));

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final purchase = _purchase;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Purchase Details',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
              actions: [
                IconButton(
                  onPressed: _isLoading ? null : _deletePurchase,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.primaryRed),
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () async {
                        setState(() => _isLoading = true);
                        await _loadPurchase();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(purchase),
                                const SizedBox(height: 14),
                                _buildSection(
                                  title: 'Purchase Info',
                                  icon: Icons.shopping_cart_outlined,
                                  children: [
                                    _infoTile(Icons.tag_rounded, 'Purchase ID', '#${purchase.id}'),
                                    _infoTile(Icons.calendar_today_outlined, 'Date', _formatDate(purchase.date)),
                                    _infoTile(Icons.route_outlined, 'Flow', _flowLabel(purchase)),
                                    _infoTile(
                                      Icons.flag_outlined,
                                      'Stage',
                                      _text(purchase.flowStageLabel ?? purchase.stage),
                                    ),
                                    _infoTile(Icons.verified_outlined, 'Status', purchase.statusLabel),
                                    if (purchase.step != null)
                                      _infoTile(Icons.linear_scale_rounded, 'Step', '${purchase.step}'),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildSection(
                                  title: 'Supplier & Vehicle',
                                  icon: Icons.local_shipping_outlined,
                                  children: [
                                    _infoTile(Icons.storefront_outlined, 'Supplier', purchase.supplierName),
                                    _infoTile(Icons.directions_car_outlined, 'Vehicle No', _text(purchase.vehicleNo)),
                                    _infoTile(Icons.receipt_outlined, 'Challan No', purchase.challanNo),
                                    _infoTile(Icons.description_outlined, 'Invoice No', purchase.invoiceNo),
                                    if ((purchase.kantaNo ?? '').trim().isNotEmpty)
                                      _infoTile(Icons.scale_outlined, 'Kanta No', purchase.kantaNo!),
                                    _infoTile(
                                      Icons.receipt_long_outlined,
                                      'Kanta Slip',
                                      purchase.isDirectPurchase
                                          ? 'Other'
                                          : purchase.hasKantaSlip
                                              ? 'Yes'
                                              : 'No',
                                    ),
                                    _infoTile(Icons.notes_outlined, 'Remark', _text(purchase.remark)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildSection(
                                  title: 'Materials',
                                  icon: Icons.inventory_2_outlined,
                                  children: [
                                    if (purchase.materials.isEmpty)
                                      _infoTile(
                                        Icons.inventory_2_outlined,
                                        'Item',
                                        _text(purchase.itemName),
                                      )
                                    else
                                      ...purchase.materials.map(
                                        (m) => _infoTile(
                                          Icons.category_outlined,
                                          m.name.trim().isEmpty ? 'Item #${m.itemId ?? '—'}' : m.name,
                                          m.qty == null
                                              ? m.unit
                                              : '${m.qty == m.qty!.roundToDouble() ? m.qty!.toInt() : m.qty} ${m.unit}',
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildSection(
                                  title: 'Images',
                                  icon: Icons.photo_library_outlined,
                                  children: [
                                    _imageTile('Loading', purchase.loadingVehicleImage, purchase.loadingVehicleImageAt),
                                    _imageTile('Unloading', purchase.unloadingVehicleImage, purchase.unloadingVehicleImageAt),
                                    _imageTile('Vehicle at Kanta', purchase.vehicleAtKantaImage, purchase.vehicleAtKantaImageAt),
                                    _imageTile('Kanta Slip', purchase.kantaSlipImage, purchase.kantaSlipImageAt),
                                  ],
                                ),
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

  Widget _buildHeader(Purchase purchase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primaryRed.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryRed, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.supplierName,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _text(purchase.vehicleNo, fallback: purchase.challanNo),
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              purchase.flowStageLabel ?? purchase.statusLabel,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryRed,
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryRed),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageTile(String label, String? image, DateTime? capturedAt) {
    final hasImage = image != null && image.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (!hasImage)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.operationsCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(height: 6),
                  Text('No image', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _isNetworkImage(image)
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.operationsCardBg,
                          alignment: Alignment.center,
                          child: Text(image, style: GoogleFonts.poppins(fontSize: 12)),
                        ),
                      )
                    : Container(
                        color: AppColors.operationsCardBg,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          image,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark),
                        ),
                      ),
              ),
            ),
            if (capturedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                formatPurchaseImageDateTime(capturedAt),
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
