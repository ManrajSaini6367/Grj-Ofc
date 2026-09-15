import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/PetiContractor/peti_contractor.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/image_pick_helper.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';

class OriginalContractorScreen extends StatefulWidget {
  const OriginalContractorScreen({super.key, this.contractor});

  final OriginalContractor? contractor;

  bool get isEditing => contractor != null;

  @override
  State<OriginalContractorScreen> createState() =>
      _OriginalContractorScreenState();
}

class _OriginalContractorScreenState extends State<OriginalContractorScreen> {
  static const _addGreen = Color(0xFF22C55E);
  static const _removeCoral = Color(0xFFF87171);
  static const _fieldHeight = 48.0;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  OriginalContractorStatus _status = OriginalContractorStatus.published;
  final List<_WorkRateEntry> _rows = [];
  bool _isSaving = false;

  final List<File> _agreementFiles = [];
  final List<File> _documentFiles = [];
  File? _cancelChequeFile;
  List<String> _existingAgreements = [];
  List<String> _existingDocuments = [];
  String? _existingCancelCheque;

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.contractor;
    if (existing != null) {
      _nameController.text = existing.name;
      _phoneController.text = existing.phone;
      _addressController.text = existing.address;
      _status = existing.status;
      _existingAgreements = List<String>.from(existing.agreements);
      _existingDocuments = List<String>.from(existing.documents);
      _existingCancelCheque = existing.cancelCheque;
      if (existing.works.isEmpty) {
        _rows.add(_WorkRateEntry());
      } else {
        for (final work in existing.works) {
          _rows.add(
            _WorkRateEntry(
              work: work.work,
              rate: work.rate == 0 ? '' : work.rate.toString(),
            ),
          );
        }
      }
    } else {
      _rows.add(_WorkRateEntry());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() => _rows.add(_WorkRateEntry()));
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
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

  bool _docsValid() {
    final hasAgreements =
        _agreementFiles.isNotEmpty || _existingAgreements.isNotEmpty;
    if (!hasAgreements) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agreement photo is required.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_docsValid()) return;

    final works = _rows
        .map(
          (row) => {
            'work': row.workController.text.trim(),
            'rate': int.tryParse(row.rateController.text.trim()) ?? 0,
          },
        )
        .where((item) => (item['work'] as String).isNotEmpty)
        .toList();

    if (works.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one work and rate.')),
      );
      return;
    }

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
        final updated = await updateOriginalContractorApi(
          context,
          originalContractorId: contractorId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          status: _status == OriginalContractorStatus.published
              ? 'published'
              : 'unpublished',
          works: works,
          agreementFiles: _agreementFiles,
          documentFiles: _documentFiles,
          cancelChequeFile: _cancelChequeFile,
        );
        if (!mounted) return;
        if (updated != null) {
          final data = updated.data;
          final apiWorks = (data?.works ?? const [])
              .map(
                (item) => WorkRateItem(
                  work: item.work ?? '',
                  rate: (item.rate ?? 0).round(),
                ),
              )
              .where((item) => item.work.trim().isNotEmpty)
              .toList();
          Navigator.of(context).pop(
            OriginalContractor(
              id: (data?.id ?? contractorId).toString(),
              name: data?.name?.trim().isNotEmpty == true
                  ? data!.name!.trim()
                  : _nameController.text.trim(),
              phone: data?.phone?.trim().isNotEmpty == true
                  ? data!.phone!.trim()
                  : _phoneController.text.trim(),
              address: data?.address?.trim().isNotEmpty == true
                  ? data!.address!.trim()
                  : _addressController.text.trim(),
              status: (data?.status ?? '').toLowerCase() == 'unpublished'
                  ? OriginalContractorStatus.unpublished
                  : _status,
              works: apiWorks.isNotEmpty
                  ? apiWorks
                  : works
                      .map(
                        (item) => WorkRateItem(
                          work: item['work'] as String,
                          rate: item['rate'] as int,
                        ),
                      )
                      .toList(),
              agreements: data?.agreements ?? _existingAgreements,
              documents: data?.documents ?? _existingDocuments,
              cancelCheque: data?.cancelCheque ?? _existingCancelCheque,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
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
      final created = await createOriginalContractorApi(
        context,
        siteId: siteId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        status: _status == OriginalContractorStatus.published
            ? 'published'
            : 'unpublished',
        works: works,
        agreementFiles: _agreementFiles,
        documentFiles: _documentFiles,
        cancelChequeFile: _cancelChequeFile,
      );
      if (!mounted) return;
      if (created != null) {
        Navigator.of(context).pop(OriginalContractor.fromApiItem(created));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = _hPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: widget.isEditing
                  ? 'Edit Peti Contractor'
                  : 'Create Peti Contractor',
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
                                ? 'Update Peti Contractor'
                                : 'New Peti Contractor',
                            style: GoogleFonts.poppins(
                              fontSize: width < 360 ? 22 : 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.headingBlack,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFormCard(width),
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

  Widget _buildFormCard(double width) {
    return Container(
      padding: EdgeInsets.all(width < 360 ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Information Peti Contractors',
            style: GoogleFonts.poppins(
              fontSize: width < 360 ? 15 : 16,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Name',
            controller: _nameController,
            hint: 'name',
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone',
            controller: _phoneController,
            hint: 'phone',
            keyboardType: TextInputType.phone,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Address',
            controller: _addressController,
            hint: 'address',
            maxLines: 2,
            required: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Documents',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 10),
          _buildMultiImageField(
            label: 'Agreements',
            required: true,
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
          const SizedBox(height: 16),
          _buildStatusField(),
          const SizedBox(height: 20),
          Text(
            'Work according to rate',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: AppColors.borderGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildWorkRateRow(index: i, width: width),
          ],
        ],
      ),
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
        fieldLabelText(
          label,
          isRequired: required,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType:
              maxLines > 1 ? TextInputType.multiline : keyboardType,
          maxLines: maxLines,
          textInputAction:
              maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildMultiImageField({
    required String label,
    required List<String> existingUrls,
    required List<File> files,
    required VoidCallback onAdd,
    required void Function(int index) onRemoveFile,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabelText(label,
            isRequired: required,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final url in existingUrls) _thumbNetwork(url),
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
        fieldLabelText(label,
            isRequired: false,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
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
            if (file != null ||
                (existingUrl != null && existingUrl.trim().isNotEmpty))
              _addThumb(onAdd, label: 'Replace'),
          ],
        ),
      ],
    );
  }

  Widget _thumbNetwork(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        mediaUrl(url),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72,
          height: 72,
          color: AppColors.operationsCardBg,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
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
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
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

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statusChip('Published', OriginalContractorStatus.published),
            const SizedBox(width: 10),
            _statusChip('Unpublished', OriginalContractorStatus.unpublished),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(String label, OriginalContractorStatus value) {
    final selected = _status == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryRed.withValues(alpha: 0.1)
                : AppColors.operationsCardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.primaryRed
                  : AppColors.borderGray.withValues(alpha: 0.6),
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

  Widget _buildWorkRateRow({required int index, required double width}) {
    final row = _rows[index];
    final isFirst = index == 0;
    final threeInRow = width >= 400;

    final workField = _labeled(
      'Work',
      _fixedField(
        TextFormField(
          controller: row.workController,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.poppins(fontSize: 14, height: 1.2),
          textAlignVertical: TextAlignVertical.center,
          decoration: _inputDecoration('Work'),
        ),
      ),
      isRequired: true,
    );

    final rateField = _labeled(
      'Rate',
      _fixedField(
        TextFormField(
          controller: row.rateController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(fontSize: 14, height: 1.2),
          textAlignVertical: TextAlignVertical.center,
          decoration: _inputDecoration('Rate'),
        ),
      ),
    );

    final action = Padding(
      padding: EdgeInsets.only(top: threeInRow ? 21 : 0),
      child: _fixedField(
        _RowActionButton(
          label: isFirst ? '+ Add More' : '- Remove',
          color: isFirst ? _addGreen : _removeCoral,
          onTap: isFirst ? _addRow : () => _removeRow(index),
        ),
      ),
    );

    if (!threeInRow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          workField,
          const SizedBox(height: 12),
          rateField,
          const SizedBox(height: 12),
          action,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: workField),
        const SizedBox(width: 10),
        Expanded(child: rateField),
        const SizedBox(width: 10),
        Expanded(child: action),
      ],
    );
  }

  Widget _fixedField(Widget child) {
    return SizedBox(height: _fieldHeight, child: child);
  }

  Widget _labeled(String label, Widget child, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabelText(
          label,
          isRequired: isRequired,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        child,
      ],
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
                widget.isEditing
                    ? 'UPDATE PETI CONTRACTOR'
                    : 'SAVE PETI CONTRACTOR',
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
        child: Text(
          'CANCEL',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _WorkRateEntry {
  _WorkRateEntry({String work = '', String rate = ''})
      : workController = TextEditingController(text: work),
        rateController = TextEditingController(text: rate);

  final TextEditingController workController;
  final TextEditingController rateController;

  void dispose() {
    workController.dispose();
    rateController.dispose();
  }
}

class _RowActionButton extends StatelessWidget {
  const _RowActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
