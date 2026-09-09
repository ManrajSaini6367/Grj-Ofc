import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Itemsscreen/item.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, this.item});

  final InventoryItem? item;

  bool get isEditing => item != null;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  static const _otherUnit = '__other__';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _otherUnitController = TextEditingController();

  String _unit = kAvailableUnits.first;
  ItemStatus _status = ItemStatus.published;
  bool _directPurchase = false;
  bool _dayReport = false;
  bool _consumable = true;
  int _balance = 0;
  bool _isSaving = false;
  late List<String> _units;

  bool get _isOtherUnit => _unit == _otherUnit;

  @override
  void initState() {
    super.initState();
    _units = [...kAvailableUnits, _otherUnit];
    final item = widget.item;
    if (item != null) {
      _nameController.text = item.name;
      _skuController.text = item.sku;
      _status = item.status;
      _directPurchase = item.directPurchase;
      _dayReport = item.dayReport;
      _consumable = item.consumable;
      _balance = item.balance;
      if (item.unit.isNotEmpty && kAvailableUnits.contains(item.unit)) {
        _unit = item.unit;
      } else if (item.unit.isNotEmpty) {
        _unit = _otherUnit;
        _otherUnitController.text = item.unit;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _otherUnitController.dispose();
    super.dispose();
  }

  String get _resolvedUnit =>
      _isOtherUnit ? _otherUnitController.text.trim() : _unit;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    final status =
        _status == ItemStatus.published ? 'published' : 'unpublished';
    final purchase = _directPurchase ? 1 : 0;
    final dayReport = _dayReport ? 1 : 0;
    final consumable = _consumable ? 1 : 0;

    if (widget.isEditing) {
      final itemId = int.tryParse(widget.item!.id);
      if (itemId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid item id.')),
        );
        return;
      }

      setState(() => _isSaving = true);
      await Future<void>.delayed(Duration.zero);
      try {
        final item = await updateItemApi(
          context,
          itemId: itemId,
          name: _nameController.text.trim(),
          sku: _skuController.text.trim(),
          unit: _resolvedUnit,
          status: status,
          balance: _balance,
          purchase: purchase,
          dayReport: dayReport,
          consumable: consumable,
        );

        if (!mounted) return;
        if (item != null) {
          Navigator.of(context).pop(item);
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
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
    await Future<void>.delayed(Duration.zero);
    try {
      final item = await createItemApi(
        context,
        siteId: siteId,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        unit: _resolvedUnit,
        status: status,
        balance: 0,
        purchase: purchase,
        dayReport: dayReport,
        consumable: consumable,
      );

      if (!mounted) return;
      if (item != null) {
        Navigator.of(context).pop(item);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
              title: widget.isEditing ? 'Edit Item' : 'Create Item',
              onBack: () => Navigator.pop(context),
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
        fieldLabelText(label,
            isRequired: required,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
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
        fieldLabelText('Unit',
            isRequired: true,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _unit,
          items: _units
              .map(
                (u) => DropdownMenuItem(
                  value: u,
                  child: Text(
                    u == _otherUnit ? 'Other' : u,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _unit = v;
              if (!_isOtherUnit) _otherUnitController.clear();
            });
          },
          validator: (v) => v == null || v.isEmpty ? 'Unit is required' : null,
          decoration: _inputDecoration('Select unit'),
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
        ),
        if (_isOtherUnit) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _otherUnitController,
            validator: (v) {
              if (!_isOtherUnit) return null;
              if (v == null || v.trim().isEmpty) return 'Enter other unit';
              if (v.trim().length > 50) return 'Unit is too long';
              return null;
            },
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: _inputDecoration('Enter other unit'),
          ),
        ],
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
                widget.isEditing ? 'UPDATE ITEM' : 'SAVE ITEM',
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
