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
  final _remarkController = TextEditingController();
  String _unit = 'Ton';

  int _step = 0;
  ItemModel? _selectedItem;
  PurchaseFlowType? _flowType;
  int? _selectedSupplierId;
  String? _selectedSupplierName;
  ItemModel? _directMaterial;
  String? _loadingImageName;
  File? _loadingImageFile;
  List<ItemModel?> _materialLines = [null];
  bool _isSaving = false;

  List<ItemModel> _items = [];
  List<({int id, String name})> _suppliers = [];
  /// Materials assigned to the currently selected supplier.
  List<ItemModel> _supplierMaterials = [];
  bool _loadingLookups = true;
  bool _loadingSuppliers = false;
  bool _loadingSupplierMaterials = false;
  /// true = last load was /suppliers/by-item; false = old /suppliers list
  bool _suppliersFilteredByItem = false;

  @override
  void initState() {
    super.initState();
    _materialLines = [null];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLookups();
      _recoverLostCameraImage();
    });
  }

  Future<void> _recoverLostCameraImage() async {
    final file = await recoverLostPurchaseImage();
    if (file == null || !mounted) return;
    setState(() {
      _loadingImageFile = file;
      _loadingImageName = file.path.split(Platform.pathSeparator).last;
    });
  }

  Future<void> _loadLookups() async {
    final itemsResult = await itemsApi(
      context,
      perPage: 15,
      fetchAllPages: true,
      purchase: '1',
    );
    if (!mounted) return;

    setState(() {
      _items = itemsResult ?? [];
      _loadingLookups = false;
    });
  }

  Future<void> _onItemSelected(ItemModel item) async {
    // Portal: picking a material = direct purchase (single step).
    setState(() {
      _selectedItem = item;
      _flowType = PurchaseFlowType.direct;
      _unit = unitFromMaterial(item);
      _selectedSupplierId = null;
      _selectedSupplierName = null;
      _suppliers = [];
      _supplierMaterials = [];
      _suppliersFilteredByItem = true;
      _loadingSuppliers = true;
    });

    final response = await getSuppliersByItemApi(
      context,
      itemId: item.id,
      perPage: 100,
    );
    if (!mounted) return;
    if (_selectedItem?.id != item.id || _flowType != PurchaseFlowType.direct) {
      return;
    }

    setState(() {
      _suppliers = (response?.data?.items ?? [])
          .where((s) => s.id != null && (s.name ?? '').trim().isNotEmpty)
          .map((s) => (id: s.id!, name: s.name!.trim()))
          .toList();
      _loadingSuppliers = false;
    });
  }

  Future<void> _onKantaOptionSelected(PurchaseFlowType flowType) async {
    // Portal: With/Without Kanta are mutually exclusive with material chips.
    setState(() {
      _flowType = flowType;
      _selectedItem = null;
      _selectedSupplierId = null;
      _selectedSupplierName = null;
      _suppliers = [];
      _supplierMaterials = [];
      _suppliersFilteredByItem = false;
      _loadingSuppliers = true;
    });

    // With/Without Kanta are not items — use full suppliers API.
    final response = await getSuppliersApi(
      context,
      perPage: 15,
      fetchAllPages: true,
    );
    if (!mounted) return;
    if (_flowType != flowType) return;

    setState(() {
      _suppliers = (response?.data?.items ?? [])
          .where((s) => s.id != null && (s.name ?? '').trim().isNotEmpty)
          .map((s) => (id: s.id!, name: s.name!.trim()))
          .toList();
      _loadingSuppliers = false;
    });
  }

  @override
  void dispose() {
    _vehicleNoController.dispose();
    _qtyController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  /// Portal: one chip only — material (direct) OR With/Without Kanta.
  bool get _canProceedStep1 {
    if (_flowType == PurchaseFlowType.direct) return _selectedItem != null;
    return _flowType == PurchaseFlowType.withKanta ||
        _flowType == PurchaseFlowType.withoutKanta;
  }

  bool get _isWithoutKanta => _flowType == PurchaseFlowType.withoutKanta;

  bool get _isDirectPurchase => _flowType == PurchaseFlowType.direct;

  List<ItemModel> get _chosenMaterials =>
      _materialLines.whereType<ItemModel>().toList();

  /// Materials available for the selected supplier (empty until a supplier is chosen).
  List<ItemModel> get _materialOptions => _supplierMaterials;

  String get _chooseTitle {
    final names = _items.map((i) => i.displayName).where((n) => n.trim().isNotEmpty);
    final parts = [...names, ...kKantaSlipOptions];
    if (parts.isEmpty) return 'Choose Material / ${kKantaSlipOptions.join(' / ')}';
    return 'Choose ${parts.join(' / ')}';
  }

  void _goToNextStep() {
    if (!_canProceedStep1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please choose a material, or With / Without Kanta.',
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
        _unit = unitFromMaterial(_selectedItem);
      } else {
        // Materials are chosen later in With/Without Kanta step 1.
        _materialLines = [null];
      }
    });
  }

  Future<void> _submitInformationPurchaseStep1({required bool withKanta}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a supplier.', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_loadingImageFile == null) {
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

    final purchase = await createPurchaseApi(
      context,
      flowType: withKanta ? 'with_kanta' : 'without_kanta',
      supplierId: _selectedSupplierId!,
      vehicleNo: _vehicleNoController.text.trim(),
      imageFile: _loadingImageFile!,
      itemIds: _chosenMaterials.map((m) => m.id).toList(),
    );

    if (!mounted) return;

    if (purchase != null) {
      Navigator.of(context).pop(purchase);
    } else {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _submitWithoutKanta() => _submitInformationPurchaseStep1(withKanta: false);

  Future<void> _submitWithKantaStep1() => _submitInformationPurchaseStep1(withKanta: true);

  Future<void> _submitDirectPurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) {
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
    if (_loadingImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image is required.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final qtyText = _qtyController.text.trim();
    final qty = double.tryParse(qtyText) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid quantity greater than 0.', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() => _isSaving = true);

    final unit = _unit.trim().isEmpty ? 'Ton' : _unit.trim();
    final remark = _remarkController.text.trim();

    final purchase = await createPurchaseApi(
      context,
      flowType: 'direct',
      supplierId: _selectedSupplierId!,
      vehicleNo: _vehicleNoController.text.trim(),
      imageFile: _loadingImageFile!,
      materials: [PurchaseMaterialPayload(itemId: _directMaterial!.id, qty: qty, unit: unit)],
      remark: remark.isEmpty ? null : remark,
    );

    if (!mounted) return;

    if (purchase != null) {
      Navigator.of(context).pop(purchase);
    } else {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickLoadingImage() async {
    final file = await pickPurchaseImageFile(
      context,
      title: 'Loading Vehicle Image',
      fromCamera: true,
    );
    if (!mounted) return;
    if (file == null) return;

    setState(() {
      _loadingImageFile = file;
      _loadingImageName = file.path.split(Platform.pathSeparator).last;
    });
  }

  Future<void> _pickSupplier() async {
    if (_selectedItem == null && _flowType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please choose an item or kanta option first.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<({int id, String name})>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _SupplierSearchSheet(
          itemId: _suppliersFilteredByItem ? _selectedItem?.id : null,
          initialSuppliers: _suppliers,
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedSupplierId = picked.id;
      _selectedSupplierName = picked.name;
      if (!_suppliers.any((s) => s.id == picked.id)) {
        _suppliers = [..._suppliers, picked];
      }
      _loadingSupplierMaterials = true;
      _supplierMaterials = [];
    });

    await _loadMaterialsForSupplier(picked.id);
  }

  Future<void> _loadMaterialsForSupplier(int supplierId) async {
    final materials = await loadSupplierMaterials(
      context,
      supplierId,
      catalog: _items,
    );
    if (!mounted) return;
    if (_selectedSupplierId != supplierId) return;

    setState(() {
      _supplierMaterials = materials;
      _loadingSupplierMaterials = false;

      // Keep current material only if this supplier actually supplies it.
      if (_directMaterial != null &&
          !_supplierMaterials.any((m) => m.id == _directMaterial!.id)) {
        _directMaterial = null;
      } else if (_directMaterial != null) {
        _directMaterial = _supplierMaterials.firstWhere(
          (m) => m.id == _directMaterial!.id,
        );
        _unit = unitFromMaterial(_directMaterial);
      }

      _materialLines = _materialLines.map((line) {
        if (line == null) return null;
        return _supplierMaterials.cast<ItemModel?>().firstWhere(
              (m) => m?.id == line.id,
              orElse: () => null,
            );
      }).toList();
      if (_materialLines.isEmpty) _materialLines = [null];
    });
  }

  Future<void> _pickMaterial(int index) async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a supplier first.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }
    if (_loadingSupplierMaterials) return;

    final options = _materialOptions;
    final picked = await showModalBottomSheet<ItemModel>(
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
                if (options.isEmpty)
                  Text(
                    'No materials assigned to this supplier.',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: options.map((item) {
                      final selected = _materialLines[index]?.id == item.id;
                      return _choiceChip(
                        item.displayName,
                        selected,
                        () => Navigator.pop(context, item),
                      );
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

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_step == 1) {
          setState(() => _step = 0);
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: _stepTitle,
              onBack: () {
                if (_step == 1) {
                  setState(() => _step = 0);
                } else {
                  Navigator.pop(context);
                }
              },
              horizontalPadding: hPad,
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

  Widget _buildStepChoose() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _chooseTitle,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        if (_loadingLookups)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (_items.isEmpty && kKantaSlipOptions.isEmpty)
                Text(
                  'No options available.',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                ),
              ..._items.map(
                (item) => _choiceChip(
                  item.displayName,
                  _flowType == PurchaseFlowType.direct && _selectedItem?.id == item.id,
                  () => _onItemSelected(item),
                ),
              ),
              ...kKantaSlipOptions.map((option) {
                final selected = switch (option) {
                  'With Kanta' => _flowType == PurchaseFlowType.withKanta,
                  _ => _flowType == PurchaseFlowType.withoutKanta,
                };
                return _choiceChip(
                  option,
                  selected,
                  () => _onKantaOptionSelected(
                    option == 'With Kanta'
                        ? PurchaseFlowType.withKanta
                        : PurchaseFlowType.withoutKanta,
                  ),
                );
              }),
            ],
          ),
        if (_loadingSuppliers) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    Expanded(child: _buildSupplierField(required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDirectMaterialField()),
                  ],
                )
              else ...[
                _buildVehicleNoField(),
                const SizedBox(height: 16),
                _buildDirectImageField(),
                const SizedBox(height: 16),
                _buildSupplierField(required: true),
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
          SizedBox(
            width: double.infinity,
            height: 48,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectMaterialField() {
    final options = _materialOptions;
    final selectedId = _directMaterial != null &&
            options.any((m) => m.id == _directMaterial!.id)
        ? _directMaterial!.id
        : null;

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
        DropdownButtonFormField<int>(
          value: selectedId,
          decoration: _inputDecoration(
            hint: _selectedSupplierId == null
                ? 'Select supplier first'
                : _loadingSupplierMaterials
                    ? 'Loading materials...'
                    : options.isEmpty
                        ? 'No materials for this supplier'
                        : '-- Select an option --',
          ),
          items: options
              .map((item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.displayName, style: GoogleFonts.poppins(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (_selectedSupplierId == null ||
                  _loadingSupplierMaterials ||
                  options.isEmpty)
              ? null
              : (value) => setState(() {
                    _directMaterial = value != null
                        ? options.where((i) => i.id == value).firstOrNull
                        : null;
                    _unit = unitFromMaterial(_directMaterial);
                  }),
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
    final units = List<String>.from(kMaterialUnits);
    if (_unit.isNotEmpty && !units.contains(_unit)) {
      units.insert(0, _unit);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unit',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: units.contains(_unit) ? _unit : units.first,
          isExpanded: true,
          items: units
              .map(
                (u) => DropdownMenuItem(
                  value: u,
                  child: Text(u, style: GoogleFonts.poppins(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _unit = v);
          },
          decoration: _inputDecoration(hint: 'Select unit'),
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
        ),
      ],
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
                    Expanded(child: _buildSupplierField()),
                  ],
                )
              else ...[
                _buildVehicleNoField(),
                const SizedBox(height: 16),
                _buildLoadingImageField(),
                const SizedBox(height: 16),
                _buildSupplierField(),
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
                              _materialLines[index]?.displayName ?? 'Please Choose',
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
       required: true,
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
      width: double.infinity,
      height: 48,
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

  Widget _buildSupplierField({bool required = false}) {
    final selectedName = _selectedSupplierName ??
        _suppliers.where((s) => s.id == _selectedSupplierId).map((s) => s.name).firstOrNull;

    return FormField<int>(
      initialValue: _selectedSupplierId,
      validator: (_) => _selectedSupplierId == null ? 'Required' : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (required)
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  children: const [
                    TextSpan(text: 'Supplier '),
                    TextSpan(text: '*', style: TextStyle(color: AppColors.primaryRed)),
                  ],
                ),
              )
            else
              Text(
                'Supplier',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 8),
            InkWell(
              onTap: (_loadingLookups || _loadingSuppliers || (_selectedItem == null && _flowType == null))
                  ? null
                  : _pickSupplier,
              borderRadius: BorderRadius.circular(6),
              child: InputDecorator(
                decoration: _inputDecoration(
                  hint: _loadingSuppliers
                      ? 'Loading suppliers...'
                      : (_selectedItem == null && _flowType == null)
                          ? 'Choose item or kanta option first'
                          : 'Search & select supplier',
                ).copyWith(
                  errorText: field.errorText,
                  suffixIcon: _loadingSuppliers
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        )
                      : const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                ),
                child: Text(
                  selectedName ??
                      (_loadingSuppliers
                          ? 'Loading suppliers...'
                          : (_selectedItem == null && _flowType == null)
                              ? 'Choose item or kanta option first'
                              : 'Search & select supplier'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: selectedName == null ? AppColors.inputHint : AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
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

class _SupplierSearchSheet extends StatefulWidget {
  const _SupplierSearchSheet({
    this.itemId,
    required this.initialSuppliers,
  });

  /// When set, search uses /suppliers/by-item. Otherwise old /suppliers list.
  final int? itemId;
  final List<({int id, String name})> initialSuppliers;

  @override
  State<_SupplierSearchSheet> createState() => _SupplierSearchSheetState();
}

class _SupplierSearchSheetState extends State<_SupplierSearchSheet> {
  final _searchController = TextEditingController();
  late List<({int id, String name})> _results;
  bool _isSearching = false;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _results = List<({int id, String name})>.from(widget.initialSuppliers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    final token = ++_searchToken;
    final keyword = query.trim();

    if (keyword.isEmpty) {
      setState(() {
        _results = List<({int id, String name})>.from(widget.initialSuppliers);
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || token != _searchToken) return;

    final local = widget.initialSuppliers
        .where((s) => s.name.toLowerCase().contains(keyword.toLowerCase()))
        .toList();

    final response = widget.itemId != null
        ? await getSuppliersByItemApi(
            context,
            itemId: widget.itemId!,
            search: keyword,
            perPage: 50,
          )
        : await getSuppliersApi(
            context,
            search: keyword,
            perPage: 15,
            fetchAllPages: true,
          );
    if (!mounted || token != _searchToken) return;

    final apiResults = (response?.data?.items ?? [])
        .where((s) => s.id != null && (s.name ?? '').trim().isNotEmpty)
        .map((s) => (id: s.id!, name: s.name!.trim()))
        .toList();

    final merged = <int, ({int id, String name})>{
      for (final s in local) s.id: s,
      for (final s in apiResults) s.id: s,
    };

    setState(() {
      _results = merged.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        height: MediaQuery.sizeOf(context).height * 0.65,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Supplier',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search supplier...',
                  hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.operationsCardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.5), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          'No suppliers found',
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppColors.borderGray.withValues(alpha: 0.4),
                        ),
                        itemBuilder: (context, index) {
                          final supplier = _results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              supplier.name,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                            onTap: () => Navigator.pop(context, supplier),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
