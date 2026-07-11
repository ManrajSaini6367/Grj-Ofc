import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/task_message_model.dart';
import 'package:grjoffice_apps/models/task_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_back_button.dart';

class TaskMessagesScreen extends StatefulWidget {
  const TaskMessagesScreen({super.key, required this.task});

  final Task task;

  @override
  State<TaskMessagesScreen> createState() => _TaskMessagesScreenState();
}

class _TaskMessagesScreenState extends State<TaskMessagesScreen> {
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  bool _hasText = false;
  List<TaskMessage> _messages = [];
  TaskMessageTaskInfo? _taskInfo;
  int _unreadCount = 0;

  int? get _taskId => int.tryParse(widget.task.id);

  String get _title {
    final fromApi = _taskInfo?.title.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return widget.task.title;
  }

  String get _subtitle {
    final assignee = _taskInfo?.assigneeName?.trim();
    if (assignee != null && assignee.isNotEmpty) return assignee;
    if (widget.task.assigneeName.trim().isNotEmpty) return widget.task.assigneeName;
    return 'Task conversation';
  }

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadMessages(showLoader: true);
    final taskId = _taskId;
    if (taskId != null && mounted) {
      await markAllTaskMessagesReadApi(context, taskId, showErrors: false);
      if (mounted) setState(() => _unreadCount = 0);
    }
  }

  Future<void> _loadMessages({bool showLoader = false}) async {
    final taskId = _taskId;
    if (taskId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    if (showLoader) setState(() => _isLoading = true);

    final response = await getTaskMessagesApi(context, taskId);
    if (!mounted) return;

    final items = List<TaskMessage>.from(response?.data?.items ?? [])
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

    setState(() {
      _taskInfo = response?.data?.task;
      _messages = items;
      _unreadCount = response?.data?.unreadCount ?? 0;
      _isLoading = false;
    });
    _scrollToBottom(animate: false);
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (!animate) {
        _scrollController.jumpTo(target);
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendMessage() async {
    final taskId = _taskId;
    final text = _messageController.text.trim();
    if (taskId == null || text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final sent = await sendTaskMessageApi(
      context,
      taskId,
      messageText: text,
      receiverId: null,
    );
    if (!mounted) return;

    setState(() => _isSending = false);
    if (sent == null) return;

    _messageController.clear();
    setState(() => _messages = [..._messages, sent]);
    _scrollToBottom();
  }

  Future<void> _deleteMessage(TaskMessage msg) async {
    final taskId = _taskId;
    if (taskId == null) return;

    HapticFeedback.mediumImpact();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(18),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGray.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.primaryRed),
                  title: Text(
                    'Delete message',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, true),
                ),
                ListTile(
                  leading: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  title: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  onTap: () => Navigator.pop(context, false),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final ok = await deleteTaskMessageApi(context, taskId, msg.id);
    if (!mounted || !ok) return;
    setState(() => _messages = _messages.where((m) => m.id != msg.id).toList());
  }

  Future<void> _markMessageRead(TaskMessage msg) async {
    final taskId = _taskId;
    if (taskId == null || msg.isMine || !msg.isUnread) return;

    final ok = await markTaskMessageReadApi(
      context,
      taskId,
      msg.id,
      showErrors: false,
    );
    if (!mounted || !ok) return;

    setState(() {
      _messages = _messages
          .map(
            (m) => m.id == msg.id
                ? TaskMessage(
                    id: m.id,
                    taskId: m.taskId,
                    message: m.message,
                    status: 'read',
                    isMine: m.isMine,
                    sender: m.sender,
                    receiver: m.receiver,
                    createdAt: m.createdAt,
                    updatedAt: m.updatedAt,
                  )
                : m,
          )
          .toList();
      if (_unreadCount > 0) _unreadCount--;
    });
  }

  void _goBack() {
    Navigator.pop(context, _unreadCount);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateLabel(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF3F0EC),
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBackButton(onPressed: _goBack),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryRed.withValues(alpha: 0.12),
              child: Text(
                _initials(_title),
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
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headingBlack,
                    ),
                  ),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : () => _loadMessages(showLoader: false),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryRed),
                  )
                : RefreshIndicator(
                    color: AppColors.primaryRed,
                    onRefresh: () => _loadMessages(showLoader: false),
                    child: _messages.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
                              _buildEmptyState(),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final prev = index > 0 ? _messages[index - 1] : null;
                              final next =
                                  index < _messages.length - 1 ? _messages[index + 1] : null;

                              final showDate = prev == null ||
                                  _formatDateLabel(prev.createdAt) !=
                                      _formatDateLabel(msg.createdAt);

                              final sameSenderAsPrev = prev != null &&
                                  prev.isMine == msg.isMine &&
                                  (prev.sender?.id == msg.sender?.id) &&
                                  !showDate;

                              final sameSenderAsNext = next != null &&
                                  next.isMine == msg.isMine &&
                                  (next.sender?.id == msg.sender?.id) &&
                                  _formatDateLabel(next.createdAt) ==
                                      _formatDateLabel(msg.createdAt);

                              return Column(
                                children: [
                                  if (showDate) _dateChip(_formatDateLabel(msg.createdAt)),
                                  _buildBubble(
                                    msg,
                                    tightTop: sameSenderAsPrev,
                                    tightBottom: sameSenderAsNext,
                                    showSender: !msg.isMine && !sameSenderAsPrev,
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
          ),
          _buildComposer(bottomInset),
        ],
      ),
    ),
    );
  }

  Widget _dateChip(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(
    TaskMessage msg, {
    required bool tightTop,
    required bool tightBottom,
    required bool showSender,
  }) {
    final isMine = msg.isMine;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final topRadius = tightTop ? 6.0 : 18.0;
    final bottomRadius = tightBottom ? 6.0 : 18.0;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          top: tightTop ? 2 : 8,
          bottom: tightBottom ? 2 : 8,
          left: isMine ? 48 : 0,
          right: isMine ? 0 : 48,
        ),
        child: Row(
          mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              if (!tightBottom)
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFE8EEF5),
                  child: Text(
                    _initials(msg.sender?.name ?? '?'),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                )
              else
                const SizedBox(width: 24),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: isMine ? () => _deleteMessage(msg) : null,
                onTap: () => _markMessageRead(msg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (showSender && (msg.sender?.name.trim().isNotEmpty ?? false))
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              msg.sender!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
                          decoration: BoxDecoration(
                            color: isMine ? AppColors.primaryRed : AppColors.cardWhite,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isMine ? 18 : topRadius),
                              topRight: Radius.circular(isMine ? topRadius : 18),
                              bottomLeft: Radius.circular(isMine ? 18 : bottomRadius),
                              bottomRight: Radius.circular(isMine ? bottomRadius : 18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: 1,
                                child: Text(
                                  msg.message,
                                  softWrap: true,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    height: 1.35,
                                    color: isMine ? Colors.white : AppColors.headingBlack,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMine && msg.isUnread) ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(right: 5),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryRed,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                  Text(
                                    _formatTime(msg.createdAt),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: isMine
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (isMine) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.done_all_rounded,
                                      size: 13,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.operationsCardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: GoogleFonts.poppins(fontSize: 14.5, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Write a message…',
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.inputHint,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (_hasText || _isSending)
                  ? AppColors.primaryRed
                  : AppColors.primaryRed.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: (_hasText && !_isSending) ? _sendMessage : null,
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 38,
              color: AppColors.primaryRed.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Start the conversation',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Messages about this task will show up here.\nAsk updates, share notes, or follow up.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
