import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/items/item.dart';
import 'package:grjoffice_apps/models/itemhistorymodal.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';
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

  final _searchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _issueToController = TextEditingController();
  final _remarkController = TextEditingController();
  String _searchQuery = '';
  List<ItemTransaction> _transactions = [];
  bool _isLoading = true;
  ItemHistoryItemInfo? _apiItem;
  DateTime _selectedDateTime = DateTime.now();

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

  Future<void> _loadHistory() async {
    final itemId = int.tryParse(widget.item.id);
    if (itemId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final response = await itemHistoryApi(context, itemId: itemId);
    if (!mounted) return;

    final records = response?.data?.items ?? [];
    setState(() {
      _apiItem = response?.data?.item;
      _transactions = records
          .map(
            (record) => record.toTransaction(
              fallbackUnit: _apiItem?.unit ?? widget.item.unit,
            ),
          )
          .toList();
      _isLoading = false;
    });
  }

  String get _displayName => _apiItem?.name ?? widget.item.name;

  String get _displaySku => _apiItem?.sku ?? widget.item.sku;

  String get _displayUnit => _apiItem?.unit ?? widget.item.unit;

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
      .where((tx) => tx.type == ItemTransactionType.debit)
      .fold(0, (sum, tx) => sum + tx.qty);

  double get _netBalance => _stockBalance;

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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  String _formatQty(double qty) {
    return qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
  }

  String _formatDateInput(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m / $d / ${dt.year}, $h:$min';
  }

  double? _parseQty() {
    final value = double.tryParse(_qtyController.text.trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  void _adjustQty(double delta) {
    final current = _parseQty() ?? 0;
    final next = (current + delta).clamp(1, 999999).toDouble();
    _qtyController.text = _formatQty(next);
    setState(() {});
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _saveEntry() {
    final qty = _parseQty();
    if (qty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity.')),
      );
      return;
    }

    final issueTo = _issueToController.text.trim();
    final remark = _remarkController.text.trim();
    final isCredit = issueTo.isEmpty && remark.isEmpty;

    setState(() {
      _transactions.insert(
        0,
        ItemTransaction(
          qty: qty,
          unit: widget.item.unit,
          type: isCredit ? ItemTransactionType.credit : ItemTransactionType.debit,
          issueTo: issueTo.isEmpty ? null : issueTo,
          remark: remark.isEmpty ? null : remark,
          dateTime: _selectedDateTime,
        ),
      );
      _qtyController.text = '1';
      _issueToController.clear();
      _remarkController.clear();
      _selectedDateTime = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction saved successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final rows = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroHeader(hPad),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryRed),
                  )
                : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 16),
                        _buildToolbar(),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 10),
                          _buildActiveFilterChips(),
                        ],
                        const SizedBox(height: 16),
                        _buildEntryForm(),
                        const SizedBox(height: 16),
                        _buildResultsHeader(rows.length),
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
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTransactionCard(rows[index], index),
                        childCount: rows.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(double hPad) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B1D1D), Color(0xFF6B1515)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x338B1D1D),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _headerIconButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                  const Spacer(),
                  const AppLogo(size: 34),
                  const Spacer(),
                  _headerIconButton(
                    Icons.filter_list_rounded,
                    _showFilterSheet,
                    showBadge: _hasActiveFilters,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: ItemThumbnail(item: widget.item, height: 52),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item History',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _displayName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _heroChip('SKU: $_displaySku'),
                            _heroChip('Unit: $_displayUnit'),
                            _heroChip('Balance: ${_formatQty(_stockBalance)}'),
                            _heroChip('${_transactions.length} records'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap, {bool showBadge = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryRed, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
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
            value: _formatQty(_netBalance),
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
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: color, height: 1),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntryForm() {
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Transaction',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.headingBlack),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              if (isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildQtyField()),
                        const SizedBox(width: 10),
                        Expanded(child: _buildDateField()),
                        const SizedBox(width: 10),
                        Expanded(child: _buildIssueToField()),
                        const SizedBox(width: 10),
                        Expanded(child: _buildRemarkField()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSaveButton(alignStart: true),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildQtyField()),
                      const SizedBox(width: 10),
                      Expanded(child: _buildDateField()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildIssueToField()),
                      const SizedBox(width: 10),
                      Expanded(child: _buildRemarkField()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSaveButton(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _entryLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.headingBlack),
      ),
    );
  }

  InputDecoration _entryDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.selectionBlue, width: 1.5),
      ),
    );
  }

  Widget _buildQtyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _entryLabel('Qty'),
        TextField(
          controller: _qtyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _entryDecoration(
            hint: 'Qty',
            suffixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    onPressed: () => _adjustQty(1),
                    icon: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textSecondary),
                  ),
                ),
                SizedBox(
                  height: 20,
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    onPressed: () => _adjustQty(-1),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _entryLabel('Date'),
        InkWell(
          onTap: _pickDateTime,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: _entryDecoration(
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
            ),
            child: Text(
              _formatDateInput(_selectedDateTime),
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIssueToField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _entryLabel('Issue To'),
        TextField(
          controller: _issueToController,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _entryDecoration(hint: 'Issue To'),
        ),
      ],
    );
  }

  Widget _buildRemarkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _entryLabel('description'),
        TextField(
          controller: _remarkController,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _entryDecoration(hint: 'Remark'),
        ),
      ],
    );
  }

  Widget _buildSaveButton({bool alignStart = false}) {
    final button = SizedBox(
      height: 44,
      width: alignStart ? 140 : double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveEntry,
        icon: const Icon(Icons.task_alt_rounded, size: 18),
        label: Text('Save', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.selectionBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );

    return alignStart ? button : button;
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
                child: Icon(
                  Icons.tune_rounded,
                  size: 22,
                  color: _hasActiveFilters ? AppColors.primaryRed : AppColors.textDark,
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
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.headingBlack),
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
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryRed),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(ItemTransaction tx, int index) {
    final isCredit = tx.type == ItemTransactionType.credit;
    final accent = isCredit ? _creditColor : _debitColor;
    final accentBg = isCredit ? _creditBg : _debitBg;

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
                                tx.unit,
                                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
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
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
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
            _typeFilter == ItemTransactionType.credit ? 'Credit' : 'Debit',
            () => setState(() => _typeFilter = null),
          ),
        if (_issueToFilter != null)
          _activeFilterChip('Issue To: $_issueToFilter', () => setState(() => _issueToFilter = null)),
        if (_dateFilter != _HistoryDateFilter.all)
          _activeFilterChip(_dateFilter.label, () => setState(() => _dateFilter = _HistoryDateFilter.all)),
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
              style: GoogleFonts.poppins(color: AppColors.primaryRed, fontSize: 12, fontWeight: FontWeight.w600),
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
                          TextButton(onPressed: () {
                            _clearFilters();
                            Navigator.pop(context);
                          }, child: Text('Clear', style: GoogleFonts.poppins(color: AppColors.primaryRed, fontWeight: FontWeight.w600))),
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
                    ]),
                    const SizedBox(height: 16),
                    _filterSection('Date Range', Icons.date_range_rounded, [
                      ..._HistoryDateFilter.values.map((filter) => _filterChip(filter.label, _dateFilter == filter, () {
                        setState(() => _dateFilter = filter);
                        Navigator.pop(context);
                      })),
                    ]),
                    if (_issueToOptions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _filterSection('Issue To', Icons.person_outline_rounded, [
                        _filterChip('All', _issueToFilter == null, () {
                          setState(() => _issueToFilter = null);
                          Navigator.pop(context);
                        }),
                        ..._issueToOptions.map((issueTo) => _filterChip(issueTo, _issueToFilter == issueTo, () {
                          setState(() => _issueToFilter = issueTo);
                          Navigator.pop(context);
                        })),
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
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.headingBlack),
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
        color: selected ? AppColors.primaryRed.withValues(alpha: 0.4) : AppColors.borderGray.withValues(alpha: 0.5),
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
            decoration: BoxDecoration(
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
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.headingBlack),
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
                style: GoogleFonts.poppins(color: AppColors.primaryRed, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _HistoryDateFilter {
  all('All'),
  today('Today'),
  last7('Last 7 days'),
  last30('Last 30 days'),
  thisMonth('This month');

  const _HistoryDateFilter(this.label);

  final String label;
}
