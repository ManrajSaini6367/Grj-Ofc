import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Itemsscreen/item.dart';
import 'package:grjoffice_apps/models/itemhistorymodal.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/item_thumbnail.dart';

class ItemHistoryScreen extends StatefulWidget {
  const ItemHistoryScreen({super.key, required this.item});

  final InventoryItem item;

  @override
  State<ItemHistoryScreen> createState() => _ItemHistoryScreenState();
}

class _ItemHistoryScreenState extends State<ItemHistoryScreen> {
  static const _creditColor = Color(0xFF059669);
  static const _creditBg = Color(0xFFECFDF5);
  static const _debitColor = Color(0xFFDC2626);
  static const _debitBg = Color(0xFFFEF2F2);
  static const _issueColor = Color(0xFFD97706);
  static const _issueBg = Color(0xFFFFFBEB);

  final _searchController = TextEditingController();
  final _qtyController = TextEditingController();
  final _issueToController = TextEditingController();
  final _remarkController = TextEditingController();
  String _searchQuery = '';
  List<ItemTransaction> _transactions = [];
  bool _isLoading = true;
  bool _isSavingHistory = false;
  bool _confirmIssue = false;
  ItemHistoryItemInfo? _apiItem;
  DateTime? _issueDateTime;

  ItemTransactionType? _typeFilter;
  String? _issueToFilter;
  _HistoryDateFilter _dateFilter = _HistoryDateFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory({bool showLoader = true}) async {
    final itemId = int.tryParse(widget.item.id);
    if (itemId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    if (showLoader) setState(() => _isLoading = true);

    final response = await itemHistoryApi(
      context,
      itemId: itemId,
      perPage: 15,
      fetchAllPages: true,
    );
    if (!mounted) return;

    final records = response?.data?.items ?? [];
    final mapped = records
        .map(
          (record) => record.toTransaction(
            fallbackUnit: response?.data?.item?.unit ?? widget.item.unit,
          ),
        )
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    setState(() {
      _apiItem = response?.data?.item;
      _transactions = mapped;
      _isLoading = false;
    });
  }

  String get _displayName =>
      (_apiItem?.name?.trim().isNotEmpty == true) ? _apiItem!.name!.trim() : widget.item.name;

  String get _displaySku =>
      (_apiItem?.sku?.trim().isNotEmpty == true) ? _apiItem!.sku!.trim() : widget.item.sku;

  String get _displayUnit =>
      (_apiItem?.unit?.trim().isNotEmpty == true) ? _apiItem!.unit!.trim() : widget.item.unit;

  double get _stockBalance {
    final fromApi = double.tryParse(_apiItem?.balance ?? '');
    if (fromApi != null) return fromApi;
    return widget.item.balance.toDouble();
  }

  bool get _hasNoHistory =>
      _transactions.isEmpty && !_hasActiveFilters && _searchQuery.isEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    _qtyController.dispose();
    _issueToController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  List<ItemTransaction> get _filteredTransactions {
    return _transactions.where((tx) {
      if (_typeFilter != null && tx.type != _typeFilter) return false;
      if (_issueToFilter != null && (tx.issueTo ?? '') != _issueToFilter) return false;
      if (!_matchesDateFilter(tx.dateTime)) return false;
      if (_searchQuery.isNotEmpty) {
        final haystack = [
          tx.qty.toString(),
          tx.unit,
          tx.typeLabel,
          tx.issueTo ?? '',
          tx.remark ?? '',
          _formatDateTime(tx.dateTime),
        ].join(' ').toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      return true;
    }).toList();
  }

  double get _totalCredit => _filteredTransactions
      .where((tx) => tx.type == ItemTransactionType.credit)
      .fold(0, (sum, tx) => sum + tx.qty);

  double get _totalDebit => _filteredTransactions
      .where((tx) => tx.isStockOut)
      .fold(0, (sum, tx) => sum + tx.qty);

  double get _currentIssueQty {
    return _transactions
        .where((tx) => tx.type == ItemTransactionType.issue)
        .fold(0.0, (sum, tx) => sum + tx.qty);
  }

  bool _matchesDateFilter(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    switch (_dateFilter) {
      case _HistoryDateFilter.all:
        return true;
      case _HistoryDateFilter.today:
        return txDate == today;
      case _HistoryDateFilter.last7:
        return !txDate.isBefore(today.subtract(const Duration(days: 6)));
      case _HistoryDateFilter.last30:
        return !txDate.isBefore(today.subtract(const Duration(days: 29)));
      case _HistoryDateFilter.thisMonth:
        return dateTime.year == now.year && dateTime.month == now.month;
    }
  }

  List<String> get _issueToOptions {
    return _transactions
        .map((tx) => tx.issueTo)
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  bool get _hasActiveFilters =>
      _typeFilter != null || _issueToFilter != null || _dateFilter != _HistoryDateFilter.all;

  void _clearFilters() {
    setState(() {
      _typeFilter = null;
      _issueToFilter = null;
      _dateFilter = _HistoryDateFilter.all;
    });
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final rows = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar.page(
              title: 'Item History',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () => _loadHistory(showLoader: false),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildItemHeader(),
                                  const SizedBox(height: 14),
                                  _buildIssueItemButton(),
                                  const SizedBox(height: 14),
                                  _buildCurrentIssueQtyCard(),
                                  const SizedBox(height: 14),
                                  _buildStatsRow(),
                                  const SizedBox(height: 14),
                                  _buildToolbar(),
                                  if (_hasActiveFilters) ...[
                                    const SizedBox(height: 10),
                                    _buildActiveFilterChips(),
                                  ],
                                  const SizedBox(height: 16),
                                  _buildResultsHeader(rows.length),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                          if (rows.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildTransactionCard(rows[index]),
                                  childCount: rows.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: ItemThumbnail(
                item: widget.item,
                height: 88,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _displaySku,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _infoChip(Icons.straighten_rounded, formatStoreUnit(_displayUnit)),
                        _infoChip(
                          Icons.inventory_2_outlined,
                          '${_formatQty(_stockBalance)} ${formatStoreUnit(_displayUnit)}',
                          color: AppColors.primaryRed,
                          bg: AppColors.primaryRed.withValues(alpha: 0.08),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueItemButton() {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showIssueItemSheet,
        icon: const Icon(Icons.outbox_outlined, size: 20),
        label: Text(
          'Issue Item',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildCurrentIssueQtyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _displayName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatQty(_currentIssueQty)} ${formatStoreUnit(_displayUnit)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingBlack,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Current Issue Qty',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: _issueColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  void _showIssueItemSheet() {
    _qtyController.clear();
    _issueToController.clear();
    _remarkController.clear();
    _issueDateTime = DateTime.now();
    _isSavingHistory = false;
    _confirmIssue = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.borderGray.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Issue Item',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.headingBlack,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _qtyField(),
                        const SizedBox(height: 10),
                        _dateField(setSheetState),
                        const SizedBox(height: 10),
                        _labeledField(
                          label: 'Issue To',
                          child: _issueTextField(
                            controller: _issueToController,
                            hint: 'Issue To',
                          ),
                        ),
                        const SizedBox(height: 10),
                        _labeledField(
                          label: 'description',
                          child: _issueTextField(
                            controller: _remarkController,
                            hint: 'Remark',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _confirmIssueCheckbox(setSheetState),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _isSavingHistory
                                ? null
                                : () => _saveIssueHistory(
                                      sheetContext: sheetContext,
                                      setSheetState: setSheetState,
                                    ),
                            icon: _isSavingHistory
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(Icons.assignment_turned_in_outlined, size: 18),
                            label: Text(
                              'Save',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor:
                                  AppColors.primaryRed.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _issueInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.cardWhite,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.4),
      ),
    );
  }

  Widget _issueTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
      decoration: _issueInputDecoration(hint),
    );
  }

  Widget _qtyField() {
    return _labeledField(
      label: 'Qty',
      child: _issueTextField(
        controller: _qtyController,
        hint: 'Qty',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
      ),
    );
  }

  Widget _dateField(StateSetter setSheetState) {
    return _labeledField(
      label: 'Date',
      child: InkWell(
        onTap: () => _pickIssueDateTime(setSheetState),
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: _issueInputDecoration('mm / dd / yyyy, -- : -- --').copyWith(
            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
          child: Text(
            _issueDateTime == null
                ? 'mm / dd / yyyy, -- : -- --'
                : _formatIssueDateTime(_issueDateTime!),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _issueDateTime == null
                  ? AppColors.inputHint
                  : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  String _formatIssueDateTime(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$mm / $dd / $yyyy, ${hour12.toString().padLeft(2, '0')} : $min $period';
  }

  String _apiDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  Future<void> _pickIssueDateTime(StateSetter setSheetState) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _issueDateTime ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _issueDateTime != null
          ? TimeOfDay.fromDateTime(_issueDateTime!)
          : TimeOfDay.fromDateTime(now),
    );
    if (!mounted) return;

    final time = pickedTime ?? const TimeOfDay(hour: 0, minute: 0);
    setSheetState(() {
      _issueDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveIssueHistory({
    required BuildContext sheetContext,
    required StateSetter setSheetState,
  }) async {
    final itemId = int.tryParse(widget.item.id);
    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item id is not valid.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final qty = double.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter Qty.', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_issueDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select Date.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final issueTo = _issueToController.text.trim();
    if (issueTo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter Issue To.', style: GoogleFonts.poppins())),
      );
      return;
    }

    setSheetState(() => _isSavingHistory = true);
    final ok = await createItemHistoryApi(
      context,
      itemId: itemId,
      qty: qty,
      date: _apiDateTime(_issueDateTime!),
      issueTo: issueTo,
      remark: _remarkController.text.trim(),
      type: _confirmIssue ? 'issue' : 'debit',
    );
    if (!mounted) return;
    setSheetState(() => _isSavingHistory = false);
    if (!ok) return;

    _qtyController.clear();
    _issueToController.clear();
    _remarkController.clear();
    _issueDateTime = null;
    _confirmIssue = false;
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    await _loadHistory(showLoader: false);
  }

  Widget _confirmIssueCheckbox(StateSetter setSheetState) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSavingHistory
            ? null
            : () => setSheetState(() => _confirmIssue = !_confirmIssue),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _confirmIssue,
                  onChanged: _isSavingHistory
                      ? null
                      : (value) {
                          setSheetState(() => _confirmIssue = value ?? false);
                        },
                  activeColor: AppColors.primaryRed,
                  side: const BorderSide(
                    color: AppColors.checkboxBorder,
                    width: 1.5,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Issue this item',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(
    IconData icon,
    String label, {
    Color color = AppColors.textDark,
    Color bg = AppColors.operationsCardBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: 'Credit',
            value: _formatQty(_totalCredit),
            unit: _displayUnit,
            icon: Icons.arrow_downward_rounded,
            color: _creditColor,
            bg: _creditBg,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            label: 'Debit',
            value: _formatQty(_totalDebit),
            unit: _displayUnit,
            icon: Icons.arrow_upward_rounded,
            color: _debitColor,
            bg: _debitBg,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            label: 'Balance',
            value: _formatQty(_stockBalance),
            unit: _displayUnit,
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.primaryRed,
            bg: AppColors.primaryRed.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  formatStoreUnit(unit),
                  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                filled: true,
                fillColor: AppColors.operationsCardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.5), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _hasActiveFilters
                ? AppColors.primaryRed.withValues(alpha: 0.1)
                : AppColors.operationsCardBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _showFilterSheet,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _hasActiveFilters
                        ? AppColors.primaryRed.withValues(alpha: 0.4)
                        : AppColors.borderGray.withValues(alpha: 0.4),
                  ),
                ),
                child: Badge(
                  isLabelVisible: _hasActiveFilters,
                  smallSize: 8,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: _hasActiveFilters ? AppColors.primaryRed : AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Row(
      children: [
        Text(
          'Transactions',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.headingBlack,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryRed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(ItemTransaction tx) {
    final isCredit = tx.type == ItemTransactionType.credit;
    final isIssue = tx.type == ItemTransactionType.issue;
    final accent = isCredit ? _creditColor : isIssue ? _issueColor : _debitColor;
    final accentBg = isCredit ? _creditBg : isIssue ? _issueBg : _debitBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                  size: 16,
                                  color: accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tx.typeLabel.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isCredit ? '+' : '-'}${_formatQty(tx.qty)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  height: 1,
                                ),
                              ),
                              Text(
                                formatStoreUnit(tx.unit),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if ((tx.issueTo ?? '').isNotEmpty || (tx.remark ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.operationsCardBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((tx.issueTo ?? '').isNotEmpty)
                                _detailRow(Icons.person_outline_rounded, 'Issue To', tx.issueTo!),
                              if ((tx.issueTo ?? '').isNotEmpty && (tx.remark ?? '').isNotEmpty)
                                const SizedBox(height: 6),
                              if ((tx.remark ?? '').isNotEmpty)
                                _detailRow(Icons.notes_rounded, 'Remark', tx.remark!),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(tx.dateTime),
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(tx.dateTime),
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_typeFilter != null)
          _activeFilterChip(
            _typeFilter == ItemTransactionType.credit
                ? 'Credit'
                : _typeFilter == ItemTransactionType.issue
                    ? 'Issue'
                    : 'Debit',
            () => setState(() => _typeFilter = null),
          ),
        if (_issueToFilter != null)
          _activeFilterChip(
            'Issue To: $_issueToFilter',
            () => setState(() => _issueToFilter = null),
          ),
        if (_dateFilter != _HistoryDateFilter.all)
          _activeFilterChip(
            _dateFilter.label,
            () => setState(() => _dateFilter = _HistoryDateFilter.all),
          ),
        GestureDetector(
          onTap: _clearFilters,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Clear all',
              style: GoogleFonts.poppins(
                color: AppColors.primaryRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onRemove) {
    return InputChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primaryRed)),
      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primaryRed),
      onDeleted: onRemove,
      backgroundColor: AppColors.primaryRed.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.25)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderGray.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppColors.primaryRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Filter Transactions',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              _clearFilters();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Clear',
                              style: GoogleFonts.poppins(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _filterSection('Type', Icons.swap_vert_rounded, [
                      _filterChip('All', _typeFilter == null, () {
                        setState(() => _typeFilter = null);
                        Navigator.pop(context);
                      }),
                      _filterChip('Credit', _typeFilter == ItemTransactionType.credit, () {
                        setState(() => _typeFilter = ItemTransactionType.credit);
                        Navigator.pop(context);
                      }),
                      _filterChip('Debit', _typeFilter == ItemTransactionType.debit, () {
                        setState(() => _typeFilter = ItemTransactionType.debit);
                        Navigator.pop(context);
                      }),
                      _filterChip('Issue', _typeFilter == ItemTransactionType.issue, () {
                        setState(() => _typeFilter = ItemTransactionType.issue);
                        Navigator.pop(context);
                      }),
                    ]),
                    const SizedBox(height: 16),
                    _filterSection(
                      'Date Range',
                      Icons.date_range_rounded,
                      _HistoryDateFilter.values
                          .map(
                            (filter) => _filterChip(filter.label, _dateFilter == filter, () {
                              setState(() => _dateFilter = filter);
                              Navigator.pop(context);
                            }),
                          )
                          .toList(),
                    ),
                    if (_issueToOptions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _filterSection('Issue To', Icons.person_outline_rounded, [
                        _filterChip('All', _issueToFilter == null, () {
                          setState(() => _issueToFilter = null);
                          Navigator.pop(context);
                        }),
                        ..._issueToOptions.map(
                          (issueTo) => _filterChip(issueTo, _issueToFilter == issueTo, () {
                            setState(() => _issueToFilter = issueTo);
                            Navigator.pop(context);
                          }),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _filterSection(String title, IconData icon, List<Widget> chips) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.operationsCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryRed),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.primaryRed : AppColors.textDark,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryRed,
      backgroundColor: AppColors.cardWhite,
      side: BorderSide(
        color: selected
            ? AppColors.primaryRed.withValues(alpha: 0.4)
            : AppColors.borderGray.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.operationsCardBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _hasNoHistory ? 'No history yet' : 'No transactions found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hasNoHistory
                ? 'Credit or debit entries for this item will appear here.'
                : 'Try adjusting your search or filters',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (_hasActiveFilters || _searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _clearFilters();
              },
              child: Text(
                'Reset filters',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _HistoryDateFilter {
  all('All Time'),
  today('Today'),
  last7('Last 7 Days'),
  last30('Last 30 Days'),
  thisMonth('This Month');

  const _HistoryDateFilter(this.label);
  final String label;
}
