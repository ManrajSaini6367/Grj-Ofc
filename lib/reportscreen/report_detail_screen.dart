import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/getsupplierlist.dart';
import 'package:grjoffice_apps/models/listcontractor.dart';
import 'package:grjoffice_apps/reportscreen/report_excel.dart';
import 'package:grjoffice_apps/reportscreen/report_models.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/purchase_image_download_service.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

/// Generic report detail — uses API `path` + `required_params` from reports list.
class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.report,
    required this.siteId,
    required this.siteName,
  });

  final ReportListItem report;
  final int siteId;
  final String siteName;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  static final _displayDateFmt = DateFormat('dd MMM yyyy');
  static final _apiDateFmt = DateFormat('yyyy-MM-dd');

  List<ContractorListItem> _contractors = [];
  List<SupplierListItem> _suppliers = [];

  int? _contractorId;
  int? _supplierId;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _singleDate;
  String? _source;
  String? _type;

  bool _loadingOptions = false;
  bool _searching = false;
  bool _searched = false;
  bool _downloadingExcel = false;
  List<Map<String, dynamic>> _rows = [];

  bool get _showDownloadExcel =>
      !_searching && _searched && _rows.isNotEmpty && widget.report.hasExcelUrl;

  double _hPad(double width) {
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 24;
  }

  String get _apiPath => widget.report.resolvedPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadFilterOptions();
      if (mounted && widget.report.canAutoLoadFromApi) {
        await _onSearch();
      }
    });
  }

  Future<void> _loadFilterOptions() async {
    final params = widget.report.requiredParams;
    final needContractors = params.contains('contractor_id');
    final needSuppliers = params.contains('supplier_id');
    if (!needContractors && !needSuppliers) return;

    setState(() => _loadingOptions = true);

    if (needContractors) {
      final contractors = await getContractorListApi(
        context,
        siteId: widget.siteId,
        perPage: 100,
      );
      if (mounted) _contractors = contractors?.data?.items ?? const [];
    }

    if (needSuppliers) {
      final suppliers = await getSuppliersApi(
        context,
        siteId: widget.siteId,
        perPage: 100,
      );
      if (mounted) _suppliers = suppliers?.data?.items ?? const [];
    }

    if (mounted) setState(() => _loadingOptions = false);
  }

  Future<void> _pickDate({
    required void Function(DateTime) onPicked,
    DateTime? initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => onPicked(DateTime(picked.year, picked.month, picked.day)));
    }
  }

  Map<String, String> _buildQueryParams() {
    final params = <String, String>{};
    for (final key in widget.report.requiredParams) {
      switch (key) {
        case 'contractor_id':
          if (_contractorId != null) {
            params[key] = _contractorId.toString();
          }
        case 'supplier_id':
          if (_supplierId != null) {
            params[key] = _supplierId.toString();
          }
        case 'start_date':
          if (_startDate != null) {
            params[key] = _apiDateFmt.format(_startDate!);
          }
        case 'end_date':
          if (_endDate != null) {
            params[key] = _apiDateFmt.format(_endDate!);
          }
        case 'date':
          final d = _singleDate ?? _startDate;
          if (d != null) {
            params[key] = _apiDateFmt.format(d);
          }
        case 'source':
          if (_source != null && _source!.trim().isNotEmpty) {
            params[key] = _source!.trim();
          }
        case 'type':
          if (_type != null && _type!.trim().isNotEmpty) {
            params[key] = _type!.trim();
          }
        case 'item_id':
          if (widget.report.itemId != null) {
            params[key] = widget.report.itemId.toString();
          }
      }
    }
    return params;
  }

  bool _validateFilters() {
    if (_apiPath.isEmpty) return false;

    for (final key in widget.report.requiredParams) {
      switch (key) {
        case 'item_id':
          if (widget.report.itemId == null) {
            _snack('Item is not configured for this report.');
            return false;
          }
          continue;
        case 'contractor_id':
          if (_contractorId == null) {
            _snack('Please choose a contractor.');
            return false;
          }
        case 'supplier_id':
          if (_supplierId == null) {
            _snack('Please choose a supplier.');
            return false;
          }
        case 'start_date':
          if (_startDate == null) {
            _snack('Please select start date.');
            return false;
          }
        case 'end_date':
          if (_endDate == null) {
            _snack('Please select end date.');
            return false;
          }
        case 'date':
          if (_singleDate == null && _startDate == null) {
            _snack('Please select date.');
            return false;
          }
        case 'source':
          if (_source == null || _source!.trim().isEmpty) {
            _snack('Please select source.');
            return false;
          }
        case 'type':
          if (_type == null || _type!.trim().isEmpty) {
            _snack('Please select type.');
            return false;
          }
      }
    }
    return true;
  }

  Future<void> _onSearch() async {
    if (_apiPath.isEmpty) {
      _snack('Report API path is not configured.');
      return;
    }
    if (!_validateFilters()) return;

    setState(() {
      _searching = true;
      _searched = true;
    });

    final response = await getReportDetailApi(
      context,
      path: _apiPath,
      siteId: widget.siteId,
      queryParams: _buildQueryParams(),
    );

    if (!mounted) return;

    setState(() {
      _rows = _extractRows(response);
      _searching = false;
    });
  }

  void _onClear() {
    setState(() {
      _contractorId = null;
      _supplierId = null;
      _startDate = null;
      _endDate = null;
      _singleDate = null;
      _source = null;
      _type = null;
      _searched = false;
      _rows = [];
    });
  }

  Future<void> _downloadExcel() async {
    if (!_showDownloadExcel || _downloadingExcel) return;

    final excelUrl = widget.report.excelUrl?.trim() ?? '';
    if (excelUrl.isEmpty) return;

    setState(() => _downloadingExcel = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      ),
    );

    try {
      final bytes = buildReportExcelFromRows(
        sheetName: widget.report.title,
        rows: _rows,
      );

      final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final safeTitle = widget.report.title.trim().replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final fileName =
          '${safeTitle.isEmpty ? 'report' : safeTitle}_$stamp.xlsx';
      final savedPath =
          await PurchaseImageDownloadService.downloadToDownloadsFolder(
            bytes: bytes,
            fileName: fileName,
          );
      if (!mounted) return;

      final result = await OpenFilex.open(savedPath);
      if (result.type != ResultType.done) {
        _snack('Excel saved to Downloads.');
      }
    } catch (_) {
      if (mounted) _snack('Failed to download Excel.');
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _downloadingExcel = false);
      }
    }
  }

  List<Map<String, dynamic>> _extractRows(Map<String, dynamic>? response) {
    if (response == null) return const [];
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final items = map['items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      final challans = map['challans'];
      if (challans is List) {
        return challans
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      final expenses = map['expenses'];
      if (expenses is List) {
        return expenses
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      final stock = map['stock'];
      if (stock is List) {
        return stock
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = _hPad(width);
    final isCompact = width < 520;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: widget.report.title,
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSiteChip(),
                    const SizedBox(height: 14),
                    _buildFilterCard(isCompact: isCompact),
                    const SizedBox(height: 16),
                    _buildResultsCard(isCompact: isCompact),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppColors.primaryRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.siteName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard({required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.report.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (_loadingOptions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            )
          else
            ..._buildFilterFields(isCompact: isCompact),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: _searching ? 'Searching...' : 'Search',
                  icon: Icons.search,
                  onPressed: _searching ? null : _onSearch,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  label: 'Clear',
                  icon: Icons.refresh,
                  onPressed: _onClear,
                ),
              ),
              if (_showDownloadExcel) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    label: _downloadingExcel
                        ? 'Downloading...'
                        : 'Download Excel',
                    icon: Icons.file_download_outlined,
                    onPressed: _downloadingExcel ? null : _downloadExcel,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterFields({required bool isCompact}) {
    final fields = <Widget>[];
    for (final param in widget.report.requiredParams) {
      Widget field;
      switch (param) {
        case 'contractor_id':
          field = _dropdownField<int?>(
            label: 'Contractor',
            value: _contractorId,
            hint: 'Choose contractor',
            items: _contractors
                .where((c) => c.id != null)
                .map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name ?? 'Contractor #${c.id}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _contractorId = v),
          );
        case 'supplier_id':
          field = _dropdownField<int?>(
            label: 'Supplier',
            value: _supplierId,
            hint: 'Choose supplier',
            items: _suppliers
                .where((s) => s.id != null)
                .map(
                  (s) => DropdownMenuItem<int?>(
                    value: s.id,
                    child: Text(s.name ?? 'Supplier #${s.id}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _supplierId = v),
          );
        case 'start_date':
          field = _dateField(
            label: 'Start date',
            value: _startDate,
            onTap: () =>
                _pickDate(initial: _startDate, onPicked: (d) => _startDate = d),
          );
        case 'end_date':
          field = _dateField(
            label: 'End date',
            value: _endDate,
            onTap: () => _pickDate(
              initial: _endDate ?? _startDate,
              onPicked: (d) => _endDate = d,
            ),
          );
        case 'date':
          field = _dateField(
            label: 'Date',
            value: _singleDate,
            onTap: () => _pickDate(
              initial: _singleDate,
              onPicked: (d) => _singleDate = d,
            ),
          );
        case 'source':
          field = _dropdownField<String?>(
            label: 'Source',
            value: _source,
            hint: 'Choose source',
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(value: 'bank', child: Text('Bank')),
              DropdownMenuItem(value: 'all', child: Text('All')),
            ],
            onChanged: (v) => setState(() => _source = v),
          );
        case 'type':
          field = _dropdownField<String?>(
            label: 'Type',
            value: _type,
            hint: 'Choose type',
            items: const [
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'full', child: Text('Full')),
              DropdownMenuItem(value: 'all', child: Text('All')),
            ],
            onChanged: (v) => setState(() => _type = v),
          );
        default:
          continue;
      }
      fields.add(field);
      fields.add(SizedBox(height: isCompact ? 12 : 10));
    }
    if (fields.isNotEmpty) fields.removeLast();
    return fields;
  }

  Widget _buildResultsCard({required bool isCompact}) {
    if (!_searched) {
      return _resultShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Text(
            widget.report.canAutoLoadFromApi
                ? 'Loading report...'
                : 'Select filters and tap Search to load report.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (_searching) {
      return _resultShell(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ),
      );
    }

    if (_rows.isEmpty) {
      return _resultShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Text(
            'No records found for selected filters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_rows.length} record${_rows.length == 1 ? '' : 's'}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ..._rows.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == _rows.length - 1 ? 0 : 10,
            ),
            child: _buildRowCard(entry.value, entry.key + 1, isCompact),
          );
        }),
      ],
    );
  }

  Widget _buildRowCard(Map<String, dynamic> row, int index, bool isCompact) {
    final entries = row.entries
        .where((e) => !isDroppedReportExcelColumn(e.key))
        .where((e) => e.value != null && e.value.toString().trim().isNotEmpty)
        .toList();

    return _resultShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#$index',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 10),
            ...entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: isCompact ? 110 : 130,
                      child: Text(
                        _labelForKey(e.key),
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatValue(e.value),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.headingBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _resultShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Every field here comes from the report's required params, so the
        // search is blocked until it is filled.
        fieldLabelText(
          label,
          isRequired: true,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          decoration: _inputDecoration(hint: hint),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabelText(
          label,
          isRequired: true,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: InputDecorator(
            decoration: _inputDecoration(hint: 'dd/mm/yyyy').copyWith(
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              value == null ? 'dd/mm/yyyy' : _displayDateFmt.format(value),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: value == null
                    ? AppColors.inputHint
                    : AppColors.headingBlack,
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: AppColors.borderGray.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: AppColors.primaryRed.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  String _labelForKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return '—';
    if (value is num || value is bool) return value.toString();
    return value.toString();
  }
}
