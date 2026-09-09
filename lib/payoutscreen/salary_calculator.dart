import 'dart:math' as math;

/// Salary structure, PF and ESI rules used to generate a payslip.
///
/// Structure: statutory minimum is 50% basic, the company uses 55% basic and
/// 45% HRA. PF is 12% of basic capped at a [pfWageCeiling] basic. ESI is 0.75%
/// of basic and stops once basic crosses [esiWageLimit], except that an
/// employee who crosses the limit mid period keeps contributing until the
/// contribution quarter (June / September / December / March) is over.
abstract final class SalaryRules {
  static const double defaultBasicPercent = 55;
  static const double minBasicPercent = 50;

  static const double pfRate = 0.12;
  static const double pfWageCeiling = 15000;

  static const double esiRate = 0.0075;
  static const double esiWageLimit = 21000;

  /// ESI keeps applying until one of these months is over.
  static bool isContributionQuarterEnd(int month) =>
      month == DateTime.june ||
      month == DateTime.september ||
      month == DateTime.december ||
      month == DateTime.march;

  /// ESI applies while basic stays under the wage limit.
  static bool esiAppliesTo(double basic) => basic > 0 && basic < esiWageLimit;
}

/// Everything the user can edit on the generate-salary form.
class SalaryInput {
  const SalaryInput({
    required this.monthlyPackage,
    required this.monthDays,
    required this.payableDays,
    this.basicPercent = SalaryRules.defaultBasicPercent,
    this.pfApplicable = true,
    this.esiApplicable = true,
    this.otherDeduction = 0,
  });

  /// Full month gross package agreed with the employee.
  final double monthlyPackage;
  final int monthDays;

  /// Present days plus paid leaves. Half days are allowed.
  final double payableDays;
  final double basicPercent;
  final bool pfApplicable;
  final bool esiApplicable;

  /// Advance or any other recovery.
  final double otherDeduction;

  double get hraPercent => 100 - basicPercent;

  SalaryInput copyWith({
    double? monthlyPackage,
    int? monthDays,
    double? payableDays,
    double? basicPercent,
    bool? pfApplicable,
    bool? esiApplicable,
    double? otherDeduction,
  }) {
    return SalaryInput(
      monthlyPackage: monthlyPackage ?? this.monthlyPackage,
      monthDays: monthDays ?? this.monthDays,
      payableDays: payableDays ?? this.payableDays,
      basicPercent: basicPercent ?? this.basicPercent,
      pfApplicable: pfApplicable ?? this.pfApplicable,
      esiApplicable: esiApplicable ?? this.esiApplicable,
      otherDeduction: otherDeduction ?? this.otherDeduction,
    );
  }
}

/// Applies the statutory PF and ESI defaults to [input].
///
/// Basic does not depend on the two flags, so the sheet can be costed once to
/// find the basic and then re-flagged from it.
SalaryInput withStatutoryDefaults(SalaryInput input) {
  final basic = SalaryBreakdown.from(input).earnedBasic;
  return input.copyWith(
    pfApplicable: basic > 0,
    esiApplicable: SalaryRules.esiAppliesTo(basic),
  );
}

/// Rupee amounts produced from a [SalaryInput]. Every value is a whole rupee so
/// the components always add back up to the totals shown on the payslip.
class SalaryBreakdown {
  const SalaryBreakdown({
    required this.fullBasic,
    required this.fullHra,
    required this.fullGross,
    required this.earnedBasic,
    required this.earnedHra,
    required this.earnedGross,
    required this.pf,
    required this.esi,
    required this.otherDeduction,
  });

  /// Full month figures, shown in the payslip "Gross Pay" column.
  final double fullBasic;
  final double fullHra;
  final double fullGross;

  /// Attendance adjusted figures, shown in the "Earnings" column.
  final double earnedBasic;
  final double earnedHra;
  final double earnedGross;

  final double pf;
  final double esi;
  final double otherDeduction;

  double get totalDeduction => pf + esi + otherDeduction;

  double get netPayable => math.max(0, earnedGross - totalDeduction);

  /// Builds the breakdown by splitting the package into basic and HRA, then
  /// prorating it over the payable days.
  ///
  /// HRA is floored and basic takes the remainder so basic + HRA never drifts
  /// away from the gross by a rounding rupee.
  factory SalaryBreakdown.from(SalaryInput input) {
    final hraShare = input.hraPercent / 100;

    final fullGross = math.max(0.0, input.monthlyPackage).roundToDouble();
    final fullHra = (fullGross * hraShare).floorToDouble();
    final fullBasic = fullGross - fullHra;

    final ratio = input.monthDays <= 0
        ? 0.0
        : (input.payableDays / input.monthDays).clamp(0.0, 1.0);
    final earnedGross = (fullGross * ratio).roundToDouble();
    final earnedHra = (earnedGross * hraShare).floorToDouble();
    final earnedBasic = earnedGross - earnedHra;

    final pf = input.pfApplicable
        ? (math.min(earnedBasic, SalaryRules.pfWageCeiling) * SalaryRules.pfRate)
              .roundToDouble()
        : 0.0;
    final esi = input.esiApplicable
        ? (earnedBasic * SalaryRules.esiRate).roundToDouble()
        : 0.0;

    return SalaryBreakdown(
      fullBasic: fullBasic,
      fullHra: fullHra,
      fullGross: fullGross,
      earnedBasic: earnedBasic,
      earnedHra: earnedHra,
      earnedGross: earnedGross,
      pf: pf,
      esi: esi,
      otherDeduction: math.max(0, input.otherDeduction).roundToDouble(),
    );
  }
}

/// Converts a rupee amount into the words printed at the bottom of a payslip,
/// e.g. `Rupees Ninety-Six Thousand Six Hundred Sixty-Seven Only`.
String rupeesInWords(double amount) {
  final value = amount.round();
  if (value <= 0) return 'Rupees Zero Only';
  return 'Rupees ${_wordsFor(value)} Only';
}

const _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];

const _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

String _wordsFor(int value) {
  // Indian numbering: crore, lakh, thousand, hundred.
  final parts = <String>[];

  void take(int divisor, String label) {
    final count = value ~/ divisor;
    if (count == 0) return;
    parts.add('${_wordsFor(count)} $label');
    value %= divisor;
  }

  take(10000000, 'Crore');
  take(100000, 'Lakh');
  take(1000, 'Thousand');
  take(100, 'Hundred');

  if (value > 0) {
    if (value < 20) {
      parts.add(_ones[value]);
    } else {
      final tens = _tens[value ~/ 10];
      final ones = value % 10;
      parts.add(ones == 0 ? tens : '$tens-${_ones[ones]}');
    }
  }

  return parts.join(' ');
}
