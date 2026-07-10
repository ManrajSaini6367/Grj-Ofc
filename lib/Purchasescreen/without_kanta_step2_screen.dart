import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class WithoutKantaStep2Screen extends StatefulWidget {
  const WithoutKantaStep2Screen({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<WithoutKantaStep2Screen> createState() => _WithoutKantaStep2ScreenState();
}

class _WithoutKantaStep2ScreenState extends State<WithoutKantaStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _remarkController = TextEditingController();
  final _qty1Controller = TextEditingController();
  final _qty2Controller = TextEditingController();
  final _unit1Controller = TextEditingController(text: 'NOS');
  final _unit2Controller = TextEditingController(text: 'NOS');

  ItemModel? _selectedItem1;
  ItemModel? _selectedItem2;
  File? _unloadingImageFile;
  bool _isSaving = false;

  List<ItemModel> _items = [];
  bool _loadingItems = true;

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _invoiceController.text = p.invoiceNo == '—' ? '' : p.invoiceNo;
    _remarkController.text = p.remark ?? '';

    if (p.materials.isNotEmpty) {
      if (p.materials[0].qty != null) _qty1Controller.text = _formatQty(p.materials[0].qty!);
      _unit1Controller.text = p.materials[0].unit;
    }
    if (p.materials.length > 1) {
      if (p.materials[1].qty != null) _qty2Controller.text = _formatQty(p.materials[1].qty!);
      _unit2Controller.text = p.materials[1].unit;
    }

    _loadItems();
  }

  Future<void> _loadItems() async {
    final cached = cachedItems();
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _items = cached;
        _loadingItems = false;
        _prefillItems();
      });
      return;
    }
    final items = await itemsApi(context);
    if (!mounted) return;
    setState(() {
      _items = items ?? [];
      _loadingItems = false;
      _prefillItems();
    });
  }

  void _prefillItems() {
    final p = widget.purchase;
    if (p.materials.isNotEmpty && p.materials[0].itemId != null) {
      _selectedItem1 = _items.cast<ItemModel?>().firstWhere(
            (it) => it?.id == p.materials[0].itemId,
            orElse: () => null,
          );
    }
    if (p.materials.length > 1 && p.materials[1].itemId != null) {
      _selectedItem2 = _items.cast<ItemModel?>().firstWhere(
            (it) => it?.id == p.materials[1].itemId,
            orElse: () => null,
          );
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _remarkController.dispose();
    _qty1Controller.dispose();
    _qty2Controller.dispose();
    _unit1Controller.dispose();
    _unit2Controller.dispose();
    super.dispose();
  }

  String _formatQty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();

  Future<void> _pickUnloadingImage() async {
    final picker = ImagePicker();
    XFile? picked = await picker.pickImage(source: ImageSource.camera);
    picked ??= await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _unloadingImageFile = File(picked!.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_unloadingImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unloading vehicle image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final materials = <PurchaseMaterialPayload>[];
    void addMaterial(ItemModel? item, TextEditingController qty, TextEditingController unit) {
      if (item == null) return;
      final qtyVal = double.tryParse(qty.text.trim());
      if (qtyVal == null) return;
      materials.add(PurchaseMaterialPayload(
        itemId: item.id,
        qty: qtyVal,
        unit: unit.text.trim().isEmpty ? 'NOS' : unit.text.trim(),
      ));
    }

    addMaterial(_selectedItem1, _qty1Controller, _unit1Controller);
    addMaterial(_selectedItem2, _qty2Controller, _unit2Controller);

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
                Expanded(child: _buildTextField(label: 'Invoice No', controller: _invoiceController, hint: 'Invoice no')),
              ],
            )
          else ...[
            _buildReadOnlyField(label: 'Supplier', value: widget.purchase.supplierName),
            const SizedBox(height: 16),
            _buildTextField(label: 'Invoice No', controller: _invoiceController, hint: 'Invoice no'),
          ],
          const SizedBox(height: 20),
          if (_loadingItems)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMaterialGroup(1, _selectedItem1, _qty1Controller, _unit1Controller,
                    onItemChanged: (v) => setState(() => _selectedItem1 = v))),
                const SizedBox(width: 12),
                Expanded(child: _buildMaterialGroup(2, _selectedItem2, _qty2Controller, _unit2Controller,
                    onItemChanged: (v) => setState(() => _selectedItem2 = v))),
              ],
            )
          else ...[
            _buildMaterialGroup(1, _selectedItem1, _qty1Controller, _unit1Controller,
                onItemChanged: (v) => setState(() => _selectedItem1 = v)),
            const SizedBox(height: 16),
            _buildMaterialGroup(2, _selectedItem2, _qty2Controller, _unit2Controller,
                onItemChanged: (v) => setState(() => _selectedItem2 = v)),
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
    ItemModel? selectedItem,
    TextEditingController qty,
    TextEditingController unit, {
    required ValueChanged<ItemModel?> onItemChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildItemDropdown(label: 'Material $index', selectedItem: selectedItem, onChanged: onItemChanged),
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

  Widget _buildItemDropdown({
    required String label,
    required ItemModel? selectedItem,
    required ValueChanged<ItemModel?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<ItemModel>(
          value: selectedItem,
          decoration: _fieldDecoration(hint: 'Select item'),
          isExpanded: true,
          items: _items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item.name, style: GoogleFonts.poppins(fontSize: 13), overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
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
