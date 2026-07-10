import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/SupplierList/supplier.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class WithKantaStep3Screen extends StatefulWidget {
  const WithKantaStep3Screen({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<WithKantaStep3Screen> createState() => _WithKantaStep3ScreenState();
}

class _WithKantaStep3ScreenState extends State<WithKantaStep3Screen> {
  static const _saveBlue = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  final _vehicleNoController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _kantaNoController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController(text: 'NOS');
  final _remarkController = TextEditingController();
  late final TextEditingController _materialController;

  String? _selectedSupplier;
  String? _kantaSlipImageName;
  DateTime? _kantaSlipImageAt;
  String? _vehicleAtKantaImageName;
  DateTime? _vehicleAtKantaImageAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _selectedSupplier = p.supplierName;
    _vehicleNoController.text = p.vehicleNo ?? '';
    _invoiceController.text = p.invoiceNo == '—' ? '' : p.invoiceNo;
    _kantaNoController.text = p.kantaNo ?? '';
    _kantaSlipImageName = p.kantaSlipImage;
    _kantaSlipImageAt = p.kantaSlipImageAt;
    _vehicleAtKantaImageName = p.vehicleAtKantaImage;
    _vehicleAtKantaImageAt = p.vehicleAtKantaImageAt;
    _remarkController.text = p.remark ?? '';

    final materialName = p.materials.isNotEmpty
        ? p.materials.first.name
        : (p.itemName ?? '').split(',').first.trim();
    _materialController = TextEditingController(text: materialName);

    if (p.materials.isNotEmpty && p.materials.first.qty != null) {
      final qty = p.materials.first.qty!;
      _qtyController.text = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
      _unitController.text = p.materials.first.unit;
    }
  }

  @override
  void dispose() {
    _vehicleNoController.dispose();
    _invoiceController.dispose();
    _kantaNoController.dispose();
    _materialController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(void Function(String) onPicked) async {
    onPicked('photo_camera.jpg');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a supplier.', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_kantaSlipImageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kanta slip image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_vehicleAtKantaImageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle at kanta image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final vehicleNo = _vehicleNoController.text.trim();
    final invoiceNo = _invoiceController.text.trim();
    final kantaNo = _kantaNoController.text.trim();
    final materialName = _materialController.text.trim();
    final qtyText = _qtyController.text.trim();
    final qty = qtyText.isEmpty ? null : double.tryParse(qtyText);
    final unit = _unitController.text.trim().isEmpty ? 'NOS' : _unitController.text.trim();

    final updated = widget.purchase.copyWith(
      supplierName: _selectedSupplier!,
      vehicleNo: vehicleNo.isEmpty ? widget.purchase.vehicleNo : vehicleNo,
      challanNo: vehicleNo.isNotEmpty ? vehicleNo : widget.purchase.challanNo,
      invoiceNo: invoiceNo.isEmpty ? widget.purchase.invoiceNo : invoiceNo,
      kantaSlipImage: _kantaSlipImageName,
      kantaSlipImageAt: _kantaSlipImageAt ?? DateTime.now(),
      kantaNo: kantaNo.isEmpty ? null : kantaNo,
      vehicleAtKantaImage: _vehicleAtKantaImageName,
      vehicleAtKantaImageAt: _vehicleAtKantaImageAt ?? DateTime.now(),
      remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
      materials: [
        PurchaseMaterialItem(name: materialName, qty: qty, unit: unit),
      ],
      itemName: materialName,
      withKantaStage: WithKantaStage.completed,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final suppliers = kMockSuppliers.map((s) => s.name).toList();
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Step 3 — Information Purchase',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
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
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Invoice No',
                                      controller: _invoiceController,
                                      hint: 'Invoice no',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildKantaSlipImageField()),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Kanta No',
                                      controller: _kantaNoController,
                                      hint: 'Kanta no',
                                    ),
                                  ),
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
                              _buildTextField(
                                label: 'Invoice No',
                                controller: _invoiceController,
                                hint: 'Invoice no',
                              ),
                              const SizedBox(height: 16),
                              _buildKantaSlipImageField(),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Kanta No',
                                controller: _kantaNoController,
                                hint: 'Kanta no',
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildMaterialField()),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Qty',
                                      controller: _qtyController,
                                      hint: 'qty',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Unit',
                                      controller: _unitController,
                                      hint: 'NOS',
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _buildMaterialField(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Qty',
                                      controller: _qtyController,
                                      hint: 'qty',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Unit',
                                      controller: _unitController,
                                      hint: 'NOS',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),
                            Divider(color: AppColors.borderGray.withValues(alpha: 0.5)),
                            const SizedBox(height: 20),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildVehicleAtKantaImageField()),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Remark',
                                      controller: _remarkController,
                                      hint: 'Remark',
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _buildVehicleAtKantaImageField(),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Remark',
                                controller: _remarkController,
                                hint: 'Remark',
                              ),
                            ],
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

  Widget _buildMaterialField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Material 1', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _materialController,
          readOnly: true,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
          decoration: _fieldDecoration(hint: 'Material').copyWith(
            filled: true,
            fillColor: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }

  Widget _buildKantaSlipImageField() => _buildImageField(
        label: 'Kanta Slip Image',
        fileName: _kantaSlipImageName,
        onPick: () => _pickImage((name) => setState(() {
              _kantaSlipImageName = 'kanta_slip_$name';
              _kantaSlipImageAt = DateTime.now();
            })),
      );

  Widget _buildVehicleAtKantaImageField() => _buildImageField(
        label: 'Vehicle at Kanta Image',
        fileName: _vehicleAtKantaImageName,
        onPick: () => _pickImage((name) => setState(() {
              _vehicleAtKantaImageName = 'vehicle_kanta_$name';
              _vehicleAtKantaImageAt = DateTime.now();
            })),
      );

  Widget _buildImageField({
    required String label,
    required String? fileName,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            children: [
              TextSpan(text: '$label '),
              const TextSpan(text: '*', style: TextStyle(color: AppColors.primaryRed)),
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
                onPressed: onPick,
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
                    color: fileName == null ? AppColors.textSecondary : AppColors.textDark,
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

  double _hPad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 14;
    if (w < 600) return 18;
    return 20;
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(fontSize: 13),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: _fieldDecoration(hint: hint),
        ),
      ],
    );
  }
}
