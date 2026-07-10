import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/SupplierList/supplier.dart';
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
  final _materialController = TextEditingController();

  String? _selectedSupplier;
  String? _unloadingImageName;
  DateTime? _unloadingImageAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _selectedSupplier = p.supplierName;
    _vehicleNoController.text = p.vehicleNo ?? '';
    _unloadingImageName = p.unloadingVehicleImage;
    if (p.materials.isNotEmpty) {
      _materialController.text = p.materials.first.name;
    } else if ((p.itemName ?? '').isNotEmpty) {
      _materialController.text = p.itemName!.split(',').first.trim();
    }
  }

  @override
  void dispose() {
    _vehicleNoController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  Future<void> _pickUnloadingImage() async {
    setState(() {
      _unloadingImageName = 'unloading_vehicle.jpg';
      _unloadingImageAt = DateTime.now();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a supplier.', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_unloadingImageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unloading vehicle image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final materialName = _materialController.text.trim();
    if (materialName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter material.', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final vehicleNo = _vehicleNoController.text.trim();
    final updated = widget.purchase.copyWith(
      supplierName: _selectedSupplier!,
      vehicleNo: vehicleNo.isEmpty ? widget.purchase.vehicleNo : vehicleNo,
      challanNo: vehicleNo.isNotEmpty ? vehicleNo : widget.purchase.challanNo,
      unloadingVehicleImage: _unloadingImageName,
      unloadingVehicleImageAt: _unloadingImageAt ?? DateTime.now(),
      materials: [PurchaseMaterialItem(name: materialName)],
      itemName: materialName,
      withKantaStage: WithKantaStage.processing,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final suppliers = kMockSuppliers.map((s) => s.name).toList();
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
                                  Expanded(child: _buildSupplierField(suppliers)),
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
                              _buildSupplierField(suppliers),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Vehicle No',
                                controller: _vehicleNoController,
                                hint: 'Vehicle No',
                              ),
                              const SizedBox(height: 16),
                              _buildUnloadingImageField(),
                            ],
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: 'Material 1',
                              controller: _materialController,
                              hint: 'Material',
                            ),
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                height: 44,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

  Widget _buildUnloadingImageField() {
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
                  _unloadingImageName ?? 'No file selected.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _unloadingImageName == null ? AppColors.textSecondary : AppColors.textDark,
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

  Widget _buildSupplierField(List<String> suppliers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Supplier', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSupplier,
          decoration: _fieldDecoration(),
          items: suppliers
              .map((name) => DropdownMenuItem(value: name, child: Text(name, style: GoogleFonts.poppins(fontSize: 13))))
              .toList(),
          onChanged: (value) => setState(() => _selectedSupplier = value),
          validator: (value) => value == null ? 'Required' : null,
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
