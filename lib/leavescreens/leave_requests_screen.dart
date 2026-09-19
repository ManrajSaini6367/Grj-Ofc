import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/leavescreens/view_leave_screen.dart';
import 'package:grjoffice_apps/models/leaverequestHR.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

/// HR panel: lists employee leave requests from API.
class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();

  List<HrLeaveRequestItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _actionLeaveId;
  String? _actionType;
  int _page = 1;
  int _lastPage = 1;
  static const int _perPage = 20;

  bool get _hasMore => _page < _lastPage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading || _loadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 140) {
      _load(reset: false);
    }
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      if (_loading && _items.isNotEmpty) return;
      setState(() {
        _loading = true;
        _page = 1;
        _lastPage = 1;
      });
    } else {
      if (!_hasMore || _loadingMore || _loading) return;
      setState(() => _loadingMore = true);
    }

    final pageToLoad = reset ? 1 : _page + 1;
    final result = await getLeaveRequestHRListApi(
      context,
      page: pageToLoad,
      perPage: _perPage,
      status: 'all',
    );
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      return;
    }

    final items = result.data?.items ?? const <HrLeaveRequestItem>[];
    final pagination = result.data?.pagination;
    final currentPage = pagination?.currentPage ?? pageToLoad;
    final lastPage =
        pagination?.lastPage ??
        (items.length < _perPage ? pageToLoad : pageToLoad + 1);

    setState(() {
      if (reset) {
        _items = List<HrLeaveRequestItem>.from(items);
      } else {
        final existingIds = _items.map((e) => e.id).toSet();
        _items.addAll(
          items.where((e) => e.id == null || !existingIds.contains(e.id)),
        );
      }
      _page = currentPage;
      _lastPage = lastPage;
      _loading = false;
      _loadingMore = false;
    });
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

  Future<void> _openLeave(HrLeaveRequestItem item) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ViewLeaveScreen(leaveId: id)));
    if (!mounted) return;
    await _load(reset: true);
  }

  void _setStatusLocal(String id, String status) {
    setState(() {
      _items = _items.map((item) {
        if (item.id != id) return item;
        return HrLeaveRequestItem(
          id: item.id,
          userId: item.userId,
          siteId: item.siteId,
          fromDate: item.fromDate,
          toDate: item.toDate,
          durationDays: item.durationDays,
          type: item.type,
          typeLabel: item.typeLabel,
          description: item.description,
          status: status,
          employeeName: item.employeeName,
          reviewedBy: item.reviewedBy,
          reviewedByName: item.reviewedByName,
          reviewedAt: item.reviewedAt,
          reviewNote: item.reviewNote,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
        );
      }).toList();
    });
  }

  Future<void> _approveLeave(HrLeaveRequestItem item) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty || _actionLeaveId != null) return;

    setState(() {
      _actionLeaveId = id;
      _actionType = 'approve';
    });

    final ok = await approveLeaveApi(context, leaveId: id);
    if (!mounted) return;

    if (ok) {
      _setStatusLocal(id, 'approved');
    }

    setState(() {
      _actionLeaveId = null;
      _actionType = null;
    });
  }

  Future<void> _rejectLeave(HrLeaveRequestItem item) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty || _actionLeaveId != null) return;

    setState(() {
      _actionLeaveId = id;
      _actionType = 'reject';
    });

    final ok = await rejectLeaveApi(context, leaveId: id);
    if (!mounted) return;

    if (ok) {
      _setStatusLocal(id, 'rejected');
    }

    setState(() {
      _actionLeaveId = null;
      _actionType = null;
    });
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showFooter = _loadingMore || _hasMore;

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
              child: _loading && _items.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : _items.isEmpty
                  ? _EmptyState(hPad: hPad, onRetry: () => _load(reset: true))
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () => _load(reset: true),
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          14,
                          hPad,
                          18 + bottomInset,
                        ),
                        itemCount: _items.length + (showFooter ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index >= _items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: _loadingMore
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: AppColors.primaryRed,
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: () => _load(reset: false),
                                        child: Text(
                                          'Load more',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryRed,
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          }

                          final item = _items[index];
                          return Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: contentMax),
                              child: _HrLeaveCard(
                                item: item,
                                onTap: () => _openLeave(item),
                                approving:
                                    _actionLeaveId == item.id &&
                                    _actionType == 'approve',
                                rejecting:
                                    _actionLeaveId == item.id &&
                                    _actionType == 'reject',
                                onApprove: () => _approveLeave(item),
                                onReject: () => _rejectLeave(item),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hPad, required this.onRetry});

  final double hPad;
  final VoidCallback onRetry;

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
              const SizedBox(height: 14),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Refresh',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                  ),
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
    required this.item,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    this.approving = false,
    this.rejecting = false,
  });

  final HrLeaveRequestItem item;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool approving;
  final bool rejecting;

  static const _approved = Color(0xFF059669);
  static const _rejected = Color(0xFFDC2626);
  static const _pending = Color(0xFFD97706);

  String get _statusKey => (item.status ?? 'pending').trim().toLowerCase();

  String get _statusLabel {
    final key = _statusKey;
    if (key.isEmpty) return 'Pending';
    return key[0].toUpperCase() + key.substring(1);
  }

  Color get _statusColor {
    switch (_statusKey) {
      case 'approved':
        return _approved;
      case 'rejected':
        return _rejected;
      default:
        return _pending;
    }
  }

  Color get _statusBg {
    switch (_statusKey) {
      case 'approved':
        return const Color(0xFFECFDF5);
      case 'rejected':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFFFF7ED);
    }
  }

  String get _initials {
    final parts = (item.employeeName ?? 'E')
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
    final pad = width < 360 ? 14.0 : 16.0;
    final days = item.durationDays ?? 0;
    final typeLabel = (item.typeLabel ?? item.type ?? 'Leave').trim();
    final name = (item.employeeName ?? 'Employee').trim();
    final description = (item.description ?? '').trim();
    final fromText =
        item.fromDate == null ? '—' : dateFmt.format(item.fromDate!);
    final toText = item.toDate == null ? '—' : dateFmt.format(item.toDate!);
    final appliedText = item.createdAt == null
        ? '—'
        : appliedFmt.format(item.createdAt!);
    final isPending = _statusKey == 'pending' || _statusKey.isEmpty;

    return Material(
      color: AppColors.cardWhite,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderGray.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _initials,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.headingBlack,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            typeLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.operationsCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final narrow = c.maxWidth < 340;
                      final from = _MetaCell(
                        icon: Icons.calendar_today_rounded,
                        label: 'From',
                        value: fromText,
                      );
                      final to = _MetaCell(
                        icon: Icons.event_rounded,
                        label: 'To',
                        value: toText,
                      );
                      final daysCell = _MetaCell(
                        icon: Icons.timelapse_rounded,
                        label: 'Duration',
                        value: days == 1 ? '1 Day' : '$days Days',
                      );

                      if (narrow) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: from),
                                const SizedBox(width: 8),
                                Expanded(child: to),
                              ],
                            ),
                            const SizedBox(height: 10),
                            daysCell,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: from),
                          Container(
                            width: 1,
                            height: 32,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: AppColors.borderGray.withValues(alpha: 0.55),
                          ),
                          Expanded(child: to),
                          Container(
                            width: 1,
                            height: 32,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: AppColors.borderGray.withValues(alpha: 0.55),
                          ),
                          Expanded(child: daysCell),
                        ],
                      );
                    },
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Applied $appliedText',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      'View',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primaryRed,
                    ),
                  ],
                ),
                if (isPending) ...[
                  const SizedBox(height: 14),
                  _ActionButtons(
                    approving: approving,
                    rejecting: rejecting,
                    onApprove: onApprove,
                    onReject: onReject,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onApprove,
    required this.onReject,
    this.approving = false,
    this.rejecting = false,
  });

  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool approving;
  final bool rejecting;

  static const _approved = Color(0xFF059669);
  static const _rejected = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final busy = approving || rejecting;

    Widget loadingDot(Color color) => SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
    );

    final approveBtn = SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: busy ? null : onApprove,
        style: ElevatedButton.styleFrom(
          backgroundColor: _approved,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _approved.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: approving
            ? loadingDot(Colors.white)
            : Text(
                'Approve',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );

    final rejectBtn = SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: busy ? null : onReject,
        style: OutlinedButton.styleFrom(
          foregroundColor: _rejected,
          side: BorderSide(color: _rejected.withValues(alpha: 0.7)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: rejecting
            ? loadingDot(_rejected)
            : Text(
                'Reject',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 320) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: approveBtn),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: rejectBtn),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: approveBtn),
            const SizedBox(width: 10),
            Expanded(child: rejectBtn),
          ],
        );
      },
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
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppColors.textDark),
        ),
        const SizedBox(width: 8),
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
