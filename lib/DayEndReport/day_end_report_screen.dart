import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

/// Premium Day End Report workspace — independent of Activity feed.
class DayEndReportScreen extends StatefulWidget {
  const DayEndReportScreen({super.key});

  @override
  State<DayEndReportScreen> createState() => _DayEndReportScreenState();
}

class _DayEndReportScreenState extends State<DayEndReportScreen>
    with SingleTickerProviderStateMixin {
  static const _ink = Color(0xFF0B1220);
  static const _inkSoft = Color(0xFF1A2332);
  static const _gold = Color(0xFFC4A35A);
  static const _mint = Color(0xFF2DD4BF);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _notesController = TextEditingController();
  late final AnimationController _pulse;

  DateTime _reportDate = DateTime.now();
  bool _isLoading = true;
  bool _isSubmitting = false;

  int _activityCount = 0;
  int _purchaseCount = 0;
  int _attendanceCount = 0;
  int _expenseCount = 0;

  late List<_CloseItem> _items;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _items = [
      const _CloseItem(
        title: 'Team attendance',
        hint: 'All punch records verified',
        icon: Icons.fingerprint_rounded,
      ),
      const _CloseItem(
        title: 'Purchases & challans',
        hint: 'Vehicles and slips closed',
        icon: Icons.local_shipping_rounded,
      ),
      const _CloseItem(
        title: 'Store balance',
        hint: 'In / out entries reconciled',
        icon: Icons.inventory_2_rounded,
      ),
      const _CloseItem(
        title: 'Site expenses',
        hint: 'Spend logged for today',
        icon: Icons.payments_rounded,
      ),
      const _CloseItem(
        title: 'Handover notes',
        hint: 'Tomorrow’s team brief ready',
        icon: Icons.sticky_note_2_rounded,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  bool get _isToday {
    final n = DateTime.now();
    return _reportDate.year == n.year &&
        _reportDate.month == n.month &&
        _reportDate.day == n.day;
  }

  int get _doneCount => _items.where((e) => e.done).length;

  double get _progress => _items.isEmpty ? 0 : _doneCount / _items.length;

  bool get _ready => _doneCount == _items.length && !_isSubmitting;

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final response = await getActivitiesApi(
      context,
      type: 'all',
      period: _isToday ? 'today' : 'all',
      perPage: 50,
    );
    if (!mounted) return;
    final byType = response?.data?.summary?.byType ?? {};
    setState(() {
      _activityCount =
          response?.data?.summary?.today ?? response?.data?.items.length ?? 0;
      _purchaseCount = byType['purchase'] ?? 0;
      _attendanceCount = byType['attendance'] ?? 0;
      _expenseCount = byType['expense'] ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reportDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _reportDate = picked);
    await _loadSummary();
  }

  void _toggle(int index) {
    setState(() {
      final item = _items[index];
      _items[index] = item.copyWith(done: !item.done);
    });
  }

  Future<void> _submit() async {
    if (!_ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete every close-out item first.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF065F46),
        content: Text(
          'Day closed successfully for ${DateFormat('dd MMM').format(_reportDate)}.',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final site = selectedSiteName()?.trim().isNotEmpty == true
        ? selectedSiteName()!
        : 'Current site';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F4F1),
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
              child: RefreshIndicator(
                color: AppColors.primaryRed,
                onRefresh: _loadSummary,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 28),
                  children: [
                    _buildOrbitHeader(site),
                    const SizedBox(height: 18),
                    _buildMetricRail(),
                    const SizedBox(height: 22),
                    _buildCloseSection(),
                    const SizedBox(height: 20),
                    _buildNotesCard(),
                    const SizedBox(height: 22),
                    _buildSubmitCta(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitHeader(String site) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.12 + (_pulse.value * 0.1);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_ink, _inkSoft, Color(0xFF3A1C1C)],
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: glow),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: -40,
                  top: -50,
                  child: CustomPaint(
                    size: const Size(180, 180),
                    painter: _OrbitPainter(
                      progress: _pulse.value,
                      color: _gold.withValues(alpha: 0.22),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _mint.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wb_twilight_rounded,
                                  size: 14,
                                  color: _gold.withValues(alpha: 0.95),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isToday ? 'Tonight’s close' : 'Archive close',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.event_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('dd MMM').format(_reportDate),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Close the day',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE · d MMMM yyyy').format(_reportDate),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  site,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    minHeight: 6,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.12),
                                    valueColor: AlwaysStoppedAnimation(
                                      _progress >= 1 ? _mint : _gold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _ProgressRing(
                            progress: _progress,
                            label: '${(_progress * 100).round()}%',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricRail() {
    final metrics = [
      _Metric('Pulse', _isLoading ? '—' : '$_activityCount', Icons.bolt_rounded),
      _Metric(
        'Buys',
        _isLoading ? '—' : '$_purchaseCount',
        Icons.shopping_bag_rounded,
      ),
      _Metric(
        'Crew',
        _isLoading ? '—' : '$_attendanceCount',
        Icons.groups_rounded,
      ),
      _Metric(
        'Spend',
        _isLoading ? '—' : '$_expenseCount',
        Icons.account_balance_wallet_rounded,
      ),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = metrics[i];
          return Container(
            width: 108,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8E4DE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(m.icon, size: 18, color: AppColors.primaryRed),
                const Spacer(),
                Text(
                  m.value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Close-out list',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.headingBlack,
              ),
            ),
            const Spacer(),
            Text(
              '$_doneCount/${_items.length}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_items.length, (i) {
          final item = _items[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i == _items.length - 1 ? 0 : 10),
            child: _CloseTile(
              item: item,
              index: i + 1,
              onTap: () => _toggle(i),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E4DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Night notes',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Anything the next shift should know.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Delays, safety, pending materials…',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.inputHint,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F6F3),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.primaryRed.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitCta() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _ready ? _submit : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _ink,
          disabledBackgroundColor: const Color(0xFFD6D3CE),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF8A857E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _ready ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _ready ? 'Lock Day End Report' : 'Finish checklist to lock',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CloseTile extends StatelessWidget {
  const _CloseTile({
    required this.item,
    required this.index,
    required this.onTap,
  });

  final _CloseItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: item.done ? const Color(0xFFECFDF5) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.done
                  ? const Color(0xFF6EE7B7)
                  : const Color(0xFFE8E4DE),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.done
                      ? const Color(0xFF059669)
                      : const Color(0xFFF3F0EC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: item.done ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. ${item.title}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headingBlack,
                        decoration:
                            item.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.hint,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.done
                      ? const Color(0xFF059669)
                      : Colors.transparent,
                  border: Border.all(
                    color: item.done
                        ? const Color(0xFF059669)
                        : const Color(0xFFCFCBC4),
                    width: 1.6,
                  ),
                ),
                child: item.done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4.5,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1
                    ? const Color(0xFF2DD4BF)
                    : const Color(0xFFC4A35A),
              ),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 3; i++) {
      final r = 28.0 + (i * 22) + (progress * 6);
      canvas.drawCircle(center, r, paint);
    }
    final dotPaint = Paint()..color = color.withValues(alpha: 0.9);
    final angle = progress * math.pi * 2;
    final orbit = 50.0 + progress * 8;
    canvas.drawCircle(
      center + Offset(math.cos(angle) * orbit, math.sin(angle) * orbit),
      3.5,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CloseItem {
  const _CloseItem({
    required this.title,
    required this.hint,
    required this.icon,
    this.done = false,
  });

  final String title;
  final String hint;
  final IconData icon;
  final bool done;

  _CloseItem copyWith({bool? done}) => _CloseItem(
        title: title,
        hint: hint,
        icon: icon,
        done: done ?? this.done,
      );
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}
