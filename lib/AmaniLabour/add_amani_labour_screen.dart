import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/AmaniLabour/amani_labour.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/image_pick_helper.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';

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

  final List<File> _agreementFiles = [];
  final List<File> _documentFiles = [];
  File? _cancelChequeFile;
  List<String> _existingAgreements = [];
  List<String> _existingDocuments = [];
  String? _existingCancelCheque;

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
      _existingAgreements = List<String>.from(c.agreements);
      _existingDocuments = List<String>.from(c.documents);
      _existingCancelCheque = c.cancelCheque;
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

  Future<void> _pickMulti(List<File> target, {required String title}) async {
    final file = await pickPurchaseImageFile(context, title: title);
    if (file == null || !mounted) return;
    setState(() => target.add(file));
  }

  Future<void> _pickCancelCheque() async {
    final file = await pickPurchaseImageFile(context, title: 'Cancel Cheque');
    if (file == null || !mounted) return;
    setState(() => _cancelChequeFile = file);
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
          agreementFiles: _agreementFiles,
          documentFiles: _documentFiles,
          cancelChequeFile: _cancelChequeFile,
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
        agreementFiles: _agreementFiles,
        documentFiles: _documentFiles,
        cancelChequeFile: _cancelChequeFile,
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
              title: widget.isEditing
                  ? 'Edit Amani Labour'
                  : 'Create Amani Labour',
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
                            widget.isEditing
                                ? 'Update Amani Labour'
                                : 'New Amani Labour',
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
      clipBehavior: Clip.none,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(label: 'Name', controller: _nameController, hint: 'Labour name', required: true),
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
          _buildSectionTitle('Documents (optional)'),
          const SizedBox(height: 10),
          _buildMultiImageField(
            label: 'Agreements',
            existingUrls: _existingAgreements,
            files: _agreementFiles,
            onAdd: () => _pickMulti(_agreementFiles, title: 'Agreement Photo'),
            onRemoveFile: (i) => setState(() => _agreementFiles.removeAt(i)),
          ),
          const SizedBox(height: 14),
          _buildMultiImageField(
            label: 'Documents',
            existingUrls: _existingDocuments,
            files: _documentFiles,
            onAdd: () => _pickMulti(_documentFiles, title: 'Document Photo'),
            onRemoveFile: (i) => setState(() => _documentFiles.removeAt(i)),
          ),
          const SizedBox(height: 14),
          _buildSingleImageField(
            label: 'Cancel Cheque',
            existingUrl: _existingCancelCheque,
            file: _cancelChequeFile,
            onAdd: _pickCancelCheque,
            onClear: () => setState(() => _cancelChequeFile = null),
          ),
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

  Widget _buildMultiImageField({
    required String label,
    required List<String> existingUrls,
    required List<File> files,
    required VoidCallback onAdd,
    required void Function(int index) onRemoveFile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final url in existingUrls)
              _thumbNetwork(url),
            for (var i = 0; i < files.length; i++)
              _thumbFile(files[i], onRemove: () => onRemoveFile(i)),
            _addThumb(onAdd),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleImageField({
    required String label,
    required String? existingUrl,
    required File? file,
    required VoidCallback onAdd,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (file != null)
              _thumbFile(file, onRemove: onClear)
            else if (existingUrl != null && existingUrl.trim().isNotEmpty)
              _thumbNetwork(existingUrl)
            else
              _addThumb(onAdd),
            if (file != null || (existingUrl != null && existingUrl.trim().isNotEmpty))
              _addThumb(onAdd, label: 'Replace'),
          ],
        ),
      ],
    );
  }

  Widget _thumbNetwork(String url) {
    final src = mediaUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        src,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _brokenThumb(),
      ),
    );
  }

  Widget _thumbFile(File file, {required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 72, height: 72, fit: BoxFit.cover),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addThumb(VoidCallback onTap, {String label = 'Add'}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.operationsCardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, size: 20, color: AppColors.primaryRed),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _brokenThumb() {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.operationsCardBg,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: AppColors.inputHint),
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
        fieldLabelText(label,
            isRequired: required,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          clipBehavior: Clip.none,
          child: TextFormField(
            controller: controller,
            keyboardType:
                maxLines > 1 ? TextInputType.multiline : keyboardType,
            maxLines: maxLines,
            textInputAction:
                maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
                : null,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: _inputDecoration(hint),
          ),
        ),
      ],
    );
  }

  Widget _buildRateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabelText(label,
            isRequired: true,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          clipBehavior: Clip.none,
          child: TextFormField(
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
    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
    );
    const focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppColors.primaryRed, width: 1.5),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 14),
      filled: true,
      fillColor: AppColors.operationsCardBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: normalBorder,
      enabledBorder: normalBorder,
      focusedBorder: focusBorder,
      errorBorder: normalBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.primaryRed),
      ),
      focusedErrorBorder: focusBorder,
      disabledBorder: normalBorder,
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
                widget.isEditing ? 'UPDATE AMANI LABOUR' : 'SAVE AMANI LABOUR',
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
