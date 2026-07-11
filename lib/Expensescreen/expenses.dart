import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/Expensescreen/add_expense_screen.dart';
import 'package:grjoffice_apps/Expensescreen/expense.dart';
import 'package:grjoffice_apps/Expensescreen/view_expense_screen.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ExpenseCategory? _categoryFilter;
  _ExpensePeriod _period = _ExpensePeriod.thisMonth;
  List<Expense> _expenses = [];
  double _totalAmount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExpenses());
  }

  String get _apiPeriod {
    switch (_period) {
      case _ExpensePeriod.thisMonth:
        return 'this_month';
      case _ExpensePeriod.last7:
        return 'last_7';
      case _ExpensePeriod.last30:
        return 'last_30';
      case _ExpensePeriod.allTime:
        return 'all';
    }
  }

  Future<void> _loadExpenses({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);

    final response = await getExpensesApi(
      context,
      period: _apiPeriod,
      category: _categoryFilter?.name,
      perPage: 50,
    );

    if (!mounted) return;
    setState(() {
      _expenses = response?.data?.items ?? [];
      _totalAmount = response?.data?.totalAmount ?? 0;
      _isLoading = false;
    });
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 16;
    if (width < 600) return 20;
    return 24;
  }

  List<Expense> get _filteredExpenses => List<Expense>.from(_expenses)
    ..sort((a, b) => b.date.compareTo(a.date));

  double get _filteredTotal =>
      _totalAmount > 0 ? _totalAmount : _filteredExpenses.fold(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final rows = _filteredExpenses;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(selectedIndex: DrawerIndex.expenses, onItemTap: _onDrawerItemTap),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar.shell(
              title: 'My Expenses',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
              actions: [
                Material(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _openAddExpense,
                    borderRadius: BorderRadius.circular(10),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(Icons.add, color: AppColors.white, size: 22),
                    ),
                  ),
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
                      onRefresh: () => _loadExpenses(showLoader: false),
                      child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                      children: [
                        _buildTotalCard(),
                        const SizedBox(height: 20),
                        _buildCategoryFilters(),
                        const SizedBox(height: 24),
                        Text(
                          'Recent Expenses',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.headingBlack,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (rows.isEmpty)
                          _buildEmptyState()
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < rows.length; i++) ...[
                                  _buildExpenseRow(rows[i], highlightAmount: i == 0),
                                  if (i < rows.length - 1)
                                    Divider(
                                      height: 1,
                                      indent: 72,
                                      color: AppColors.borderGray.withValues(alpha: 0.35),
                                    ),
                                ],
                              ],
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

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }

  Future<void> _openAddExpense() async {
    final result = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Expense ${result.id} saved.')),
    );
    await _loadExpenses();
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Expenses',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  formatExpenseAmount(_filteredTotal),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPeriodDropdown(),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryRed, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.operationsCardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_ExpensePeriod>(
          value: _period,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500),
          items: const [
            DropdownMenuItem(value: _ExpensePeriod.thisMonth, child: Text('This Month')),
            DropdownMenuItem(value: _ExpensePeriod.last7, child: Text('Last 7 Days')),
            DropdownMenuItem(value: _ExpensePeriod.last30, child: Text('Last 30 Days')),
            DropdownMenuItem(value: _ExpensePeriod.allTime, child: Text('All Time')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _period = value);
            _loadExpenses();
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    const filters = <_CategoryFilterItem>[
      _CategoryFilterItem(label: 'All', icon: Icons.grid_view_rounded, category: null),
      _CategoryFilterItem(label: 'Transport', icon: Icons.local_shipping_outlined, category: ExpenseCategory.transport),
      _CategoryFilterItem(label: 'Labour', icon: Icons.engineering_outlined, category: ExpenseCategory.labour),
      _CategoryFilterItem(label: 'Material', icon: Icons.inventory_2_outlined, category: ExpenseCategory.material),
      _CategoryFilterItem(label: 'Utilities', icon: Icons.home_outlined, category: ExpenseCategory.utilities),
      _CategoryFilterItem(label: 'More', icon: Icons.more_horiz, category: ExpenseCategory.miscellaneous),
    ];

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = filters[index];
          final selected = _categoryFilter == item.category;
          final color = item.category == null
              ? AppColors.primaryRed
              : _categoryStyle(item.category!).color;

          return GestureDetector(
            onTap: () {
              setState(() => _categoryFilter = item.category);
              _loadExpenses();
            },
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? color : AppColors.cardWhite,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: selected ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpenseRow(Expense expense, {bool highlightAmount = false}) {
    final style = _categoryStyle(expense.category);
    final amountColor = highlightAmount ? AppColors.primaryRed : AppColors.headingBlack;

    return InkWell(
      onTap: () => _showDetails(expense),
      onLongPress: () => _showExpenseMenu(expense),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: style.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.categoryLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.headingBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatExpenseListDate(expense.date),
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
            Text(
              formatExpenseAmount(expense.amount),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryRed, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.headingBlack),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another category or time period',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(Expense expense) async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(builder: (_) => ViewExpenseScreen(expense: expense)),
    );
    if (!mounted || result == null) return;

    if (result == 'deleted') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense "${expense.title}" deleted')),
      );
      await _loadExpenses();
      return;
    }

    if (result is Expense) {
      await _loadExpenses();
    }
  }

  Future<void> _openEditExpense(Expense expense) async {
    final updated = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: expense)),
    );
    if (updated == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Expense ${updated.id} updated.')),
    );
    await _loadExpenses();
  }

  Future<void> _deleteExpense(Expense expense) async {
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

    setState(() => _expenses.removeWhere((e) => e.id == expense.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Expense "${expense.title}" deleted')),
    );
  }

  void _showExpenseMenu(Expense expense) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text('Edit Expense', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _openEditExpense(expense);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.primaryRed),
                title: Text('Delete Expense', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primaryRed)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteExpense(expense);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  _CategoryVisual _categoryStyle(ExpenseCategory category) => switch (category) {
        ExpenseCategory.transport => _CategoryVisual(
            Icons.local_shipping_outlined,
            AppColors.selectionBlue,
            AppColors.selectionBlue.withValues(alpha: 0.12),
          ),
        ExpenseCategory.labour => _CategoryVisual(
            Icons.engineering_outlined,
            AppColors.primaryRed,
            AppColors.primaryRed.withValues(alpha: 0.1),
          ),
        ExpenseCategory.material => _CategoryVisual(
            Icons.shopping_bag_outlined,
            const Color(0xFF059669),
            const Color(0xFF059669).withValues(alpha: 0.12),
          ),
        ExpenseCategory.utilities => _CategoryVisual(
            Icons.home_outlined,
            const Color(0xFFD97706),
            const Color(0xFFD97706).withValues(alpha: 0.12),
          ),
        ExpenseCategory.miscellaneous => _CategoryVisual(
            Icons.confirmation_number_outlined,
            AppColors.textDark,
            AppColors.iconBgGray,
          ),
      };
}

enum _ExpensePeriod { thisMonth, last7, last30, allTime }

class _CategoryFilterItem {
  const _CategoryFilterItem({
    required this.label,
    required this.icon,
    required this.category,
  });

  final String label;
  final IconData icon;
  final ExpenseCategory? category;
}

class _CategoryVisual {
  const _CategoryVisual(this.icon, this.color, this.bg);

  final IconData icon;
  final Color color;
  final Color bg;
}
