import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Expensescreen/expense.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

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
  String _entryType = kExpenseEntryTypes.first;
  String _source = 'Cheque';
  bool _isSaving = false;

  bool get _isChequeSource => _source == 'Cheque';

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
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final chequeNo = _chequeController.text.trim();
    final voucherNo = _voucherController.text.trim();

    final expense = Expense(
      id: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
      date: _expenseDate,
      title: detail,
      category: ExpenseCategory.miscellaneous,
      amount: amount,
      paidTo: '—',
      paymentMode: expensePaymentModeFromSource(_source),
      status: ExpenseStatus.paid,
      entryType: _entryType == 'Credit' ? ExpenseEntryType.credit : ExpenseEntryType.debit,
      chequeNo: _isChequeSource && chequeNo.isNotEmpty ? chequeNo : null,
      voucherNo: voucherNo.isEmpty ? null : voucherNo,
      remark: detail,
    );

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
              title: 'Add Expenses',
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
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildSourceField()),
                                    ],
                                  )
                                else ...[
                                  _buildDateField(),
                                  const SizedBox(height: 16),
                                  _buildTypeField(),
                                  const SizedBox(height: 16),
                                  _buildSourceField(),
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
                                _buildDetailField(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 44,
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
                                  'Save',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 22),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
          if (value != null) setState(() => _entryType = value);
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
      label: 'voucher_no',
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
      label: 'detail',
      child: TextFormField(
        controller: _detailController,
        maxLines: 1,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: _fieldDecoration(hint: 'detail'),
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
