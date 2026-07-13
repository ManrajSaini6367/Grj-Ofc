import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
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
  final _vehicleNoController = TextEditingController();

  File? _unloadingImageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _vehicleNoController.text = p.vehicleNo ?? '';
  }

  @override
  void dispose() {
    _vehicleNoController.dispose();
    super.dispose();
  }

  Future<void> _pickUnloadingImage() async {
    final picked = await pickPurchaseImage(context);
    if (picked == null || !mounted) return;
    setState(() => _unloadingImageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_unloadingImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unloading vehicle image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final vehicleNo = _vehicleNoController.text.trim();
    if (vehicleNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle No is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final purchaseId = int.tryParse(widget.purchase.id);
    if (purchaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid purchase ID.', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() => _isSaving = true);
    final updated = await purchaseStep2WithKantaApi(
      context,
      purchaseId: purchaseId,
      vehicleNo: vehicleNo,
      unloadingImage: _unloadingImageFile!,
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
                          border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Information Purchase',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildReadOnlyField(label: 'Supplier', value: widget.purchase.supplierName)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Vehicle No',
                                      controller: _vehicleNoController,
                                      hint: 'Vehicle No',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildUnloadingImageField()),
                                ],
                              )
                            else ...[
                              _buildReadOnlyField(label: 'Supplier', value: widget.purchase.supplierName),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Vehicle No',
                                controller: _vehicleNoController,
                                hint: 'Vehicle No',
                              ),
                              const SizedBox(height: 16),
                              _buildUnloadingImageField(),
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
                                    : const Icon(Icons.assignment_outlined, size: 18),
                                label: Text(
                                  'Save',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _saveBlue,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.6)),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildUnloadingImageField() {
    final fileName = _unloadingImageFile?.path.split('/').last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            children: const [
              TextSpan(text: 'Unloading Vehicle Image '),
              TextSpan(text: '*', style: TextStyle(color: AppColors.primaryRed)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.operationsCardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: _pickUnloadingImage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  backgroundColor: const Color(0xFFE5E7EB),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text('Take Photo', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName ?? 'No file selected.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _unloadingImageFile == null ? AppColors.textSecondary : AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.operationsCardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.5), width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _fieldDecoration(hint: hint),
        ),
      ],
    );
  }
}
