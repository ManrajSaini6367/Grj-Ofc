import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/InwardOutward/outward_request_store.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

/// Incoming outward requests — Approve / Hindrance.
class ReceiveOutwardRequestScreen extends StatefulWidget {
  const ReceiveOutwardRequestScreen({super.key});

  @override
  State<ReceiveOutwardRequestScreen> createState() =>
      _ReceiveOutwardRequestScreenState();
}

enum _ReceiveFilter { all, pending, approved, rejected }

class _ReceiveOutwardRequestScreenState
    extends State<ReceiveOutwardRequestScreen> {
  List<OutwardRequest> _requests = [];
  bool _loading = true;
  String? _actionId;
  _ReceiveFilter _filter = _ReceiveFilter.all;

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

  String? get _apiStatus => switch (_filter) {
        _ReceiveFilter.all => 'all',
        _ReceiveFilter.pending => 'pending',
        _ReceiveFilter.approved => 'accepted',
        _ReceiveFilter.rejected => 'hindrance',
      };

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await OutwardRequestStore.loadIncoming(
      context,
      status: _apiStatus,
    );
    if (!mounted) return;
    setState(() {
      _requests = items;
      _loading = false;
    });
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
    if (success) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request approved.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reject(OutwardRequest request) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Hindrance Request',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mark outward request for "${request.itemName}" as Hindrance?',
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
              'Hindrance',
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
    if (success) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request marked as Hindrance.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final items = _requests;
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Receive Request',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', _ReceiveFilter.all, compact),
                    const SizedBox(width: 8),
                    _filterChip('Pending', _ReceiveFilter.pending, compact),
                    const SizedBox(width: 8),
                    _filterChip('Approved', _ReceiveFilter.approved, compact),
                    const SizedBox(width: 8),
                    _filterChip('Hindrance', _ReceiveFilter.rejected, compact),
                  ],
                ),
              ),
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
                          child: Text(
                            'No receive requests found.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primaryRed,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final request = items[index];
                              return _ReceiveRequestCard(
                                request: request,
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

  Widget _filterChip(String label, _ReceiveFilter value, bool compact) {
    final selected = _filter == value;
    return Material(
      color: selected
          ? AppColors.primaryRed.withValues(alpha: 0.12)
          : AppColors.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          setState(() => _filter = value);
          _load();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primaryRed
                  : AppColors.borderGray.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primaryRed : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiveRequestCard extends StatelessWidget {
  const _ReceiveRequestCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final OutwardRequest request;
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
    final isPending = request.status == OutwardRequestStatus.pending;
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
              'Hindrance reason: ${request.rejectionReason}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
          if (isPending) ...[
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
                        'Hindrance',
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
