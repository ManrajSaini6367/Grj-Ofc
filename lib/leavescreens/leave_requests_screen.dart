import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/leavescreens/leave_models.dart';
import 'package:grjoffice_apps/leavescreens/leave_service.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

/// HR panel: lists all employee leave requests (API wiring later).
class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _service = LeaveService.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await _service.ensureLoaded();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _onUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdated);
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    if (width < 900) return 24;
    return 32;
  }

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }

  Future<void> _setStatus(String id, LeaveStatus status) async {
    // Local update for now (API integration comes later).
    await _service.updateStatus(id, status);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final width = MediaQuery.sizeOf(context).width;
    final contentMax = width >= 1100
        ? 860.0
        : width >= 900
            ? 760.0
            : double.infinity;
    final items = _service.leaves;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.leaveRequests,
        onItemTap: _onDrawerItemTap,
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Leave Requests',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : items.isEmpty
                      ? _EmptyState(hPad: hPad)
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            hPad,
                            10,
                            hPad,
                            18 + bottomInset,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return Center(
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: contentMax),
                                child: _HrLeaveCard(
                                  request: items[index],
                                  onApprove: () => _setStatus(
                                    items[index].id,
                                    LeaveStatus.approved,
                                  ),
                                  onReject: () => _setStatus(
                                    items[index].id,
                                    LeaveStatus.rejected,
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hPad});

  final double hPad;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad + 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primaryRed,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No leave requests',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Employee leave applications will appear here for review.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HrLeaveCard extends StatelessWidget {
  const _HrLeaveCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final LeaveRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color get _statusColor {
    switch (request.status) {
      case LeaveStatus.pending:
        return const Color(0xFFD97706);
      case LeaveStatus.approved:
        return const Color(0xFF059669);
      case LeaveStatus.rejected:
        return const Color(0xFFDC2626);
    }
  }

  Color get _statusBg {
    switch (request.status) {
      case LeaveStatus.pending:
        return const Color(0xFFFFF7ED);
      case LeaveStatus.approved:
        return const Color(0xFFECFDF5);
      case LeaveStatus.rejected:
        return const Color(0xFFFEF2F2);
    }
  }

  String get _initials {
    final parts = request.employeeName
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'E';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final appliedFmt = DateFormat('dd MMM yyyy, hh:mm a');
    final width = MediaQuery.sizeOf(context).width;
    final pad = width < 360 ? 10.0 : 12.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderGray.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _initials,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.employeeName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      request.type.label,
                      style: GoogleFonts.poppins(
                        fontSize: 12.2,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  request.status.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 360;
                final from = _MetaCell(
                  icon: Icons.calendar_today_rounded,
                  label: 'From',
                  value: dateFmt.format(request.fromDate),
                );
                final to = _MetaCell(
                  icon: Icons.event_rounded,
                  label: 'To',
                  value: dateFmt.format(request.toDate),
                );
                final days = _MetaCell(
                  icon: Icons.timelapse_rounded,
                  label: 'Total Days',
                  value: request.durationDays == 1
                      ? '1 Day'
                      : '${request.durationDays} Days',
                );

                if (narrow) {
                  // Keep From + To on the same row; put Days on a second line.
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: from),
                          _vDivider(),
                          Expanded(child: to),
                        ],
                      ),
                      const SizedBox(height: 6),
                      days,
                    ],
                  );
                }

                // Fully horizontal on larger screens.
                return Row(
                  children: [
                    Expanded(child: from),
                    _vDivider(),
                    Expanded(child: to),
                    _vDivider(),
                    Expanded(child: days),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Applied Date: ${appliedFmt.format(request.createdAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ActionButtons(
            status: request.status,
            onApprove: onApprove,
            onReject: onReject,
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.borderGray.withValues(alpha: 0.55),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.status,
    required this.onApprove,
    required this.onReject,
  });

  final LeaveStatus status;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  static const approvedColor = Color(0xFF059669);
  static const rejectedColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stack = width < 420;

    final approveEnabled = status != LeaveStatus.approved;
    final rejectEnabled = status != LeaveStatus.rejected;

    const radius = 12.0;
    const verticalPadding = 10.0;

    final approveBtn = SizedBox(
      width: stack ? double.infinity : null,
      child: ElevatedButton(
        onPressed: approveEnabled ? onApprove : null,
        style: ButtonStyle(
          elevation: const MaterialStatePropertyAll(0),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: verticalPadding),
          ),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            final disabled = states.contains(MaterialState.disabled);
            return disabled
                ? approvedColor.withValues(alpha: 0.07)
                : approvedColor.withValues(alpha: 0.10);
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            final disabled = states.contains(MaterialState.disabled);
            return disabled
                ? approvedColor.withValues(alpha: 0.45)
                : approvedColor;
          }),
          shape: MaterialStateProperty.resolveWith((states) {
            final disabled = states.contains(MaterialState.disabled);
            return RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(
                color: disabled
                    ? approvedColor.withValues(alpha: 0.25)
                    : approvedColor,
                width: 1.25,
              ),
            );
          }),
        ),
        child: Text(
          status == LeaveStatus.approved ? 'Approved' : 'Approve',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );

    final rejectBtn = SizedBox(
      width: stack ? double.infinity : null,
      child: ElevatedButton(
        onPressed: rejectEnabled ? onReject : null,
        style: ButtonStyle(
          elevation: const MaterialStatePropertyAll(0),
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: verticalPadding),
          ),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            final disabled = states.contains(MaterialState.disabled);
            return disabled
                ? rejectedColor.withValues(alpha: 0.07)
                : rejectedColor.withValues(alpha: 0.10);
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            final disabled = states.contains(MaterialState.disabled);
            return disabled
                ? rejectedColor.withValues(alpha: 0.45)
                : rejectedColor;
          }),
          shape: MaterialStateProperty.resolveWith((states) {
            final disabled = states.contains(MaterialState.disabled);
            return RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(
                color: disabled
                    ? rejectedColor.withValues(alpha: 0.25)
                    : rejectedColor,
                width: 1.25,
              ),
            );
          }),
        ),
        child: Text(
          status == LeaveStatus.rejected ? 'Rejected' : 'Reject',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );

    if (stack) {
      if (status == LeaveStatus.approved) {
        return Column(children: [approveBtn]);
      }
      if (status == LeaveStatus.rejected) {
        return Column(children: [rejectBtn]);
      }
      return Column(
        children: [
          approveBtn,
          const SizedBox(height: 8),
          rejectBtn,
        ],
      );
    }

    if (status == LeaveStatus.approved) {
      return Row(children: [Expanded(child: approveBtn)]);
    }
    if (status == LeaveStatus.rejected) {
      return Row(children: [Expanded(child: rejectBtn)]);
    }
    return Row(
      children: [
        Expanded(child: approveBtn),
        const SizedBox(width: 10),
        Expanded(child: rejectBtn),
      ],
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.primaryRed),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
