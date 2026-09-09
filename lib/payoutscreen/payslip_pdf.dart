import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:grjoffice_apps/payoutscreen/salary_calculator.dart';

/// Employer block printed at the top of every payslip.
abstract final class PayslipCompany {
  static const String name = 'Gulshan Rai Jain II';
  static const List<String> addressLines = [
    'N-29, Adinath Nagar, Opp. World Trade Park,',
    'Jai Jawan Colony-III, Malviya Nagar,',
    'Jaipur, RAJASTHAN, 302017',
  ];
  static const String logoAsset = 'assets/images/grj_logo.png';
}

/// A single attendance line in the payslip's left column, e.g. `P  20.0`.
class PayslipAttendanceLine {
  const PayslipAttendanceLine(this.label, this.value);

  final String label;
  final String value;
}

/// Everything printed on one payslip.
class PayslipData {
  const PayslipData({
    required this.month,
    required this.employeeName,
    required this.breakdown,
    this.employeeCode = '',
    this.department = '',
    this.designation = '',
    this.dateOfJoining = '',
    this.gender = '',
    this.dateOfBirth = '',
    this.bankName = '',
    this.location = '',
    this.uan = '',
    this.esiNumber = '',
    this.pan = '',
    this.aadhaar = '',
    this.bankAccountNumber = '',
    this.remarks = '',
    this.attendance = const [],
  });

  final DateTime month;
  final String employeeName;
  final SalaryBreakdown breakdown;

  final String employeeCode;
  final String department;
  final String designation;
  final String dateOfJoining;
  final String gender;
  final String dateOfBirth;
  final String bankName;
  final String location;
  final String uan;
  final String esiNumber;
  final String pan;
  final String aadhaar;
  final String bankAccountNumber;
  final String remarks;
  final List<PayslipAttendanceLine> attendance;

  String get monthLabel => DateFormat('MMMM yyyy').format(month);

  String get fileName {
    final safeName = employeeName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return 'Payslip_${safeName}_${DateFormat('MMM_yyyy').format(month)}.pdf';
  }
}

/// Renders [data] to a PDF and writes it into the app's documents directory.
Future<File> generatePayslipFile(PayslipData data) async {
  final bytes = await buildPayslipPdf(data);
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/${data.fileName}');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<Uint8List> buildPayslipPdf(PayslipData data) async {
  final logo = await _loadLogo();
  final document = pw.Document();

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(logo),
          pw.SizedBox(height: 26),
          pw.Center(
            child: pw.Text(
              'Payslip for the month of ${data.monthLabel}',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 18),
          _employeeDetails(data),
          pw.SizedBox(height: 14),
          _salaryTable(data),
          pw.SizedBox(height: 4),
          _footNote(data),
          if (data.remarks.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Remarks: ${data.remarks}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
          pw.SizedBox(height: 60),
          _signature(),
        ],
      ),
    ),
  );

  return document.save();
}

Future<pw.MemoryImage?> _loadLogo() async {
  try {
    final data = await rootBundle.load(PayslipCompany.logoAsset);
    return pw.MemoryImage(data.buffer.asUint8List());
  } catch (_) {
    // The payslip is still valid without the logo.
    return null;
  }
}

pw.Widget _header(pw.MemoryImage? logo) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 64,
        height: 64,
        child: logo == null ? pw.SizedBox() : pw.Image(logo),
      ),
      pw.Expanded(
        child: pw.Column(
          children: [
            pw.Text(
              PayslipCompany.name,
              style: pw.TextStyle(
                fontSize: 17,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            for (final line in PayslipCompany.addressLines)
              pw.Text(
                line,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
      pw.SizedBox(width: 64),
    ],
  );
}

pw.Widget _employeeDetails(PayslipData data) {
  final left = <List<String>>[
    ['Employee Name :', data.employeeName],
    ['Department :', data.department],
    ['Date of Joining :', data.dateOfJoining],
    ['Gender :', data.gender],
    ['Date of Birth :', data.dateOfBirth],
    ['Bank Name :', data.bankName],
    ['Location :', data.location],
  ];
  final right = <List<String>>[
    ['Code :', data.employeeCode],
    ['Designation :', data.designation],
    ['UAN :', data.uan],
    ['ESI A/c No :', data.esiNumber],
    ['PAN :', data.pan],
    ['Aadhar No :', data.aadhaar],
    ['Bank A/c No :', data.bankAccountNumber],
  ];

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(child: _detailColumn(left)),
      pw.SizedBox(width: 20),
      pw.Expanded(child: _detailColumn(right)),
    ],
  );
}

pw.Widget _detailColumn(List<List<String>> rows) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final row in rows)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 92,
                child: pw.Text(row[0], style: const pw.TextStyle(fontSize: 8)),
              ),
              pw.Expanded(
                child: pw.Text(
                  row[1],
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _salaryTable(PayslipData data) {
  final breakdown = data.breakdown;
  final deductions = <List<String>>[
    if (breakdown.pf > 0) ['EPF', _amount(breakdown.pf)],
    if (breakdown.esi > 0) ['ESI', _amount(breakdown.esi)],
    if (breakdown.otherDeduction > 0)
      ['Advance', _amount(breakdown.otherDeduction)],
  ];

  const border = pw.TableBorder(
    left: pw.BorderSide(width: 0.7),
    right: pw.BorderSide(width: 0.7),
    top: pw.BorderSide(width: 0.7),
    bottom: pw.BorderSide(width: 0.7),
    horizontalInside: pw.BorderSide(width: 0.7),
    verticalInside: pw.BorderSide(width: 0.7),
  );

  return pw.Table(
    border: border,
    columnWidths: const {
      0: pw.FlexColumnWidth(1.15),
      1: pw.FlexColumnWidth(0.75),
      2: pw.FlexColumnWidth(1.85),
      3: pw.FlexColumnWidth(0.85),
      4: pw.FlexColumnWidth(0.85),
      5: pw.FlexColumnWidth(1.0),
      6: pw.FlexColumnWidth(0.7),
    },
    children: [
      pw.TableRow(
        children: [
          _headerCell('Attendance', align: pw.TextAlign.center),
          _headerCell(''),
          _headerCell('Heads of Incomes'),
          _headerCell('Gross Pay', align: pw.TextAlign.center),
          _headerCell('Earnings', align: pw.TextAlign.center),
          _headerCell('Deductions', align: pw.TextAlign.center),
          _headerCell(''),
        ],
      ),
      pw.TableRow(
        children: [
          _stackCell([for (final line in data.attendance) line.label]),
          _stackCell([for (final line in data.attendance) line.value]),
          _stackCell(['Basic Salary', 'House Rent Allowance']),
          _stackCell([
            _amount(breakdown.fullBasic),
            _amount(breakdown.fullHra),
          ], align: pw.TextAlign.right),
          _stackCell([
            _amount(breakdown.earnedBasic),
            _amount(breakdown.earnedHra),
          ], align: pw.TextAlign.right),
          _stackCell([for (final row in deductions) row[0]]),
          _stackCell([
            for (final row in deductions) row[1],
          ], align: pw.TextAlign.right),
        ],
      ),
      pw.TableRow(
        children: [
          _bodyCell(''),
          _bodyCell(''),
          _bodyCell('Round Off', align: pw.TextAlign.right),
          _bodyCell(''),
          _bodyCell(''),
          _bodyCell(''),
          _bodyCell(''),
        ],
      ),
      pw.TableRow(
        children: [
          _bodyCell('Month Days'),
          _bodyCell('PD : ${_days(data)}', bold: true),
          _bodyCell('TOTAL', align: pw.TextAlign.right, bold: true),
          _bodyCell(
            _amount(breakdown.fullGross),
            align: pw.TextAlign.right,
            bold: true,
          ),
          _bodyCell(
            _amount(breakdown.earnedGross),
            align: pw.TextAlign.right,
            bold: true,
          ),
          _bodyCell('TOTAL', bold: true),
          _bodyCell(
            breakdown.totalDeduction > 0
                ? _amount(breakdown.totalDeduction)
                : '',
            align: pw.TextAlign.right,
            bold: true,
          ),
        ],
      ),
      pw.TableRow(
        children: [
          _bodyCell(''),
          _bodyCell(''),
          _bodyCell('NET SALARY PAYABLE', bold: true),
          _bodyCell(''),
          _bodyCell(
            _amount(breakdown.netPayable),
            align: pw.TextAlign.right,
            bold: true,
          ),
          _bodyCell(''),
          _bodyCell(''),
        ],
      ),
    ],
  );
}

pw.Widget _footNote(PayslipData data) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Text(
          'P-Present, WO-Weekend Off, AB-Absent',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      pw.Expanded(
        child: pw.Text(
          rupeesInWords(data.breakdown.netPayable),
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}

pw.Widget _signature() {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Text(
        PayslipCompany.name.toUpperCase(),
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 46),
      pw.Text(
        'Authorized Signature',
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );
}

pw.Widget _headerCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
    ),
  );
}

pw.Widget _bodyCell(
  String text, {
  pw.TextAlign align = pw.TextAlign.left,
  bool bold = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 8,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

/// A cell that holds several stacked lines and keeps the tall body row height
/// of the printed payslip even when there are few lines.
pw.Widget _stackCell(
  List<String> lines, {
  pw.TextAlign align = pw.TextAlign.left,
}) {
  return pw.Container(
    height: 118,
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    alignment: align == pw.TextAlign.right
        ? pw.Alignment.topRight
        : pw.Alignment.topLeft,
    child: pw.Column(
      crossAxisAlignment: align == pw.TextAlign.right
          ? pw.CrossAxisAlignment.end
          : pw.CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(line, style: const pw.TextStyle(fontSize: 8)),
          ),
      ],
    ),
  );
}

String _days(PayslipData data) {
  final payDays = data.attendance
      .firstWhere(
        (line) => line.label.toLowerCase() == 'pay days',
        orElse: () => const PayslipAttendanceLine('', ''),
      )
      .value;
  return payDays.isEmpty ? '' : _trimDecimal(payDays);
}

String _trimDecimal(String value) {
  final parsed = double.tryParse(value);
  if (parsed == null) return value;
  return parsed == parsed.roundToDouble()
      ? parsed.round().toString()
      : parsed.toString();
}

/// Printed payslips show plain rupee figures with no grouping separators.
String _amount(double value) => value.round().toString();
