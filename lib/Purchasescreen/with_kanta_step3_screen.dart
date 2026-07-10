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

class WithKantaStep3Screen extends StatefulWidget {
  const WithKantaStep3Screen({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<WithKantaStep3Screen> createState() => _WithKantaStep3ScreenState();
}

class _WithKantaStep3ScreenState extends State<WithKantaStep3Screen> {
  static const _saveBlue = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _kantaNoController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController(text: 'NOS');
  final _remarkController = TextEditingController();

  ItemModel? _selectedItem;
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

    if (p.materials.isNotEmpty && p.materials.first.qty != null) {
      final qty = p.materials.first.qty!;
      _qtyController.text = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
      _unitController.text = p.materials.first.unit;
    }

    _loadItems();
  }

  Future<void> _loadItems() async {
    final cached = cachedItems();
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _items = cached;
        _loadingItems = false;
        _prefillItem();
      });
      return;
    }
    final items = await itemsApi(context);
    if (!mounted) return;
    setState(() {
      _items = items ?? [];
      _loadingItems = false;
      _prefillItem();
    });
  }

  void _prefillItem() {
    final p = widget.purchase;
    if (p.materials.isNotEmpty && p.materials.first.itemId != null) {
      _selectedItem = _items.cast<ItemModel?>().firstWhere(
            (it) => it?.id == p.materials.first.itemId,
            orElse: () => null,
          );
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _kantaNoController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isKantaSlip}) async {
    final picker = ImagePicker();
    XFile? picked = await picker.pickImage(source: ImageSource.camera);
    picked ??= await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isKantaSlip) {
          _kantaSlipImageFile = File(picked!.path);
        } else {
          _vehicleAtKantaImageFile = File(picked!.path);
        }
      });
    }
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
    if (invoiceNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice No is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final kantaNo = _kantaNoController.text.trim();
    if (kantaNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kanta No is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a material.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final qtyVal = double.tryParse(_qtyController.text.trim());
    if (qtyVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid quantity.', style: GoogleFonts.poppins())),
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

    final unit = _unitController.text.trim().isEmpty ? 'NOS' : _unitController.text.trim();
    final remark = _remarkController.text.trim();
    final materials = [PurchaseMaterialPayload(itemId: _selectedItem!.id, qty: qtyVal, unit: unit)];

    setState(() => _isSaving = true);
    final updated = await purchaseStep3WithKantaApi(
      context,
      purchaseId: purchaseId,
      invoiceNo: invoiceNo,
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
                                  Expanded(child: _buildReadOnlyField(label: 'Supplier', value: widget.purchase.supplierName)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Invoice No',
                                      controller: _invoiceController,
                                      hint: 'Invoice no',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildImagePickerField(
                                    label: 'Kanta Slip Image',
                                    file: _kantaSlipImageFile,
                                    onPick: () => _pickImage(isKantaSlip: true),
                                  )),
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
                              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                            else if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildItemDropdown()),
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
                              _buildItemDropdown(),
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
                                  Expanded(child: _buildImagePickerField(
                                    label: 'Vehicle at Kanta Image',
                                    file: _vehicleAtKantaImageFile,
                                    onPick: () => _pickImage(isKantaSlip: false),
                                  )),
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

  Widget _buildItemDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Material 1', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<ItemModel>(
          value: _selectedItem,
          decoration: _fieldDecoration(hint: 'Select item'),
          isExpanded: true,
          items: _items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item.name, style: GoogleFonts.poppins(fontSize: 13), overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedItem = v),
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
