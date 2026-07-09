import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Purchasescreen/purchase.dart';
import 'package:grjoffice_apps/SupplierList/supplier.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  static const _nextGreen = Color(0xFF22C55E);
  static const _saveBlue = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  final _vehicleNoController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController(text: 'Ton');
  final _remarkController = TextEditingController();

  int _step = 0;
  String? _selectedItem;
  PurchaseFlowType? _flowType;
  final DateTime _purchaseDate = DateTime.now();
  String? _selectedSupplier;
  String? _directMaterial;
  String? _loadingImageName;
  DateTime? _loadingImageAt;
  List<String?> _materialLines = [null];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _materialLines = [null];
  }

  @override
  void dispose() {
    _vehicleNoController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  bool get _canProceedStep1 => _selectedItem != null && _flowType != null;

  bool get _isWithoutKanta => _flowType == PurchaseFlowType.withoutKanta;

  bool get _isDirectPurchase => _flowType == PurchaseFlowType.direct;

  List<String> get _chosenMaterials =>
      _materialLines.whereType<String>().where((m) => m.isNotEmpty).toList();

  void _goToNextStep() {
    if (!_canProceedStep1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please choose an item and kanta slip option.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _step = 1;
      if (_isDirectPurchase) {
        _directMaterial = _selectedItem;
      } else {
        _materialLines = [_selectedItem];
      }
    });
  }

  Future<void> _submitInformationPurchaseStep1({required bool withKanta}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a supplier.', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_loadingImageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loading vehicle image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_chosenMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please choose at least one material.', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final vehicleNo = _vehicleNoController.text.trim();
    final materialItems = _chosenMaterials.map((m) => PurchaseMaterialItem(name: m)).toList();
    final prefix = withKanta ? 'WK' : 'NK';
    final purchase = Purchase(
      id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
      date: _purchaseDate,
      challanNo: vehicleNo.isNotEmpty ? vehicleNo : '$prefix-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNo: '—',
      supplierName: _selectedSupplier!,
      status: PurchaseStatus.pending,
      flowType: withKanta ? PurchaseFlowType.withKanta : PurchaseFlowType.withoutKanta,
      vehicleNo: vehicleNo.isEmpty ? null : vehicleNo,
      loadingVehicleImage: _loadingImageName,
      loadingVehicleImageAt: _loadingImageAt,
      materials: materialItems,
      itemName: _chosenMaterials.join(', '),
      withoutKantaStage: withKanta ? null : WithoutKantaStage.initial,
      withKantaStage: withKanta ? WithKantaStage.initial : null,
    );

    Navigator.of(context).pop(purchase);
  }

  Future<void> _submitWithoutKanta() => _submitInformationPurchaseStep1(withKanta: false);

  Future<void> _submitWithKantaStep1() => _submitInformationPurchaseStep1(withKanta: true);

  Future<void> _submitDirectPurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a supplier.', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_directMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a material.', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_loadingImageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final vehicleNo = _vehicleNoController.text.trim();
    final qtyText = _qtyController.text.trim();
    final qty = qtyText.isEmpty ? null : double.tryParse(qtyText);
    final unit = _unitController.text.trim().isEmpty ? 'Ton' : _unitController.text.trim();
    final remark = _remarkController.text.trim();

    final purchase = Purchase(
      id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
      date: _purchaseDate,
      challanNo: vehicleNo.isNotEmpty ? vehicleNo : 'DR-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNo: '—',
      supplierName: _selectedSupplier!,
      status: PurchaseStatus.pending,
      flowType: PurchaseFlowType.direct,
      vehicleNo: vehicleNo.isEmpty ? null : vehicleNo,
      loadingVehicleImage: _loadingImageName,
      loadingVehicleImageAt: _loadingImageAt,
      materials: [PurchaseMaterialItem(name: _directMaterial!, qty: qty, unit: unit)],
      itemName: _directMaterial,
      remark: remark.isEmpty ? null : remark,
      directPurchaseStage: DirectPurchaseStage.completed,
    );

    Navigator.of(context).pop(purchase);
  }

  Future<void> _pickLoadingImage() async {
    setState(() {
      _loadingImageName = 'vehicle_loading.jpg';
      _loadingImageAt = DateTime.now();
    });
  }

  Future<void> _pickMaterial(int index) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose Material',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: kPurchaseItemOptions.map((item) {
                    final selected = _materialLines[index] == item;
                    return _choiceChip(item, selected, () => Navigator.pop(context, item));
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() => _materialLines[index] = picked);
  }

  void _addMaterialLine() {
    setState(() => _materialLines.add(null));
  }

  void _removeMaterialLine(int index) {
    if (_materialLines.length <= 1) return;
    setState(() => _materialLines.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
              color: AppColors.cardWhite,
              child: _buildTopBar(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _step == 0 ? _buildStepChoose() : _buildStepDetails(),
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

  String get _stepTitle {
    if (_step == 0) return 'Create Purchase';
    if (_isDirectPurchase) return 'Information Purchase';
    return 'Step 1 — Information Purchase';
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.pop(context);
            }
          },
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
            _stepTitle,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildStepChoose() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose $kPurchaseItemOptionsTitle / ${kKantaSlipOptions.join(' / ')}',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...kPurchaseItemOptions.map(
              (item) => _choiceChip(
                item,
                _selectedItem == item,
                () => setState(() => _selectedItem = item),
              ),
            ),
            ...kKantaSlipOptions.map((option) {
              final selected = switch (option) {
                'With Kanta' => _flowType == PurchaseFlowType.withKanta,
                'Without Kanta' => _flowType == PurchaseFlowType.withoutKanta,
                _ => _flowType == PurchaseFlowType.direct,
              };
              return _choiceChip(
                option,
                selected,
                () => setState(() {
                  _flowType = switch (option) {
                    'With Kanta' => PurchaseFlowType.withKanta,
                    'Without Kanta' => PurchaseFlowType.withoutKanta,
                    _ => PurchaseFlowType.direct,
                  };
                }),
              );
            }),
          ],
        ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _canProceedStep1 ? _goToNextStep : null,
              icon: const Icon(Icons.add, size: 20),
              label: Text('Next', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _nextGreen,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: _nextGreen.withValues(alpha: 0.45),
                disabledForegroundColor: AppColors.white.withValues(alpha: 0.85),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? const Color(0xFFE5E7EB) : AppColors.cardWhite,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: selected ? null : Border.all(color: AppColors.borderGray),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.headingBlack : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepDetails() {
    if (_isDirectPurchase) {
      return _buildDirectPurchaseForm();
    }
    return _buildInformationPurchaseForm(
      onSave: _isWithoutKanta ? _submitWithoutKanta : _submitWithKantaStep1,
    );
  }

  Widget _buildDirectPurchaseForm() {
    final suppliers = kMockSuppliers.map((s) => s.name).toList();
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormCard(
            title: 'Information Purchase',
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildVehicleNoField()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDirectImageField()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSupplierField(suppliers, required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDirectMaterialField()),
                  ],
                )
              else ...[
                _buildVehicleNoField(),
                const SizedBox(height: 16),
                _buildDirectImageField(),
                const SizedBox(height: 16),
                _buildSupplierField(suppliers, required: true),
                const SizedBox(height: 16),
                _buildDirectMaterialField(),
              ],
              const SizedBox(height: 20),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildQtyField()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildUnitField()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Remark',
                        controller: _remarkController,
                        hint: 'remark',
                      ),
                    ),
                  ],
                )
              else ...[
                _buildQtyField(),
                const SizedBox(height: 16),
                _buildUnitField(),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Remark',
                  controller: _remarkController,
                  hint: 'remark',
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitDirectPurchase,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.assignment_outlined, size: 18),
                label: Text('Save', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
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
    );
  }

  Widget _buildDirectMaterialField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            children: const [
              TextSpan(text: 'Material '),
              TextSpan(text: '*', style: TextStyle(color: AppColors.primaryRed)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _directMaterial,
          decoration: _inputDecoration(hint: '-- Select an option --'),
          items: kPurchaseItemOptions
              .map((item) => DropdownMenuItem(value: item, child: Text(item, style: GoogleFonts.poppins(fontSize: 13))))
              .toList(),
          onChanged: (value) => setState(() => _directMaterial = value),
          validator: (value) => value == null ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDirectImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            children: const [
              TextSpan(text: 'Image '),
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
                onPressed: _pickLoadingImage,
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
                  _loadingImageName ?? 'No file selected.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _loadingImageName == null ? AppColors.textSecondary : AppColors.textDark,
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

  Widget _buildQtyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Qty', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _qtyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _inputDecoration(hint: 'qty'),
        ),
      ],
    );
  }

  Widget _buildUnitField() {
    return _buildTextField(
      label: 'Unit',
      controller: _unitController,
      hint: 'Ton',
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
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

  Widget _buildInformationPurchaseForm({required Future<void> Function() onSave}) {
    final suppliers = kMockSuppliers.map((s) => s.name).toList();
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormCard(
            title: 'Information Purchase',
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildVehicleNoField()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildLoadingImageField()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSupplierField(suppliers)),
                  ],
                )
              else ...[
                _buildVehicleNoField(),
                const SizedBox(height: 16),
                _buildLoadingImageField(),
                const SizedBox(height: 16),
                _buildSupplierField(suppliers),
              ],
              const SizedBox(height: 20),
              Text('Material', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...List.generate(_materialLines.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index < _materialLines.length - 1 ? 10 : 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickMaterial(index),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDark,
                            backgroundColor: AppColors.cardWhite,
                            side: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _materialLines[index] ?? 'Please Choose',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _materialLines[index] == null
                                    ? AppColors.textSecondary
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_materialLines.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeMaterialLine(index),
                          icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                      if (index == _materialLines.length - 1) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _addMaterialLine,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text('Add More', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _nextGreen,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          _buildSaveButton(onPressed: onSave, label: 'Save Step 1'),
        ],
      ),
    );
  }

  Widget _buildVehicleNoField() {
    return _buildTextField(
      label: 'Vehicle No',
      controller: _vehicleNoController,
      hint: 'Vehicle No',
    );
  }

  Widget _buildLoadingImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            children: const [
              TextSpan(text: 'Loading Vehicle Image '),
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
                onPressed: _pickLoadingImage,
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
                  _loadingImageName ?? 'No file selected.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _loadingImageName == null ? AppColors.textSecondary : AppColors.textDark,
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

  Widget _buildSaveButton({required Future<void> Function() onPressed, String label = 'Save Purchase'}) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: _isSaving ? null : onPressed,
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
            : Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFormCard({String? title, required List<Widget> children}) {
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
          if (title != null) ...[
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildSupplierField(List<String> suppliers, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (required)
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
              children: const [
                TextSpan(text: 'Supplier '),
                TextSpan(text: '*', style: TextStyle(color: AppColors.primaryRed)),
              ],
            ),
          )
        else
          Text('Supplier', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSupplier,
          decoration: _inputDecoration(hint: '-- Select an option --'),
          items: suppliers
              .map((name) => DropdownMenuItem(value: name, child: Text(name, style: GoogleFonts.poppins(fontSize: 13))))
              .toList(),
          onChanged: (value) => setState(() => _selectedSupplier = value),
          validator: (value) => value == null ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
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
          ),
          validator: required
              ? (value) => (value == null || value.trim().isEmpty) ? 'Required' : null
              : null,
        ),
      ],
    );
  }
}
