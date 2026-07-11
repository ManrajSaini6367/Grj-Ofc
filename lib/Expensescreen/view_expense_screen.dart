import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Expensescreen/add_expense_screen.dart';
import 'package:grjoffice_apps/Expensescreen/expense.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ViewExpenseScreen extends StatefulWidget {
  const ViewExpenseScreen({super.key, required this.expense});

  final Expense expense;

  @override
  State<ViewExpenseScreen> createState() => _ViewExpenseScreenState();
}

class _ViewExpenseScreenState extends State<ViewExpenseScreen> {
  bool _isLoading = true;
  Expense? _detail;
  bool _didUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExpense());
  }

  Future<void> _loadExpense() async {
    final expenseId = int.tryParse(widget.expense.id);
    if (expenseId == null) {
      if (!mounted) return;
      setState(() {
        _detail = widget.expense;
        _isLoading = false;
      });
      return;
    }

    final expense = await getExpenseApi(context, expenseId);
    if (!mounted) return;
    setState(() {
      _detail = expense ?? widget.expense;
      _isLoading = false;
    });
  }

  Expense get _expense => _detail ?? widget.expense;

  void _goBack() {
    Navigator.pop(context, _didUpdate ? _expense : null);
  }

  Future<void> _editExpense() async {
    final updated = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: _expense)),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _detail = updated;
      _didUpdate = true;
    });
  }

  Future<void> _deleteExpense() async {
    final expense = _expense;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Delete Expense',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${expense.title}"?',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final expenseId = int.tryParse(expense.id);
    if (expenseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid expense id.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final ok = await deleteExpenseApi(context, expenseId);
    if (!mounted || !ok) return;

    Navigator.pop(context, 'deleted');
  }

  String _text(String? value, {String fallback = '—'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final expense = _expense;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Expense Details',
              onBack: _goBack,
              horizontalPadding: hPad,
              actions: [
                IconButton(
                  onPressed: _isLoading ? null : _editExpense,
                  icon: const Icon(Icons.edit_outlined, color: AppColors.headingBlack),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _deleteExpense,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.primaryRed),
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: _loadExpense,
                      child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(expense),
                              const SizedBox(height: 16),
                              _buildQuickStats(expense),
                              const SizedBox(height: 16),
                              _buildSection(
                                title: 'Details',
                                icon: Icons.receipt_long_outlined,
                                children: [
                                  _infoTile(Icons.title_rounded, 'Title', expense.title),
                                  _infoTile(
                                    Icons.notes_rounded,
                                    'Detail',
                                    _text(expense.detail, fallback: expense.title),
                                  ),
                                  _infoTile(
                                    Icons.category_outlined,
                                    'Category',
                                    expense.categoryLabel,
                                  ),
                                  _infoTile(
                                    Icons.comment_outlined,
                                    'Remark',
                                    _text(expense.remark),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSection(
                                title: 'Payment',
                                icon: Icons.payments_outlined,
                                children: [
                                  _infoTile(
                                    Icons.swap_vert_rounded,
                                    'Type',
                                    expense.entryTypeLabel ?? '—',
                                  ),
                                  _infoTile(
                                    Icons.account_balance_wallet_outlined,
                                    'Source',
                                    expense.paymentModeLabel,
                                  ),
                                  _infoTile(
                                    Icons.person_outline,
                                    'Paid To',
                                    _text(expense.paidTo),
                                  ),
                                  _infoTile(
                                    Icons.verified_outlined,
                                    'Status',
                                    expense.statusLabel,
                                  ),
                                  if (expense.chequeNo != null &&
                                      expense.chequeNo!.trim().isNotEmpty)
                                    _infoTile(
                                      Icons.money_outlined,
                                      'Cheque No',
                                      expense.chequeNo!,
                                    ),
                                  _infoTile(
                                    Icons.confirmation_number_outlined,
                                    'Voucher No',
                                    _text(expense.voucherNo),
                                  ),
                                  if (expense.challanNo != null &&
                                      expense.challanNo!.trim().isNotEmpty)
                                    _infoTile(
                                      Icons.article_outlined,
                                      'Challan No',
                                      expense.challanNo!,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSection(
                                title: 'Site & Balance',
                                icon: Icons.apartment_outlined,
                                children: [
                                  _infoTile(
                                    Icons.location_on_outlined,
                                    'Site',
                                    _text(expense.siteName),
                                  ),
                                  _infoTile(
                                    Icons.calendar_today_outlined,
                                    'Date',
                                    formatExpenseListDate(expense.date),
                                  ),
                                  _infoTile(
                                    Icons.account_balance_outlined,
                                    'Balance Amount',
                                    expense.balanceAmount == null
                                        ? '—'
                                        : formatExpenseAmount(expense.balanceAmount!),
                                  ),
                                  _infoTile(
                                    Icons.tag_rounded,
                                    'Expense ID',
                                    '#${expense.id}',
                                  ),
                                ],
                              ),
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

  Widget _buildHeader(Expense expense) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            expense.title,
            style: GoogleFonts.poppins(
              color: AppColors.headingBlack,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatExpenseAmount(expense.amount),
            style: GoogleFonts.poppins(
              color: AppColors.primaryRed,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(expense.categoryLabel, AppColors.primaryRed),
              _chip(expense.statusLabel, const Color(0xFF10B981)),
              if (expense.entryTypeLabel != null)
                _chip(expense.entryTypeLabel!, const Color(0xFF2563EB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickStats(Expense expense) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.payments_outlined,
            label: 'Payment',
            value: expense.paymentModeLabel,
            color: AppColors.primaryRed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.swap_vert_rounded,
            label: 'Type',
            value: expense.entryTypeLabel ?? '—',
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.verified_outlined,
            label: 'Status',
            value: expense.statusLabel,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: AppColors.headingBlack,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderGray.withValues(alpha: 0.45)),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
