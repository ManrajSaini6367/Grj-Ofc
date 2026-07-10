import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _period = 'This Month';

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.report,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Reports',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                children: [
                  Text(
                    'Period',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Today', 'This Week', 'This Month', 'Custom'].map((label) {
                      final selected = _period == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => _period = label),
                        selectedColor: AppColors.primaryRed.withValues(alpha: 0.15),
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.primaryRed : AppColors.textDark,
                        ),
                        side: BorderSide(
                          color: selected ? AppColors.primaryRed : AppColors.borderGray,
                        ),
                        backgroundColor: AppColors.cardWhite,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Available Reports',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headingBlack,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._kReports.map(_reportCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(_ReportItem report) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${report.title} — $_period report ready to export.')),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(report.icon, color: AppColors.primaryRed, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headingBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.subtitle,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.file_download_outlined, color: AppColors.textSecondary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportItem {
  const _ReportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

const _kReports = [
  _ReportItem(
    title: 'Attendance Report',
    subtitle: 'Employee punch in/out summary',
    icon: Icons.how_to_reg_outlined,
  ),
  _ReportItem(
    title: 'Purchase Report',
    subtitle: 'Purchase orders and spend',
    icon: Icons.shopping_cart_outlined,
  ),
  _ReportItem(
    title: 'Store Stock Report',
    subtitle: 'Inventory balances by item',
    icon: Icons.storefront_outlined,
  ),
  _ReportItem(
    title: 'Expense Report',
    subtitle: 'Category-wise expense breakdown',
    icon: Icons.account_balance_wallet_outlined,
  ),
  _ReportItem(
    title: 'Day End Report',
    subtitle: 'Daily site activity summary',
    icon: Icons.event_note_outlined,
  ),
  _ReportItem(
    title: 'Contractor Report',
    subtitle: 'Labour contractor attendance & rates',
    icon: Icons.groups_outlined,
  ),
];
