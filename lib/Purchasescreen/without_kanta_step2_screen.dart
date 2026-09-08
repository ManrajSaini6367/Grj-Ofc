import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase_multi_image_picker.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/image_pick_helper.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class WithoutKantaStep2Screen extends StatefulWidget {
  const WithoutKantaStep2Screen({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<WithoutKantaStep2Screen> createState() => _WithoutKantaStep2ScreenState();
}

class _MaterialLine {
  _MaterialLine({
    String? qtyText,
    this.unit = 'Ton',
    this.lockedItemId,
    this.lockedName,
  }) : qty = TextEditingController(text: qtyText ?? '');

  ItemModel? item;
  final int? lockedItemId;
  final String? lockedName;
  final TextEditingController qty;
  String unit;

  int? get itemId => item?.id ?? lockedItemId;

  String get displayName {
    final fromItem = item?.displayName.trim() ?? '';
    if (fromItem.isNotEmpty) return fromItem;
    final fromLock = lockedName?.trim() ?? '';
    if (fromLock.isNotEmpty) return fromLock;
    return '—';
  }

  void dispose() => qty.dispose();
}

class _WithoutKantaStep2ScreenState extends State<WithoutKantaStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _remarkController = TextEditingController();
  final List<_MaterialLine> _lines = [];

  final List<File> _unloadingImages = [];
  bool _isSaving = false;

  List<ItemModel> _items = [];
  bool _loadingItems = true;

  String get _savedVehicleNo => widget.purchase.vehicleNo?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _invoiceController.text = p.invoiceNo == '—' ? '' : p.invoiceNo;
    _remarkController.text = p.remark ?? '';

    if (p.materials.isEmpty) {
      _lines.add(_MaterialLine());
    } else {
      for (final m in p.materials) {
        _lines.add(
          _MaterialLine(
            qtyText: m.qty != null ? _formatQty(m.qty!) : null,
            unit: m.unit.trim().isEmpty ? 'Ton' : m.unit.trim(),
            lockedItemId: m.itemId,
            lockedName: m.name,
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
      if (matched != null) {
        _lines[i].unit = unitFromMaterial(matched);
      }
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _remarkController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  String _formatQty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();

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
        SnackBar(content: Text('Unloading vehicle image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final materials = <PurchaseMaterialPayload>[];
    for (final line in _lines) {
      final itemId = line.itemId;
      if (itemId == null) continue;
      final qtyVal = double.tryParse(line.qty.text.trim());
      if (qtyVal == null || qtyVal <= 0) continue;
      materials.add(
        PurchaseMaterialPayload(
          itemId: itemId,
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

    final invoiceNo = _invoiceController.text.trim();
    if (invoiceNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice No is required.', style: GoogleFonts.poppins())),
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
    final updated = await purchaseStep2WithoutKantaApi(
      context,
      purchaseId: purchaseId,
      invoiceNo: invoiceNo,
      remark: remark.isEmpty ? null : remark,
      materials: materials,
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
                      child: _buildFormCard(isWide: isWide),
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

  Widget _buildFormCard({required bool isWide}) {
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
                Expanded(child: _buildReadOnlyField(label: 'Supplier', value: widget.purchase.supplierName)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReadOnlyField(
                    label: 'Vehicle No',
                    value: _savedVehicleNo.isEmpty ? '—' : _savedVehicleNo,
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
              ],
            )
          else ...[
            _buildReadOnlyField(label: 'Supplier', value: widget.purchase.supplierName),
            const SizedBox(height: 16),
            _buildReadOnlyField(
              label: 'Vehicle No',
              value: _savedVehicleNo.isEmpty ? '—' : _savedVehicleNo,
            ),
            const SizedBox(height: 16),
            _buildTextField(label: 'Invoice No', controller: _invoiceController, hint: 'Invoice no'),
          ],
          const SizedBox(height: 20),
          if (_loadingItems)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else ...[
            ...List.generate(_lines.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index < _lines.length - 1 ? 16 : 0),
                child: _buildMaterialRow(index, isWide: isWide),
              );
            }),
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
            width: double.infinity,
            height: 48,
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

  Widget _buildMaterialRow(int index, {required bool isWide}) {
    final line = _lines[index];
    final units = List<String>.from(kMaterialUnits);
    if (line.unit.isNotEmpty && !units.contains(line.unit)) {
      units.insert(0, line.unit);
    }

    final materialField = _buildReadOnlyField(
      label: 'Material ${index + 1}',
      value: line.displayName,
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

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: materialField),
          const SizedBox(width: 12),
          Expanded(child: qtyField),
          const SizedBox(width: 12),
          Expanded(child: unitField),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        materialField,
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

  Widget _buildUnloadingImageField() {
    return PurchaseMultiImagePicker(
      label: 'Unloading Vehicle Image',
      files: _unloadingImages,
      onAdd: _pickUnloadingImage,
      onRemoveAt: _removeUnloadingImage,
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
