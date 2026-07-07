import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/SupplierList/supplier.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

class WithoutKantaStep2Screen extends StatefulWidget {
  const WithoutKantaStep2Screen({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<WithoutKantaStep2Screen> createState() => _WithoutKantaStep2ScreenState();
}

class _WithoutKantaStep2ScreenState extends State<WithoutKantaStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNoController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _remarkController = TextEditingController();
  final _mat1Controller = TextEditingController();
  final _mat2Controller = TextEditingController();
  final _qty1Controller = TextEditingController();
  final _qty2Controller = TextEditingController();
  final _unit1Controller = TextEditingController(text: 'NOS');
  final _unit2Controller = TextEditingController(text: 'NOS');

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
    _invoiceController.text = p.invoiceNo == '—' ? '' : p.invoiceNo;
    _remarkController.text = p.remark ?? '';
    _unloadingImageName = p.unloadingVehicleImage;

    if (p.materials.isNotEmpty) {
      _mat1Controller.text = p.materials[0].name;
      if (p.materials[0].qty != null) _qty1Controller.text = _formatQty(p.materials[0].qty!);
      _unit1Controller.text = p.materials[0].unit;
    }
    if (p.materials.length > 1) {
      _mat2Controller.text = p.materials[1].name;
      if (p.materials[1].qty != null) _qty2Controller.text = _formatQty(p.materials[1].qty!);
      _unit2Controller.text = p.materials[1].unit;
    }
  }

  @override
  void dispose() {
    _vehicleNoController.dispose();
    _invoiceController.dispose();
    _remarkController.dispose();
    _mat1Controller.dispose();
    _mat2Controller.dispose();
    _qty1Controller.dispose();
    _qty2Controller.dispose();
    _unit1Controller.dispose();
    _unit2Controller.dispose();
    super.dispose();
  }

  String _formatQty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();

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

    final materials = <PurchaseMaterialItem>[];
    void addMaterial(TextEditingController name, TextEditingController qty, TextEditingController unit) {
      final n = name.text.trim();
      if (n.isEmpty) return;
      materials.add(PurchaseMaterialItem(
        name: n,
        qty: double.tryParse(qty.text.trim()),
        unit: unit.text.trim().isEmpty ? 'NOS' : unit.text.trim(),
      ));
    }

    addMaterial(_mat1Controller, _qty1Controller, _unit1Controller);
    addMaterial(_mat2Controller, _qty2Controller, _unit2Controller);

    if (materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter at least one material.', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final vehicleNo = _vehicleNoController.text.trim();
    final updated = widget.purchase.copyWith(
      supplierName: _selectedSupplier!,
      vehicleNo: vehicleNo,
      challanNo: vehicleNo.isNotEmpty ? vehicleNo : widget.purchase.challanNo,
      invoiceNo: _invoiceController.text.trim().isEmpty ? '—' : _invoiceController.text.trim(),
      remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
      unloadingVehicleImage: _unloadingImageName,
      unloadingVehicleImageAt: _unloadingImageAt ?? DateTime.now(),
      materials: materials,
      itemName: materials.map((m) => m.name).join(', '),
      withoutKantaStage: WithoutKantaStage.completed,
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
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
              color: AppColors.cardWhite,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: AppColors.textDark,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                  const AppLogo(size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Step 2 — Information Purchase',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Form(
                      key: _formKey,
                      child: _buildFormCard(
                        isWide: isWide,
                        suppliers: suppliers,
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

  Widget _buildFormCard({required bool isWide, required List<String> suppliers}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Information Purchase', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSupplierField(suppliers)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(label: 'Vehicle No', controller: _vehicleNoController, hint: 'Vehicle No')),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(label: 'Invoice No', controller: _invoiceController, hint: 'Invoice no')),
              ],
            )
          else ...[
            _buildSupplierField(suppliers),
            const SizedBox(height: 16),
            _buildTextField(label: 'Vehicle No', controller: _vehicleNoController, hint: 'Vehicle No'),
            const SizedBox(height: 16),
            _buildTextField(label: 'Invoice No', controller: _invoiceController, hint: 'Invoice no'),
          ],
          const SizedBox(height: 20),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMaterialGroup(1, _mat1Controller, _qty1Controller, _unit1Controller)),
                const SizedBox(width: 12),
                Expanded(child: _buildMaterialGroup(2, _mat2Controller, _qty2Controller, _unit2Controller)),
              ],
            )
          else ...[
            _buildMaterialGroup(1, _mat1Controller, _qty1Controller, _unit1Controller),
            const SizedBox(height: 16),
            _buildMaterialGroup(2, _mat2Controller, _qty2Controller, _unit2Controller),
          ],
          const SizedBox(height: 20),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildUnloadingImageField()),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(label: 'Remark', controller: _remarkController, hint: 'Remark')),
              ],
            )
          else ...[
            _buildUnloadingImageField(),
            const SizedBox(height: 16),
            _buildTextField(label: 'Remark', controller: _remarkController, hint: 'Remark'),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : Text('Complete Purchase', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialGroup(
    int index,
    TextEditingController name,
    TextEditingController qty,
    TextEditingController unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(label: 'Material $index', controller: name, hint: name.text.isEmpty ? 'Material' : name.text),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Qty',
                controller: qty,
                hint: 'qty',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(label: 'Unit', controller: unit, hint: 'NOS')),
          ],
        ),
      ],
    );
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
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _fieldDecoration(hint: hint),
        ),
      ],
    );
  }
}
