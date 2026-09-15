import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase_multi_image_picker.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/image_pick_helper.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class WithKantaStep2Screen extends StatefulWidget {
  const WithKantaStep2Screen({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<WithKantaStep2Screen> createState() => _WithKantaStep2ScreenState();
}

class _WithKantaStep2ScreenState extends State<WithKantaStep2Screen> {
  static const _saveBlue = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();

  final List<File> _unloadingImages = [];
  bool _isSaving = false;

  String get _savedVehicleNo => widget.purchase.vehicleNo?.trim() ?? '';

  Future<void> _pickUnloadingImage() async {
    final file = await pickPurchaseImageFile(
      context,
      title: 'Unloading Vehicle Image',
      fromCamera: true,
    );
    if (file == null || !mounted) return;
    if (_unloadingImages.any((existing) => existing.path == file.path)) return;
    setState(() => _unloadingImages.add(file));
  }

  void _removeUnloadingImage(int index) {
    if (index < 0 || index >= _unloadingImages.length) return;
    setState(() => _unloadingImages.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_unloadingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unloading vehicle image is required.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    final vehicleNo = _savedVehicleNo;
    if (vehicleNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle No from Step 1 is missing.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    final purchaseId = int.tryParse(widget.purchase.id);
    if (purchaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid purchase ID.', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final updated = await purchaseStep2WithKantaApi(
      context,
      purchaseId: purchaseId,
      vehicleNo: vehicleNo,
      unloadingImages: _unloadingImages,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (updated != null) {
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final isWide = MediaQuery.sizeOf(context).width >= 640;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Step 2 — Information Purchase',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderGray.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Information Purchase',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      label: 'Supplier',
                                      value: widget.purchase.supplierName,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      label: 'Vehicle No',
                                      value: _savedVehicleNo.isEmpty
                                          ? '—'
                                          : _savedVehicleNo,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildUnloadingImageField()),
                                ],
                              )
                            else ...[
                              _buildReadOnlyField(
                                label: 'Supplier',
                                value: widget.purchase.supplierName,
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField(
                                label: 'Vehicle No',
                                value: _savedVehicleNo.isEmpty
                                    ? '—'
                                    : _savedVehicleNo,
                              ),
                              const SizedBox(height: 16),
                              _buildUnloadingImageField(),
                            ],
                            if (widget.purchase.materials.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              ...widget.purchase.materials.asMap().entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        entry.key ==
                                            widget.purchase.materials.length - 1
                                        ? 0
                                        : 12,
                                  ),
                                  child: _buildReadOnlyField(
                                    label: widget.purchase.materials.length == 1
                                        ? 'Material'
                                        : 'Material ${entry.key + 1}',
                                    value: entry.value.name.trim().isEmpty
                                        ? '—'
                                        : entry.value.name,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _submit,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.assignment_outlined,
                                        size: 18,
                                      ),
                                label: Text(
                                  'Save',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _saveBlue,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }

  double _hPad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 14;
    if (w < 600) return 18;
    return 20;
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.borderGray.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnloadingImageField() {
    return PurchaseMultiImagePicker(
      label: 'Unloading Vehicle Image',
      files: _unloadingImages,
      onAdd: _pickUnloadingImage,
      onRemoveAt: _removeUnloadingImage,
    );
  }
}
