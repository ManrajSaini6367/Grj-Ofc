import 'package:flutter/material.dart';

/// Report card shown on the list screen. Values will come from API later.
class ReportListItem {
  const ReportListItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.accentColor = const Color(0xFFF59E0B),
  });

  final String id;
  final String title;
  final String subtitle;
  final ReportType type;
  final Color accentColor;
}

enum ReportType {
  labourAttendance,
  challan,
  expenses,
  dayReport,
  itemReport,
  employerAttendance,
}

/// Temporary preview list for UI only — replace with API response later.
List<ReportListItem> previewReportItems({required String siteName}) {
  return [
    const ReportListItem(
      id: 'labour_attendance',
      title: 'Labour Attendance Report',
      subtitle: 'LABOUR ATTENDANCE',
      type: ReportType.labourAttendance,
      accentColor: Color(0xFFF59E0B),
    ),
    const ReportListItem(
      id: 'chalan',
      title: 'Chalan Report',
      subtitle: 'CHALAN REPORT',
      type: ReportType.challan,
      accentColor: Color(0xFFEF4444),
    ),
    const ReportListItem(
      id: 'expenses',
      title: 'Expenses Report',
      subtitle: 'EXPENSES REPORT',
      type: ReportType.expenses,
      accentColor: Color(0xFF22C55E),
    ),
    const ReportListItem(
      id: 'day_report',
      title: 'Day Report',
      subtitle: 'DAY REPORT',
      type: ReportType.dayReport,
      accentColor: Color(0xFFF59E0B),
    ),
    const ReportListItem(
      id: 'item_1',
      title: 'Grit 10MM Report',
      subtitle: 'GRIT 10MM REPORT',
      type: ReportType.itemReport,
      accentColor: Color(0xFFF59E0B),
    ),
    const ReportListItem(
      id: 'item_2',
      title: 'sariya Report',
      subtitle: 'SARIYA REPORT',
      type: ReportType.itemReport,
      accentColor: Color(0xFFF59E0B),
    ),
    const ReportListItem(
      id: 'item_3',
      title: 'blacksendreti Report',
      subtitle: 'BLACKSENDRETI REPORT',
      type: ReportType.itemReport,
      accentColor: Color(0xFFF59E0B),
    ),
    const ReportListItem(
      id: 'employer_attendance',
      title: 'Employer Attendance',
      subtitle: 'EMPLOYER ATTENDANCE',
      type: ReportType.employerAttendance,
      accentColor: Color(0xFFF59E0B),
    ),
  ];
}
