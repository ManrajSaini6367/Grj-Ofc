import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/AmaniLabour/amani_labour.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/listcontractor.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';
import 'package:intl/intl.dart';

/// Form to create a contractor attendance entry for today.
class AddContractorAttendanceScreen extends StatefulWidget {
  const AddContractorAttendanceScreen({super.key});

  @override
  State<AddContractorAttendanceScreen> createState() =>
      _AddContractorAttendanceScreenState();
}

class _AddContractorAttendanceScreenState
    extends State<AddContractorAttendanceScreen> {
  static const _saveBlue = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();

  final _today = DateTime.now();

  final _contractorSearchController = TextEditingController();
  final _contractorSearchFocus = FocusNode();

  final _masonController = TextEditingController();
  final _beldarController = TextEditingController();
  final _coolieController = TextEditingController();

  final _masonOtController = TextEditingController();
  final _beldarOtController = TextEditingController();
  final _coolieOtController = TextEditingController();

  final _remarkController = TextEditingController();

  Timer? _debounce;

  List<LabourContractor> _contractors = [];
  List<LabourContractor> _suggestions = [];

  String? _selectedContractorId;

  bool _loadingContractors = true;
  bool _showSuggestions = false;
  bool _suppressSearchListener = false;
  bool _isSaving = false;

  String? _contractorError;

  @override
  void initState() {
    super.initState();

    _contractorSearchController.addListener(_onContractorSearchChanged);

    _contractorSearchFocus.addListener(() {
      if (!_contractorSearchFocus.hasFocus) {
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (mounted && !_contractorSearchFocus.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContractors());
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _contractorSearchController.removeListener(_onContractorSearchChanged);

    _contractorSearchController.dispose();
    _contractorSearchFocus.dispose();

    _masonController.dispose();
    _beldarController.dispose();
    _coolieController.dispose();

    _masonOtController.dispose();
    _beldarOtController.dispose();
    _coolieOtController.dispose();

    _remarkController.dispose();

    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 360) return 14;
    if (width < 600) return 18;

    return 20;
  }

  bool get _isWide => MediaQuery.sizeOf(context).width >= 700;

  String get _todayLabel => DateFormat('dd MMM yyyy').format(_today);

  void _onContractorSearchChanged() {
    if (_suppressSearchListener) return;

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;

      final q = _contractorSearchController.text.trim().toLowerCase();

      setState(() {
        _contractorError = null;

        if (q.isEmpty) {
          _suggestions = [];
          _showSuggestions = false;
          _selectedContractorId = null;
        } else {
          _suggestions = _contractors
              .where((c) => c.name.toLowerCase().contains(q))
              .toList();

          _showSuggestions = true;

          if (_selectedContractorId != null) {
            LabourContractor? selected;

            for (final c in _contractors) {
              if (c.id == _selectedContractorId) {
                selected = c;
                break;
              }
            }

            if (selected == null || selected.name.toLowerCase() != q) {
              _selectedContractorId = null;
            }
          }
        }
      });
    });
  }

  void _setSearchText(String value) {
    _suppressSearchListener = true;

    _contractorSearchController.text = value;

    _contractorSearchController.selection = TextSelection.collapsed(
      offset: value.length,
    );

    _suppressSearchListener = false;
  }

  void _selectContractor(LabourContractor contractor) {
    _debounce?.cancel();

    setState(() {
      _selectedContractorId = contractor.id;
      _suggestions = [];
      _showSuggestions = false;
      _contractorError = null;
    });

    _setSearchText(contractor.name);

    _contractorSearchFocus.unfocus();
  }

  void _clearSelectedContractor() {
    _debounce?.cancel();

    setState(() {
      _selectedContractorId = null;
      _suggestions = [];
      _showSuggestions = false;
      _contractorError = null;
    });

    _setSearchText('');
  }

  Future<void> _loadContractors() async {
    setState(() => _loadingContractors = true);

    final response = await getContractorListApi(context, perPage: 100);

    if (!mounted) return;

    setState(() {
      _contractors = response?.data?.items?.map(_toContractor).toList() ?? [];

      _loadingContractors = false;
    });
  }

  LabourContractor _toContractor(ContractorListItem item) {
    return LabourContractor(
      id: (item.id ?? 0).toString(),
      name: item.name ?? '',
      mobile: item.mobile ?? '',
      address: item.address ?? '',
      masonRatePerDay: item.masonRateValue,
      beldarRatePerDay: item.beldarRateValue,
      coolieRatePerDay: item.coolieRateValue,
      masonOtRatePerHour: item.masonOverRateValue,
      beldarOtRatePerHour: item.beldarOverRateValue,
      coolieOtRatePerHour: item.coolieOverRateValue,
      status: (item.status ?? '').toLowerCase() == 'unpublished'
          ? ContractorStatus.unpublished
          : ContractorStatus.published,
    );
  }

  int _parseCount(TextEditingController controller) {
    final trimmed = controller.text.trim();

    if (trimmed.isEmpty) return 0;

    return int.tryParse(trimmed) ?? 0;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedContractorId == null) {
      setState(() {
        _contractorError = 'Please choose a contractor';
      });

      return;
    }

    final siteId = selectedSiteId();

    if (siteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a site first.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );

      return;
    }

    final contractorId = int.tryParse(_selectedContractorId!);

    if (contractorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid contractor selected.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );

      return;
    }

    setState(() => _isSaving = true);

    final ok = await markLabourAttendanceApi(
      context,
      siteId: siteId,
      contractorId: contractorId,
      date: DateFormat('yyyy-MM-dd').format(_today),
      mason: _parseCount(_masonController),
      beldar: _parseCount(_beldarController),
      coolie: _parseCount(_coolieController),
      masonOver: _parseCount(_masonOtController),
      beldarOver: _parseCount(_beldarOtController),
      coolieOver: _parseCount(_coolieOtController),

      // Remark API mein send hoga
      remark: _remarkController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (!ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance saved for $_todayLabel.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF166534),
      ),
    );

    popShellRoute(context);
  }

  void _onCancel() {
    popShellRoute(context);
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
              title: 'Add Attendances',
              useShellPop: true,
              horizontalPadding: hPad,
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
                  children: [
                    Text(
                      'Information Attendances',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildFormCard(),

                    const SizedBox(height: 22),

                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final fields = [
      _buildReadOnlyDateField(),

      _buildContractorField(),

      _buildNumberField(
        label: 'Mason',
        controller: _masonController,
        hint: 'mason',
      ),

      _buildNumberField(
        label: 'Beldar',
        controller: _beldarController,
        hint: 'beldar',
      ),

      _buildNumberField(
        label: 'Coolie',
        controller: _coolieController,
        hint: 'coolie',
      ),

      _buildNumberField(
        label: 'Mason Over Time',
        controller: _masonOtController,
        hint: 'Mason Over Time',
      ),

      _buildNumberField(
        label: 'Beldar Over Time',
        controller: _beldarOtController,
        hint: 'Beldar Over Time',
      ),

      _buildNumberField(
        label: 'Coolie Over Time',
        controller: _coolieOtController,
        hint: 'Coolie Over Time',
      ),

      _buildTextField(
        label: 'Remark',
        controller: _remarkController,
        hint: 'remark',
        maxLines: 3,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
      ),
      child: _isWide
          ? _buildWideGrid(fields)
          : Column(
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  fields[i],
                  if (i != fields.length - 1) const SizedBox(height: 14),
                ],
                const SizedBox(height: 8),
              ],
            ),
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
        fieldLabelText(
          label,
          isRequired: required,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _inputDecoration(hint: hint),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildWideGrid(List<Widget> fields) {
    final rows = <Widget>[];

    for (var i = 0; i < fields.length; i += 3) {
      final end = (i + 3 < fields.length) ? i + 3 : fields.length;

      final chunk = fields.sublist(i, end);

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < 3; j++) ...[
                if (j > 0) const SizedBox(width: 12),

                Expanded(child: j < chunk.length ? chunk[j] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildReadOnlyDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),

        const SizedBox(height: 8),

        InputDecorator(
          decoration: _inputDecoration().copyWith(
            filled: true,
            fillColor: AppColors.operationsCardBg,
            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          child: Text(
            _todayLabel,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.headingBlack,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContractorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabelText(
          'Contractor',
          isRequired: true,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),

        const SizedBox(height: 8),

        if (_loadingContractors)
          Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderGray.withValues(alpha: 0.7),
              ),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryRed,
              ),
            ),
          )
        else ...[
          TextField(
            controller: _contractorSearchController,
            focusNode: _contractorSearchFocus,
            style: GoogleFonts.poppins(fontSize: 13),
            onTap: () {
              final q = _contractorSearchController.text.trim();

              if (q.isNotEmpty) {
                setState(() {
                  _suggestions = _contractors
                      .where(
                        (c) => c.name.toLowerCase().contains(q.toLowerCase()),
                      )
                      .toList();

                  _showSuggestions = true;
                });
              }
            },
            decoration: _inputDecoration(hint: 'Search contractor…').copyWith(
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _contractorSearchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: _clearSelectedContractor,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
              errorText: _contractorError,
            ),
          ),

          if (_showSuggestions) ...[
            const SizedBox(height: 8),
            _buildSuggestionsPanel(),
          ],
        ],
      ],
    );
  }

  Widget _buildSuggestionsPanel() {
    if (_suggestions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.operationsCardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.borderGray.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          'No contractor found.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppColors.borderGray.withValues(alpha: 0.45),
        ),
        itemBuilder: (context, index) {
          final contractor = _suggestions[index];

          final selected = contractor.id == _selectedContractorId;

          return InkWell(
            onTap: () => _selectContractor(contractor),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      contractor.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: AppColors.headingBlack,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.primaryRed,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _inputDecoration(hint: hint),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return null;
            }

            if (int.tryParse(v.trim()) == null) {
              return 'Enter a valid number';
            }

            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        TextButton(
          onPressed: _isSaving ? null : _onCancel,
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),

        const SizedBox(width: 8),

        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _onSave,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(
              'Save',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _saveBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.inputHint),
      filled: true,
      fillColor: AppColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.borderGray.withValues(alpha: 0.7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.borderGray.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.4),
      ),
    );
  }
}
