import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

/// Day End Report detail for a selected date (API later).
class DayEndReportDetailScreen extends StatefulWidget {
  const DayEndReportDetailScreen({
    super.key,
    required this.selectedDate,
  });

  final DateTime selectedDate;

  @override
  State<DayEndReportDetailScreen> createState() =>
      _DayEndReportDetailScreenState();
}

class _DayEndReportDetailScreenState extends State<DayEndReportDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static final _dateFormat = DateFormat('dd MMM yyyy');

  // Placeholder stock rows — replace with API data later.
  static const _stockItems = <_StockBalanceItem>[
    _StockBalanceItem(
      name: 'Grit 10MM',
      opening: 0,
      received: 0,
      issue: 0,
      closing: 0,
    ),
    _StockBalanceItem(
      name: 'sariya',
      opening: 0,
      received: 0,
      issue: 0,
      closing: 0,
    ),
    _StockBalanceItem(
      name: 'blacksendreti',
      opening: 0,
      received: 0,
      issue: 0,
      closing: 0,
    ),
  ];

  double _hPad(double width) {
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 28;
  }

  int _stockColumns(double width) {
    if (width >= 1100) return 3;
    if (width >= 680) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = _hPad(size.width);
    final isCompact = size.width < 420;
    final stockCols = _stockColumns(size.width);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.dayEndReport,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Day End Report',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      isCompact ? 14 : 18,
                      hPad,
                      32,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildReportHeader(isCompact: isCompact),
                            SizedBox(height: isCompact ? 14 : 18),
                            _buildMaterialReceiptsCard(isCompact: isCompact),
                            SizedBox(height: isCompact ? 14 : 18),
                            _buildStockSectionTitle(isCompact: isCompact),
                            const SizedBox(height: 12),
                            _buildStockGrid(
                              columns: stockCols,
                              isCompact: isCompact,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 40 : 44,
            height: isCompact ? 40 : 44,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primaryRed,
              size: isCompact ? 20 : 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATERIAL',
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Day-end stock & challan summary',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: isCompact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 12,
                vertical: isCompact ? 7 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryRed.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _dateFormat.format(widget.selectedDate),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryRed,
                        fontSize: isCompact ? 11.5 : 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialReceiptsCard({required bool isCompact}) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Material Receipts',
            style: GoogleFonts.poppins(
              color: AppColors.headingBlack,
              fontSize: isCompact ? 14 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'S. No. · Supplier · Challan No · Material · Qty · Unit · Remark',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: isCompact ? 14 : 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? 28 : 34,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.operationsCardBg.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderGray.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No matching records found',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No challan entries for this date yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSectionTitle({required bool isCompact}) {
    return Row(
      children: [
        Text(
          'Stock Balances',
          style: GoogleFonts.poppins(
            color: AppColors.headingBlack,
            fontSize: isCompact ? 14.5 : 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.iconBgGray,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_stockItems.length}',
            style: GoogleFonts.poppins(
              color: AppColors.textDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockGrid({
    required int columns,
    required bool isCompact,
  }) {
    if (columns == 1) {
      return Column(
        children: [
          for (var i = 0; i < _stockItems.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _StockBalanceCard(item: _stockItems[i], isCompact: isCompact),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 12.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in _stockItems)
              SizedBox(
                width: itemWidth,
                child: _StockBalanceCard(item: item, isCompact: isCompact),
              ),
          ],
        );
      },
    );
  }
}

class _StockBalanceCard extends StatelessWidget {
  const _StockBalanceCard({
    required this.item,
    required this.isCompact,
  });

  final _StockBalanceItem item;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: isCompact ? 14.5 : 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 14),
          // Mobile-friendly metric tiles (avoids cramped wide tables)
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Opening Balances',
                  value: _fmt(item.opening),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Received',
                  value: _fmt(item.received),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Issue',
                  value: _fmt(item.issue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Closing Balances',
                  value: _fmt(item.closing),
                  emphasize: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: emphasize
            ? AppColors.primaryRed.withValues(alpha: 0.06)
            : AppColors.operationsCardBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasize
              ? AppColors.primaryRed.withValues(alpha: 0.18)
              : AppColors.borderGray.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: emphasize ? AppColors.primaryRed : AppColors.headingBlack,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: child,
      ),
    );
  }
}

class _StockBalanceItem {
  const _StockBalanceItem({
    required this.name,
    required this.opening,
    required this.received,
    required this.issue,
    required this.closing,
  });

  final String name;
  final num opening;
  final num received;
  final num issue;
  final num closing;
}
