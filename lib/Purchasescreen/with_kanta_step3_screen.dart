import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/image_pick_helper.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class WithKantaStep3Screen extends StatefulWidget {
  const WithKantaStep3Screen({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<WithKantaStep3Screen> createState() => _WithKantaStep3ScreenState();
}

class _KantaMaterialLine {
  _KantaMaterialLine({String? qtyText, this.unit = 'Ton'})
      : qty = TextEditingController(text: qtyText ?? '');

  ItemModel? item;
  final TextEditingController qty;
  String unit;

  void dispose() => qty.dispose();
}

class _WithKantaStep3ScreenState extends State<WithKantaStep3Screen> {
  static const _saveBlue = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _kantaNoController = TextEditingController();
  final _remarkController = TextEditingController();
  final List<_KantaMaterialLine> _lines = [];

  File? _kantaSlipImageFile;
  File? _vehicleAtKantaImageFile;
  bool _isSaving = false;

  List<ItemModel> _items = [];
  bool _loadingItems = true;

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _invoiceController.text = p.invoiceNo == '—' ? '' : p.invoiceNo;
    _kantaNoController.text = p.kantaNo ?? '';
    _remarkController.text = p.remark ?? '';

    if (p.materials.isEmpty) {
      _lines.add(_KantaMaterialLine());
    } else {
      for (final m in p.materials) {
        final qty = m.qty;
        _lines.add(
          _KantaMaterialLine(
            qtyText: qty == null
                ? null
                : (qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString()),
            unit: m.unit.trim().isEmpty ? 'Ton' : m.unit.trim(),
          ),
        );
      }
    }

    _loadItems();
  }

  Future<void> _loadItems() async {
    final supplierId = widget.purchase.supplierId;
    final catalog = cachedItems() ??
        await itemsApi(
          context,
          perPage: 15,
          fetchAllPages: true,
          purchase: '1',
        ) ??
        <ItemModel>[];
    if (!mounted) return;

    List<ItemModel> materials = [];
    if (supplierId != null) {
      materials = await loadSupplierMaterials(
        context,
        supplierId,
        catalog: catalog,
      );
      if (!mounted) return;
    }

    setState(() {
      _items = materials;
      _loadingItems = false;
      _prefillItems();
    });
  }

  void _prefillItems() {
    final p = widget.purchase;
    for (var i = 0; i < p.materials.length && i < _lines.length; i++) {
      final material = p.materials[i];
      if (material.itemId == null) continue;
      final matched = _items.cast<ItemModel?>().firstWhere(
            (it) => it?.id == material.itemId,
            orElse: () => null,
          );
      _lines[i].item = matched;
      if (matched != null && material.unit.trim().isEmpty) {
        _lines[i].unit = unitFromMaterial(matched);
      }
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _kantaNoController.dispose();
    _remarkController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _removeMaterialLine(int index) {
    if (_lines.length <= 1) return;
    setState(() => _lines.removeAt(index).dispose());
  }

  Future<void> _pickImage({required bool isKantaSlip}) async {
    final title = isKantaSlip ? 'Kanta Slip Image' : 'Vehicle at Kanta Image';
    final file = await pickPurchaseImageFile(
      context,
      title: title,
      fromCamera: true,
    );
    if (file == null || !mounted) return;
    setState(() {
      if (isKantaSlip) {
        _kantaSlipImageFile = file;
      } else {
        _vehicleAtKantaImageFile = file;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kantaSlipImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kanta slip image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_vehicleAtKantaImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle at kanta image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final invoiceNo = _invoiceController.text.trim();

    final kantaNo = _kantaNoController.text.trim();
    if (kantaNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kanta No is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final materials = <PurchaseMaterialPayload>[];
    for (final line in _lines) {
      if (line.item == null) continue;
      final qtyVal = double.tryParse(line.qty.text.trim());
      if (qtyVal == null || qtyVal <= 0) continue;
      materials.add(
        PurchaseMaterialPayload(
          itemId: line.item!.id,
          qty: qtyVal,
          unit: line.unit.trim().isEmpty ? 'Ton' : line.unit.trim(),
        ),
      );
    }

    if (materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter at least one material with qty.', style: GoogleFonts.poppins())),
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

    final remark = _remarkController.text.trim();

    setState(() => _isSaving = true);
    final updated = await purchaseStep3WithKantaApi(
      context,
      purchaseId: purchaseId,
      invoiceNo: invoiceNo.isEmpty ? null : invoiceNo,
      kantaNo: kantaNo,
      remark: remark.isEmpty ? null : remark,
      materials: materials,
      kantaSlipImage: _kantaSlipImageFile!,
      vehicleAtKantaImage: _vehicleAtKantaImageFile!,
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
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      label: 'Supplier',
                                      value: widget.purchase.supplierName,
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
                                  Expanded(
                                    child: _buildImagePickerField(
                                      label: 'Kanta Slip Image',
                                      file: _kantaSlipImageFile,
                                      onPick: () => _pickImage(isKantaSlip: true),
                                    ),
                                  ),
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
                              _buildReadOnlyField(label: 'Supplier', value: widget.purchase.supplierName),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Invoice No',
                                controller: _invoiceController,
                                hint: 'Invoice no',
                              ),
                              const SizedBox(height: 16),
                              _buildImagePickerField(
                                label: 'Kanta Slip Image',
                                file: _kantaSlipImageFile,
                                onPick: () => _pickImage(isKantaSlip: true),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Kanta No',
                                controller: _kantaNoController,
                                hint: 'Kanta no',
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (_loadingItems)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else ...[
                              ...List.generate(_lines.length, (index) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: index < _lines.length - 1 ? 16 : 0),
                                  child: _buildMaterialRow(index, isWide: isWide),
                                );
                              }),
                            ],
                            const SizedBox(height: 20),
                            Divider(color: AppColors.borderGray.withValues(alpha: 0.5)),
                            const SizedBox(height: 20),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildImagePickerField(
                                      label: 'Vehicle at Kanta Image',
                                      file: _vehicleAtKantaImageFile,
                                      onPick: () => _pickImage(isKantaSlip: false),
                                    ),
                                  ),
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
                              _buildImagePickerField(
                                label: 'Vehicle at Kanta Image',
                                file: _vehicleAtKantaImageFile,
                                onPick: () => _pickImage(isKantaSlip: false),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Remark',
                                controller: _remarkController,
                                hint: 'Remark',
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

  Widget _buildMaterialRow(int index, {required bool isWide}) {
    final line = _lines[index];
    final units = List<String>.from(kMaterialUnits);
    if (line.unit.isNotEmpty && !units.contains(line.unit)) {
      units.insert(0, line.unit);
    }

    final materialField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Material ${index + 1}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<ItemModel>(
          value: line.item,
          decoration: _fieldDecoration(hint: 'Select item'),
          isExpanded: true,
          items: _items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.displayName,
                    style: GoogleFonts.poppins(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() {
            line.item = v;
            line.unit = unitFromMaterial(v);
          }),
        ),
      ],
    );

    final qtyField = _buildTextField(
      label: 'Qty',
      controller: line.qty,
      hint: 'qty',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    );

    final unitField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: units.contains(line.unit) ? line.unit : units.first,
          isExpanded: true,
          decoration: _fieldDecoration(hint: 'Select unit'),
          items: units
              .map(
                (u) => DropdownMenuItem(
                  value: u,
                  child: Text(u, style: GoogleFonts.poppins(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => line.unit = v);
          },
        ),
      ],
    );

    final removeBtn = _lines.length > 1
        ? IconButton(
            onPressed: () => _removeMaterialLine(index),
            tooltip: 'Remove material',
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryRed),
          )
        : null;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: materialField),
          const SizedBox(width: 12),
          Expanded(child: qtyField),
          const SizedBox(width: 12),
          Expanded(child: unitField),
          if (removeBtn != null) ...[
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(top: 24), child: removeBtn),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: materialField),
            if (removeBtn != null) ...[
              const SizedBox(width: 4),
              Padding(padding: const EdgeInsets.only(top: 24), child: removeBtn),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: qtyField),
            const SizedBox(width: 12),
            Expanded(child: unitField),
          ],
        ),
      ],
    );
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

  Widget _buildImagePickerField({
    required String label,
    required File? file,
    required VoidCallback onPick,
  }) {
    final fileName = file?.path.split('/').last;
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
                    color: file == null ? AppColors.textSecondary : AppColors.textDark,
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
