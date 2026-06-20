import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/items/item.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, this.item});

  final InventoryItem? item;

  bool get isEditing => item != null;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();

  String _unit = kAvailableUnits.first;
  ItemStatus _status = ItemStatus.published;
  bool _directPurchase = false;
  bool _dayReport = false;
  bool _consumable = true;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _nameController.text = item.name;
      _skuController.text = item.sku;
      _unit = item.unit;
      _status = item.status;
      _directPurchase = item.directPurchase;
      _dayReport = item.dayReport;
      _consumable = item.consumable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final item = InventoryItem(
      id: widget.item?.id ?? 'ITM-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      unit: _unit,
      status: _status,
      directPurchase: _directPurchase,
      dayReport: _dayReport,
      consumable: _consumable,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditing ? 'Item updated successfully.' : 'Item created successfully.'),
      ),
    );
    Navigator.of(context).pop(item);
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
                          Text(
                            widget.isEditing ? 'Update Item' : 'New Item',
                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
                          ),
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
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 14;
    if (w < 600) return 18;
    return 20;
  }

  Widget _buildTopBar() {
    return Row(
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
            widget.isEditing ? 'Edit Item' : 'Create Item',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
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
          _buildTextField(label: 'Name', controller: _nameController, hint: 'Item name', required: true),
          const SizedBox(height: 16),
          _buildTextField(label: 'SKU', controller: _skuController, hint: 'e.g. CEM-OPC-53', required: true),
          const SizedBox(height: 16),
          _buildUnitField(),
          const SizedBox(height: 20),
          _buildStatusField(),
          const SizedBox(height: 20),
          _buildYesNoField('Direct Purchase', _directPurchase, (v) => setState(() => _directPurchase = v)),
          const SizedBox(height: 16),
          _buildYesNoField('Day Report', _dayReport, (v) => setState(() => _dayReport = v)),
          const SizedBox(height: 16),
          _buildYesNoField('Consumable', _consumable, (v) => setState(() => _consumable = v)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildUnitField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _unit,
          items: kAvailableUnits
              .map((u) => DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.poppins(fontSize: 14))))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _unit = v);
          },
          decoration: _inputDecoration('Select unit'),
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: [
            _statusChip('Published', ItemStatus.published),
            const SizedBox(width: 10),
            _statusChip('Unpublished', ItemStatus.unpublished),
          ],
        ),
      ],
    );
  }

  Widget _buildYesNoField(String label, bool value, ValueChanged<bool> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: [
            _yesNoChip('Yes', true, value, onChanged),
            const SizedBox(width: 10),
            _yesNoChip('No', false, value, onChanged),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(String label, ItemStatus statusValue) {
    final selected = _status == statusValue;
    return Expanded(child: _selectChip(label, selected, () => setState(() => _status = statusValue)));
  }

  Widget _yesNoChip(String label, bool chipValue, bool currentValue, ValueChanged<bool> onChanged) {
    return Expanded(child: _selectChip(label, currentValue == chipValue, () => onChanged(chipValue)));
  }

  Widget _selectChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryRed.withValues(alpha: 0.1) : AppColors.operationsCardBg,
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
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
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
          widget.isEditing ? 'UPDATE ITEM' : 'SAVE ITEM',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text('CANCEL', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
