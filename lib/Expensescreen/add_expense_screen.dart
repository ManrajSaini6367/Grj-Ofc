import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Expensescreen/expense.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expense});

  /// When set, screen works in edit mode and calls update API.
  final Expense? expense;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chequeController = TextEditingController();
  final _amountController = TextEditingController();
  final _voucherController = TextEditingController();
  final _detailController = TextEditingController();

  DateTime _expenseDate = DateTime.now();
  String _entryType = 'Debit';
  String _source = 'Cash';
  String _category = kExpenseCategories.first;
  bool _isSaving = false;

  bool get _isEdit => widget.expense != null;
  bool get _isCredit => _entryType == 'Credit';
  bool get _isChequeSource => !_isCredit && _source == 'Cheque';
  bool get _showSource => !_isCredit;

  @override
  void initState() {
    super.initState();
    _prefillFromExpense();
  }

  void _prefillFromExpense() {
    final expense = widget.expense;
    if (expense == null) return;

    _expenseDate = expense.date;
    _entryType = expense.entryType == ExpenseEntryType.credit ? 'Credit' : 'Debit';
    _source = switch (expense.paymentMode) {
      ExpensePaymentMode.cash => 'Cash',
      ExpensePaymentMode.cheque => 'Cheque',
      ExpensePaymentMode.upi => 'UPI',
      ExpensePaymentMode.bank => 'Bank Transfer',
    };
    _category = expense.categoryLabel;
    _amountController.text = expense.amount.toStringAsFixed(
      expense.amount == expense.amount.roundToDouble() ? 0 : 2,
    );
    _voucherController.text = expense.voucherNo ?? '';
    _chequeController.text = expense.chequeNo ?? '';
    _detailController.text = expense.detail?.trim().isNotEmpty == true
        ? expense.detail!.trim()
        : expense.title;
  }

  @override
  void dispose() {
    _chequeController.dispose();
    _amountController.dispose();
    _voucherController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  String _formatApiDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _apiType() => _entryType.toLowerCase();

  String _apiSource() {
    switch (_source) {
      case 'Cash':
        return 'cash';
      case 'Cheque':
        return 'cheque';
      case 'UPI':
        return 'upi';
      case 'Bank Transfer':
      default:
        return 'bank';
    }
  }

  String _apiCategory() {
    switch (_category) {
      case 'Transport':
        return 'transport';
      case 'Labour':
        return 'labour';
      case 'Material':
        return 'material';
      case 'Utilities':
        return 'utilities';
      case 'Miscellaneous':
      default:
        return 'miscellaneous';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final detail = _detailController.text.trim();
    if (detail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter expense detail.', style: GoogleFonts.poppins())),
      );
      return;
    }

    if (_isChequeSource && _chequeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter cheque number.', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() => _isSaving = true);

    Expense? expense;
    if (_isEdit) {
      final expenseId = int.tryParse(widget.expense!.id);
      if (expenseId == null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid expense id.', style: GoogleFonts.poppins())),
        );
        return;
      }
      expense = await updateExpenseApi(
        context,
        expenseId: expenseId,
        date: _formatApiDate(_expenseDate),
        type: _apiType(),
        source: _isCredit ? null : _apiSource(),
        cheque: _isChequeSource ? _chequeController.text.trim() : null,
        amount: amount,
        voucherNo: _voucherController.text.trim(),
        detail: detail,
        category: _apiCategory(),
      );
    } else {
      expense = await createExpenseApi(
        context,
        date: _formatApiDate(_expenseDate),
        type: _apiType(),
        source: _isCredit ? null : _apiSource(),
        cheque: _isChequeSource ? _chequeController.text.trim() : null,
        amount: amount,
        voucherNo: _voucherController.text.trim(),
        detail: detail,
        category: _apiCategory(),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (expense == null) return;
    Navigator.of(context).pop(expense);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: _isEdit ? 'Edit Expense' : 'Add Expenses',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Information Expenses',
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 16),
                                if (isWide)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildDateField()),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildTypeField()),
                                      if (_showSource) ...[
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildSourceField()),
                                      ],
                                    ],
                                  )
                                else ...[
                                  _buildDateField(),
                                  const SizedBox(height: 16),
                                  _buildTypeField(),
                                  if (_showSource) ...[
                                    const SizedBox(height: 16),
                                    _buildSourceField(),
                                  ],
                                ],
                                const SizedBox(height: 20),
                                if (isWide)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_isChequeSource) ...[
                                        Expanded(child: _buildChequeField()),
                                        const SizedBox(width: 12),
                                      ],
                                      Expanded(child: _buildAmountField()),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildVoucherField()),
                                    ],
                                  )
                                else ...[
                                  if (_isChequeSource) ...[
                                    _buildChequeField(),
                                    const SizedBox(height: 16),
                                  ],
                                  _buildAmountField(),
                                  const SizedBox(height: 16),
                                  _buildVoucherField(),
                                ],
                                const SizedBox(height: 20),
                                _buildCategoryField(),
                                const SizedBox(height: 20),
                                _buildDetailField(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _submit,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined, size: 18),
                              label: Text(
                                _isEdit ? 'Update' : 'Save',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: AppColors.white,
                                disabledBackgroundColor:
                                    AppColors.primaryRed.withValues(alpha: 0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
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

  Widget _buildDateField() {
    return _labeledField(
      label: 'Date',
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(6),
        child: InputDecorator(
          decoration: _fieldDecoration(),
          child: Text(
            formatExpenseFormDate(_expenseDate),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeField() {
    return _labeledField(
      label: 'Type',
      child: DropdownButtonFormField<String>(
        initialValue: _entryType,
        decoration: _fieldDecoration(),
        items: kExpenseEntryTypes
            .map((type) => DropdownMenuItem(value: type, child: Text(type, style: GoogleFonts.poppins(fontSize: 13))))
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _entryType = value;
            if (_isCredit) {
              _chequeController.clear();
            }
          });
        },
      ),
    );
  }

  Widget _buildSourceField() {
    return _labeledField(
      label: 'Source',
      child: DropdownButtonFormField<String>(
        initialValue: _source,
        decoration: _fieldDecoration(),
        items: kExpenseSources
            .map((source) => DropdownMenuItem(value: source, child: Text(source, style: GoogleFonts.poppins(fontSize: 13))))
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _source = value;
            if (!_isChequeSource) _chequeController.clear();
          });
        },
      ),
    );
  }

  Widget _buildCategoryField() {
    return _labeledField(
      label: 'Category',
      child: DropdownButtonFormField<String>(
        initialValue: _category,
        decoration: _fieldDecoration(),
        items: kExpenseCategories
            .map(
              (category) => DropdownMenuItem(
                value: category,
                child: Text(category, style: GoogleFonts.poppins(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _category = value);
        },
      ),
    );
  }

  Widget _buildChequeField() {
    return _labeledField(
      label: 'Cheque No',
      child: TextFormField(
        controller: _chequeController,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: _fieldDecoration(hint: 'Cheque'),
      ),
    );
  }

  Widget _buildAmountField() {
    return _labeledField(
      label: 'Amount',
      child: TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: _fieldDecoration(hint: 'amount'),
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildVoucherField() {
    return _labeledField(
      label: 'Voucher No',
      child: TextFormField(
        controller: _voucherController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: _fieldDecoration(hint: 'voucher_no'),
      ),
    );
  }

  Widget _buildDetailField() {
    return _labeledField(
      label: 'Detail',
      child: TextFormField(
        controller: _detailController,
        maxLines: 1,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: _fieldDecoration(hint: 'detail'),
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.operationsCardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.5), width: 1.5),
      ),
    );
  }

  double _hPad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 14;
    if (w < 600) return 18;
    return 20;
  }
}
