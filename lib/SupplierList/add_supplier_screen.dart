import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/SupplierList/supplier.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key, this.supplier});

  final Supplier? supplier;

  bool get isEditing => supplier != null;

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _materialSearchController = TextEditingController();
  final _gstController = TextEditingController();
  final _panController = TextEditingController();
  final _addressController = TextEditingController();

  final List<ItemModel> _selectedItems = [];
  List<ItemModel> _materialSuggestions = [];
  SupplierStatus _status = SupplierStatus.published;
  bool _showMaterialSuggestions = false;
  bool _isMaterialSearching = false;
  bool _isSaving = false;
  bool _isLoadingSupplier = false;
  Timer? _materialSearchDebounce;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    if (supplier != null) {
      _nameController.text = supplier.name;
      _mobileController.text = supplier.mobile;
      _gstController.text = supplier.gstNo;
      _panController.text = supplier.panNo;
      _addressController.text = supplier.address;
      _status = supplier.status;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSupplierForEdit());
    }
    _materialSearchController.addListener(_onMaterialSearchChanged);
  }

  Future<void> _loadSupplierForEdit() async {
    final supplierId = int.tryParse(widget.supplier?.id ?? '');
    if (supplierId == null) return;

    setState(() => _isLoadingSupplier = true);
    final response = await getSupplierApi(context, supplierId);
    if (!mounted) return;

    final items = response?.data?.items ?? [];
    setState(() {
      _selectedItems
        ..clear()
        ..addAll(
          items.map(
            (item) => ItemModel(
              id: item.id ?? 0,
              siteId: response?.data?.siteId ?? 0,
              name: item.name ?? '',
              unit: item.unit ?? '',
              status: 'published',
            ),
          ),
        );
      _isLoadingSupplier = false;
    });
  }

  void _onMaterialSearchChanged() {
    final query = _materialSearchController.text.trim();
    setState(() => _showMaterialSuggestions = query.isNotEmpty);

    _materialSearchDebounce?.cancel();
    if (query.length < 3) {
      setState(() {
        _materialSuggestions = [];
        _isMaterialSearching = false;
      });
      return;
    }

    _materialSearchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _searchMaterials(query);
    });
  }

  Future<void> _searchMaterials(String keyword) async {
    setState(() => _isMaterialSearching = true);
    final items = await itemsSearchApi(context, keyword: keyword);
    if (!mounted) return;
    setState(() {
      _materialSuggestions = items
              ?.where(
                (item) =>
                    !_selectedItems.any((selected) => selected.id == item.id),
              )
              .toList() ??
          [];
      _isMaterialSearching = false;
    });
  }

  @override
  void dispose() {
    _materialSearchDebounce?.cancel();
    _nameController.dispose();
    _mobileController.dispose();
    _materialSearchController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _addMaterial(ItemModel item) {
    setState(() {
      if (!_selectedItems.any((selected) => selected.id == item.id)) {
        _selectedItems.add(item);
      }
      _materialSearchController.clear();
      _materialSuggestions = [];
      _showMaterialSuggestions = false;
    });
  }

  void _removeItem(ItemModel item) {
    setState(() => _selectedItems.removeWhere((selected) => selected.id == item.id));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one material.')),
      );
      return;
    }

    final itemIds = _selectedItems.map((item) => item.id).toList();
    final materialNames = _selectedItems.map((item) => item.displayName).toList();
    final status =
        _status == SupplierStatus.published ? 'published' : 'unpublished';

    if (widget.isEditing) {
      final supplierId = int.tryParse(widget.supplier!.id);
      if (supplierId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid supplier id.')),
        );
        return;
      }

      setState(() => _isSaving = true);
      final supplier = await updateSupplierApi(
        context,
        supplierId: supplierId,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        gstNo: _gstController.text.trim(),
        panNo: _panController.text.trim(),
        status: status,
        itemIds: itemIds,
        materialNames: materialNames,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (supplier != null) {
        Navigator.of(context).pop(supplier);
      }
      return;
    }

    final siteId = selectedSiteId();
    if (siteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a site first.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final supplier = await createSupplierApi(
      context,
      siteId: siteId,
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      address: _addressController.text.trim(),
      gstNo: _gstController.text.trim(),
      panNo: _panController.text.trim(),
      status: status,
      itemIds: itemIds,
      materialNames: materialNames,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (supplier != null) {
      Navigator.of(context).pop(supplier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: widget.isEditing ? 'Edit Supplier' : 'Create Supplier',
              onBack: () => Navigator.of(context).pop(),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildFormCard(),
                          const SizedBox(height: 24),
                          _buildSaveButton(),
                          const SizedBox(height: 12),
                          _buildCancelButton(),
                        ],
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
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditing ? 'Update Supplier' : 'New Supplier',
          style: GoogleFonts.poppins(
            color: AppColors.headingBlack,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter supplier details and assign materials.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
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
          _buildTextField(
            label: 'Name',
            controller: _nameController,
            hint: 'Supplier name',
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Mobile',
            controller: _mobileController,
            hint: '+91 98765 43210',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Mobile is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildMaterialField(),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'GST NO',
            controller: _gstController,
            hint: '27AABCS1429B1Z5',
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'GST number is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'PAN NO',
            controller: _panController,
            hint: 'AABCS1429B',
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'PAN number is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Address',
            controller: _addressController,
            hint: 'Full address',
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Address is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildStatusField(),
        ],
      ),
    );
  }

  Widget _buildMaterialField() {
    final query = _materialSearchController.text.trim();
    final showDropdown = _showMaterialSuggestions && query.length >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Material',
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _materialSearchController,
          onTap: () => setState(() => _showMaterialSuggestions = true),
          style: GoogleFonts.poppins(color: AppColors.headingBlack, fontSize: 14),
          decoration: _inputDecoration('Search materials (min 3 letters)').copyWith(
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          ),
        ),
        if (query.isNotEmpty && query.length < 3) ...[
          const SizedBox(height: 6),
          Text(
            'Type at least 3 letters to search',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        if (showDropdown) ...[
          const SizedBox(height: 6),
          if (_isMaterialSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryRed,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (_materialSuggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No materials found for "$query"',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _materialSuggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.borderGray.withValues(alpha: 0.4),
                ),
                itemBuilder: (context, index) {
                  final item = _materialSuggestions[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primaryRed),
                    title: Text(
                      item.displayName,
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
                    ),
                    subtitle: item.unit.isNotEmpty
                        ? Text(
                            item.unit,
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                          )
                        : null,
                    onTap: () => _addMaterial(item),
                  );
                },
              ),
            ),
        ],
        if (_selectedItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedItems.map((item) {
              return InputChip(
                label: Text(
                  item.displayName,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryRed),
                ),
                deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primaryRed),
                onDeleted: () => _removeItem(item),
                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
        ],
        if (_isLoadingSupplier) ...[
          const SizedBox(height: 10),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.primaryRed,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statusChip('Published', SupplierStatus.published),
            const SizedBox(width: 10),
            _statusChip('Unpublished', SupplierStatus.unpublished),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(String label, SupplierStatus value) {
    final selected = _status == value;
    return Expanded(
      child: Material(
        color: selected
            ? AppColors.primaryRed.withValues(alpha: 0.1)
            : AppColors.operationsCardBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _status = value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.primaryRed : AppColors.borderGray.withValues(alpha: 0.6),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: selected ? AppColors.primaryRed : AppColors.textDark,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(color: AppColors.headingBlack, fontSize: 14),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 14),
      filled: true,
      fillColor: AppColors.operationsCardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.6),
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.white,
                ),
              )
            : Text(
                widget.isEditing ? 'UPDATE SUPPLIER' : 'SAVE SUPPLIER',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          'CANCEL',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
