import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/models/attendance_model.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class ContractorAttendanceScreen extends StatefulWidget {
  const ContractorAttendanceScreen({super.key});

  @override
  State<ContractorAttendanceScreen> createState() => _ContractorAttendanceScreenState();
}

class _ContractorAttendanceScreenState extends State<ContractorAttendanceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  DateTime _selectedDate = DateTime.now();
  late List<_ContractorAttendance> _items;

  @override
  void initState() {
    super.initState();
    _items = List<_ContractorAttendance>.from(_kMockContractorAttendance);
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  int get _presentCount => _items.where((a) => a.status == AttendanceStatus.present).length;
  int get _absentCount => _items.where((a) => a.status == AttendanceStatus.absent).length;
  int get _leaveCount => _items.where((a) => a.status == AttendanceStatus.leave).length;

  List<_ContractorAttendance> get _filtered {
    var list = _items;
    if (_selectedFilter == 'Present') {
      list = list.where((a) => a.status == AttendanceStatus.present).toList();
    } else if (_selectedFilter == 'Absent') {
      list = list.where((a) => a.status == AttendanceStatus.absent).toList();
    } else if (_selectedFilter == 'Leave') {
      list = list.where((a) => a.status == AttendanceStatus.leave).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((a) =>
              a.contractorName.toLowerCase().contains(q) ||
              a.trade.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              onSurface: AppColors.headingBlack,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final rows = _filtered;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.contractorAttendances,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Contractor Attendances',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search contractors...',
                  hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.cardWhite,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
              child: Row(
                children: [
                  Text(
                    'Date:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.headingBlack,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primaryRed),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: hPad),
                children: ['All', 'Present', 'Absent', 'Leave'].map((label) {
                  final selected = _selectedFilter == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedFilter = label),
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
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
              child: Row(
                children: [
                  _statChip('Present', _presentCount, const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  _statChip('Absent', _absentCount, AppColors.primaryRed),
                  const SizedBox(width: 8),
                  _statChip('Leave', _leaveCount, const Color(0xFFD97706)),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text(
                        'No contractor attendance found',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _card(rows[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: color),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_ContractorAttendance item) {
    final color = switch (item.status) {
      AttendanceStatus.present => const Color(0xFF059669),
      AttendanceStatus.absent => AppColors.primaryRed,
      AttendanceStatus.leave => const Color(0xFFD97706),
    };
    final label = switch (item.status) {
      AttendanceStatus.present => 'Present',
      AttendanceStatus.absent => 'Absent',
      AttendanceStatus.leave => 'Leave',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
            child: Text(
              item.contractorName.isNotEmpty ? item.contractorName[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primaryRed),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.contractorName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingBlack,
                  ),
                ),
                Text(
                  item.trade,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (item.workersCount > 0)
                  Text(
                    '${item.workersCount} workers on site',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractorAttendance {
  const _ContractorAttendance({
    required this.contractorName,
    required this.trade,
    required this.status,
    this.workersCount = 0,
  });

  final String contractorName;
  final String trade;
  final AttendanceStatus status;
  final int workersCount;
}

const _kMockContractorAttendance = [
  _ContractorAttendance(
    contractorName: 'Rajesh Labour Contractors',
    trade: 'Masonry',
    status: AttendanceStatus.present,
    workersCount: 12,
  ),
  _ContractorAttendance(
    contractorName: 'Sharma Electricals',
    trade: 'Electrical',
    status: AttendanceStatus.present,
    workersCount: 6,
  ),
  _ContractorAttendance(
    contractorName: 'Metro Steel Works',
    trade: 'Steel Fixing',
    status: AttendanceStatus.absent,
  ),
  _ContractorAttendance(
    contractorName: 'Aqua Plumbing Co.',
    trade: 'Plumbing',
    status: AttendanceStatus.leave,
    workersCount: 4,
  ),
];
