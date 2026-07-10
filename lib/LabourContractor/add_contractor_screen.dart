import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/LabourContractor/labour_contractor.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class AddContractorScreen extends StatefulWidget {
  const AddContractorScreen({super.key, this.contractor});

  final LabourContractor? contractor;

  bool get isEditing => contractor != null;

  @override
  State<AddContractorScreen> createState() => _AddContractorScreenState();
}

class _AddContractorScreenState extends State<AddContractorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _masonDayController = TextEditingController();
  final _beldarDayController = TextEditingController();
  final _coolieDayController = TextEditingController();
  final _masonOtController = TextEditingController();
  final _beldarOtController = TextEditingController();
  final _coolieOtController = TextEditingController();

  ContractorStatus _status = ContractorStatus.published;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contractor;
    if (c != null) {
      _nameController.text = c.name;
      _mobileController.text = c.mobile;
      _addressController.text = c.address;
      _masonDayController.text = c.masonRatePerDay.toStringAsFixed(0);
      _beldarDayController.text = c.beldarRatePerDay.toStringAsFixed(0);
      _coolieDayController.text = c.coolieRatePerDay.toStringAsFixed(0);
      _masonOtController.text = c.masonOtRatePerHour.toStringAsFixed(0);
      _beldarOtController.text = c.beldarOtRatePerHour.toStringAsFixed(0);
      _coolieOtController.text = c.coolieOtRatePerHour.toStringAsFixed(0);
      _status = c.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _masonDayController.dispose();
    _beldarDayController.dispose();
    _coolieDayController.dispose();
    _masonOtController.dispose();
    _beldarOtController.dispose();
    _coolieOtController.dispose();
    super.dispose();
  }

  double? _parseRate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final status =
        _status == ContractorStatus.published ? 'published' : 'unpublished';
    final masonRate = _parseRate(_masonDayController.text)!.round();
    final beldarRate = _parseRate(_beldarDayController.text)!.round();
    final coolieRate = _parseRate(_coolieDayController.text)!.round();
    final masonOverRate = _parseRate(_masonOtController.text)!.round();
    final beldarOverRate = _parseRate(_beldarOtController.text)!.round();
    final coolieOverRate = _parseRate(_coolieOtController.text)!.round();

    if (widget.isEditing) {
      final contractorId = int.tryParse(widget.contractor!.id);
      if (contractorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid contractor id.')),
        );
        return;
      }

      setState(() => _isSaving = true);
      try {
        final contractor = await updateContractorApi(
          context,
          contractorId: contractorId,
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          address: _addressController.text.trim(),
          status: status,
          masonRate: masonRate,
          beldarRate: beldarRate,
          coolieRate: coolieRate,
          masonOverRate: masonOverRate,
          beldarOverRate: beldarOverRate,
          coolieOverRate: coolieOverRate,
        );

        if (!mounted) return;
        if (contractor != null) {
          Navigator.of(context).pop(contractor);
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
    try {
      final contractor = await createContractorApi(
        context,
        siteId: siteId,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        status: status,
        masonRate: masonRate,
        beldarRate: beldarRate,
        coolieRate: coolieRate,
        masonOverRate: masonOverRate,
        beldarOverRate: beldarOverRate,
        coolieOverRate: coolieOverRate,
      );

      if (!mounted) return;
      if (contractor != null) {
        Navigator.of(context).pop(contractor);
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
              title: widget.isEditing ? 'Edit Contractor' : 'Create Contractor',
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
                            widget.isEditing ? 'Update Contractor' : 'New Contractor',
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
          _buildTextField(label: 'Name', controller: _nameController, hint: 'Contractor name', required: true),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Mobile',
            controller: _mobileController,
            hint: '+91 98765 43210',
            keyboardType: TextInputType.phone,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Address',
            controller: _addressController,
            hint: 'Full address',
            maxLines: 3,
            required: true,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Daily Rates'),
          const SizedBox(height: 10),
          _buildRateField('Mason Rate (Per Day)', _masonDayController),
          const SizedBox(height: 12),
          _buildRateField('Beldar Rate (Per Day)', _beldarDayController),
          const SizedBox(height: 12),
          _buildRateField('Coolie Rate (Per Day)', _coolieDayController),
          const SizedBox(height: 20),
          _buildSectionTitle('Over Time Rates'),
          const SizedBox(height: 10),
          _buildRateField('Mason Over Time Rate (Per Hour)', _masonOtController),
          const SizedBox(height: 12),
          _buildRateField('Beldar Over Time Rate (Per Hour)', _beldarOtController),
          const SizedBox(height: 12),
          _buildRateField('Coolie Over Time Rate (Per Hour)', _coolieOtController),
          const SizedBox(height: 20),
          _buildStatusField(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.headingBlack),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildRateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Rate is required';
            if (_parseRate(v) == null) return 'Enter a valid amount';
            return null;
          },
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _inputDecoration('0').copyWith(prefixText: '₹ '),
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
            _statusChip('Published', ContractorStatus.published),
            const SizedBox(width: 10),
            _statusChip('Unpublished', ContractorStatus.unpublished),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(String label, ContractorStatus value) {
    final selected = _status == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = value),
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
                widget.isEditing ? 'UPDATE CONTRACTOR' : 'SAVE CONTRACTOR',
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
