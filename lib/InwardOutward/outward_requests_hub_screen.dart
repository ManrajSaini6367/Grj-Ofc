import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/InwardOutward/outward_request_screen.dart';
import 'package:grjoffice_apps/InwardOutward/outward_request_store.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

enum _OutwardListTab { request, receive }

/// Single screen: Request | Receive Request lists.
class OutwardRequestsHubScreen extends StatefulWidget {
  const OutwardRequestsHubScreen({super.key});

  @override
  State<OutwardRequestsHubScreen> createState() =>
      _OutwardRequestsHubScreenState();
}

class _OutwardRequestsHubScreenState extends State<OutwardRequestsHubScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _OutwardListTab _tab = _OutwardListTab.request;
  List<OutwardRequest> _sent = [];
  List<OutwardRequest> _incoming = [];
  bool _loading = true;
  String? _actionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sent = await OutwardRequestStore.loadSent(context);
    if (!mounted) return;
    final incoming = await OutwardRequestStore.loadIncoming(context);
    if (!mounted) return;
    setState(() {
      _sent = sent;
      _incoming = incoming;
      _loading = false;
    });
  }

  List<OutwardRequest> get _currentList =>
      _tab == _OutwardListTab.request ? _sent : _incoming;

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateOutwardRequestPage()),
    );
    if (created == true && mounted) {
      setState(() => _tab = _OutwardListTab.request);
      await _load();
    }
  }

  Future<void> _approve(OutwardRequest request) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Approve Request',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Approve outward request for "${request.itemName}"?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Approve',
              style: GoogleFonts.poppins(
                color: const Color(0xFF059669),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final receiveId = request.actionId;
    if (receiveId == null) return;

    setState(() => _actionId = request.id);
    final success = await OutwardRequestStore.acceptIncoming(
      context,
      receiveRequestId: receiveId,
    );
    if (!mounted) return;
    setState(() => _actionId = null);
    if (success) await _load();
  }

  Future<void> _reject(OutwardRequest request) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Reject Request',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reject outward request for "${request.itemName}"?',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              minLines: 2,
              maxLines: 4,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.inputHint,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.operationsCardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Reject',
              style: GoogleFonts.poppins(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (ok != true || !mounted) return;

    final receiveId = request.actionId;
    if (receiveId == null) return;

    setState(() => _actionId = request.id);
    final success = await OutwardRequestStore.rejectIncoming(
      context,
      receiveRequestId: receiveId,
      reviewNote: reason.isNotEmpty ? reason : null,
    );
    if (!mounted) return;
    setState(() => _actionId = null);
    if (success) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final compact = MediaQuery.sizeOf(context).width < 360;
    final items = _currentList;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: DrawerIndex.outwardRequests,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      floatingActionButton: _tab == _OutwardListTab.request
          ? FloatingActionButton(
              onPressed: _openCreate,
              backgroundColor: AppColors.primaryRed,
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.shell(
              title: 'Outward Requests',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
              child: _buildTabs(compact: compact),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: Text(
                              _tab == _OutwardListTab.request
                                  ? 'No requests yet.\nTap + to create one.'
                                  : 'No receive requests yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primaryRed,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              hPad,
                              4,
                              hPad,
                              _tab == _OutwardListTab.request ? 88 : 24,
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final request = items[index];
                              return _RequestListCard(
                                request: request,
                                showActions:
                                    _tab == _OutwardListTab.receive &&
                                    request.status ==
                                        OutwardRequestStatus.pending,
                                busy: _actionId == request.id,
                                onApprove: () => _approve(request),
                                onReject: () => _reject(request),
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

  Widget _buildTabs({required bool compact}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label: 'Request',
              selected: _tab == _OutwardListTab.request,
              count: _sent.length,
              compact: compact,
              onTap: () => setState(() => _tab = _OutwardListTab.request),
            ),
          ),
          Expanded(
            child: _tabButton(
              label: 'Receive Request',
              selected: _tab == _OutwardListTab.receive,
              count: _incoming.length,
              compact: compact,
              onTap: () => setState(() => _tab = _OutwardListTab.receive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool selected,
    required int count,
    required bool compact,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? AppColors.primaryRed.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primaryRed
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryRed
                      : AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.white : AppColors.textSecondary,
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

class _RequestListCard extends StatelessWidget {
  const _RequestListCard({
    required this.request,
    required this.showActions,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final OutwardRequest request;
  final bool showActions;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color get _statusColor => switch (request.status) {
        OutwardRequestStatus.pending => const Color(0xFFD97706),
        OutwardRequestStatus.approved => const Color(0xFF059669),
        OutwardRequestStatus.rejected => const Color(0xFFDC2626),
      };

  @override
  Widget build(BuildContext context) {
    final qtyText = request.qty == request.qty.roundToDouble()
        ? '${request.qty.toInt()}'
        : '${request.qty}';
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(request.createdAt),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Qty: $qtyText ${request.unit}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark),
          ),
          if (request.fromSiteName.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'From: ${request.fromSiteName}',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark),
            ),
          ],
          if (request.siteName.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              request.isIncoming
                  ? 'To: ${request.siteName}'
                  : 'Site: ${request.siteName}',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark),
            ),
          ],
          if (request.remark.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Remark: ${request.remark}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark),
            ),
          ],
          if (request.status == OutwardRequestStatus.rejected &&
              request.rejectionReason.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reject reason: ${request.rejectionReason}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: compact ? 36 : 40,
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryRed,
                        side: const BorderSide(color: AppColors.primaryRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: compact ? 36 : 40,
                    child: ElevatedButton(
                      onPressed: busy ? null : onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              'Approve',
                              style: GoogleFonts.poppins(
                                fontSize: compact ? 12 : 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
