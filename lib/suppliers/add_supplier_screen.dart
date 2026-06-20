import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/suppliers/supplier.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

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

  final List<String> _selectedMaterials = [];
  SupplierStatus _status = SupplierStatus.published;
  bool _showMaterialSuggestions = false;

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
      _selectedMaterials.addAll(supplier.materials);
      _status = supplier.status;
    }
    _materialSearchController.addListener(() {
      setState(() => _showMaterialSuggestions = _materialSearchController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _materialSearchController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  List<String> get _materialSuggestions {
    final query = _materialSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return [];
    return kAvailableMaterials
        .where((material) => !_selectedMaterials.contains(material))
        .where((material) => material.toLowerCase().contains(query))
        .take(8)
        .toList();
  }

  void _addMaterial(String material) {
    setState(() {
      if (!_selectedMaterials.contains(material)) {
        _selectedMaterials.add(material);
      }
      _materialSearchController.clear();
      _showMaterialSuggestions = false;
    });
  }

  void _removeMaterial(String material) {
    setState(() => _selectedMaterials.remove(material));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one material.')),
      );
      return;
    }

    final supplier = Supplier(
      id: widget.supplier?.id ?? 'SUP-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      materials: List<String>.from(_selectedMaterials),
      gstNo: _gstController.text.trim(),
      panNo: _panController.text.trim(),
      address: _addressController.text.trim(),
      status: _status,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Supplier updated successfully.'
              : 'Supplier created successfully.',
        ),
      ),
    );
    Navigator.of(context).pop(supplier);
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

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
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
            widget.isEditing ? 'Edit Supplier' : 'Create Supplier',
            style: GoogleFonts.poppins(
              color: AppColors.headingBlack,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
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
          decoration: _inputDecoration('Search and select materials').copyWith(
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          ),
        ),
        if (_showMaterialSuggestions && _materialSuggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
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
                final material = _materialSuggestions[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  leading: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primaryRed),
                  title: Text(
                    material,
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
                  ),
                  onTap: () => _addMaterial(material),
                );
              },
            ),
          ),
        ],
        if (_selectedMaterials.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedMaterials.map((material) {
              return InputChip(
                label: Text(
                  material,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryRed),
                ),
                deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primaryRed),
                onDeleted: () => _removeMaterial(material),
                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              );
            }).toList(),
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
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
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
