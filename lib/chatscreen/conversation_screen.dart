import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/chat_camera_screen.dart';
import 'package:grjoffice_apps/chatscreen/group_info_screen.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/chatscreen/services/chat_service.dart';
import 'package:grjoffice_apps/chatscreen/theme/chat_theme.dart';
import 'package:grjoffice_apps/chatscreen/utils/chat_formatters.dart';
import 'package:grjoffice_apps/chatscreen/widgets/chat_avatar.dart';
import 'package:grjoffice_apps/chatscreen/widgets/message_bubble.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/widgets/app_back_button.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.threadId});

  final String threadId;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _service = ChatService.instance;
  bool _hasText = false;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.addListener(_onChatUpdated);
    _messageController.addListener(() {
      final next = _messageController.text.trim().isNotEmpty;
      if (next != _hasText) setState(() => _hasText = next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await _service.loadThreadDetails(widget.threadId);
    if (!mounted) return;
    await _service.loadMessages(widget.threadId);
    if (!mounted) return;
    await _service.markThreadRead(widget.threadId);
    if (!mounted) return;
    _initialLoadDone = true;
    _service.startMessagePolling(widget.threadId);
    _scrollToBottom(force: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.stopMessagePolling();
    _service.removeListener(_onChatUpdated);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _service.startMessagePolling(widget.threadId);
      _service.syncMessages(widget.threadId);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _service.stopMessagePolling();
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.maxScrollExtent - pos.pixels < 140;
  }

  void _onChatUpdated() {
    if (!mounted) return;
    final shouldScroll = _isNearBottom;
    setState(() {});
    if (shouldScroll) _scrollToBottom();
  }

  void _scrollToBottom({bool force = false}) {
    if (!_scrollController.hasClients && !force) return;
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  ChatThread? get _thread => _service.threadById(widget.threadId);

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    _messageController.clear();
    await _service.sendMessage(widget.threadId, text);
    _scrollToBottom(force: true);
  }

  Future<void> _openCamera() async {
    _focusNode.unfocus();
    final result = await Navigator.of(context).push<ChatCameraResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ChatCameraScreen(),
      ),
    );
    if (result == null || !mounted) return;

    final ok = await _service.sendMediaMessage(
      widget.threadId,
      mediaPath: result.file.path,
      isVideo: result.isVideo,
      duration: result.duration,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _service.error ??
                'Media server pe save nahi hui. Backend upload check karein.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _scrollToBottom(force: true);
  }

  void _openGroupInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupInfoScreen(threadId: widget.threadId),
      ),
    );
  }

  bool _isFirstInGroup(List<ChatMessage> messages, int index) {
    if (index == 0) return true;
    final prev = messages[index - 1];
    final curr = messages[index];
    if (prev.senderId != curr.senderId) return true;
    return curr.sentAt.difference(prev.sentAt).inMinutes > 5;
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    final media = MediaQuery.of(context);
    final topPad = media.padding.top;
    final bottomPad = media.padding.bottom;
    final width = media.size.width;
    final sideInset = ChatTheme.contentSideInset(width);

    if (thread == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: ChatTheme.wallpaper,
          appBar: AppBar(
            backgroundColor: ChatTheme.header,
            foregroundColor: AppColors.headingBlack,
            elevation: 0,
            title: Text(
              'Chat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          body: const Center(child: Text('Conversation not found')),
        ),
      );
    }

    final peer = thread.isGroup
        ? null
        : _service.userById(
            thread.participantIds.firstWhere(
              (id) => id != _service.currentUserId,
              orElse: () => _service.currentUserId,
            ),
          );

    final String? subtitle = thread.isGroup
        ? '${thread.participantIds.length} members'
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: ChatTheme.composerBar,
      ),
      child: Scaffold(
        backgroundColor: ChatTheme.wallpaper,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            _ChatHeader(
              topPadding: topPad,
              thread: thread,
              peer: peer,
              subtitle: subtitle,
              onBack: () => Navigator.of(context).maybePop(),
              onTapTitle: thread.isGroup ? _openGroupInfo : null,
              onInfo: thread.isGroup ? _openGroupInfo : null,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sideInset),
                child: ColoredBox(
                  color: ChatTheme.wallpaper,
                  child: _service.isLoadingMessages &&
                          thread.messages.isEmpty &&
                          !_initialLoadDone
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryRed,
                          ),
                        )
                      : thread.messages.isEmpty
                          ? _EmptyChatState(isGroup: thread.isGroup)
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                width < 360 ? 4 : 8,
                                12,
                                width < 360 ? 4 : 8,
                                12,
                              ),
                              itemCount: thread.messages.length,
                              itemBuilder: (context, index) {
                                final message = thread.messages[index];
                                final showDate = index == 0 ||
                                    !ChatFormatters.isSameDay(
                                      thread.messages[index - 1].sentAt,
                                      message.sentAt,
                                    );
                                final isMine =
                                    message.isMine(_service.currentUserId);
                                final sender =
                                    _service.userById(message.senderId);
                                final isSystem = message.text
                                        .startsWith('You created') ||
                                    message.text.startsWith('You added') ||
                                    message.text.startsWith('You removed');
                                final firstInGroup = _isFirstInGroup(
                                  thread.messages,
                                  index,
                                );

                                return Column(
                                  children: [
                                    if (showDate)
                                      _DateChip(
                                        label: ChatFormatters.dayLabel(
                                          message.sentAt,
                                        ),
                                      ),
                                    if (isSystem)
                                      _SystemBanner(text: message.text)
                                    else
                                      MessageBubble(
                                        message: message,
                                        isMine: isMine,
                                        showSenderName:
                                            thread.isGroup && !isMine,
                                        senderName: sender?.name,
                                        isFirstInGroup: firstInGroup,
                                      ),
                                  ],
                                );
                              },
                            ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sideInset),
              child: _MessageComposer(
                controller: _messageController,
                focusNode: _focusNode,
                hasText: _hasText,
                bottomInset: bottomPad,
                onSend: _send,
                onCamera: _openCamera,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.topPadding,
    required this.thread,
    required this.peer,
    required this.subtitle,
    required this.onBack,
    this.onTapTitle,
    this.onInfo,
  });

  final double topPadding;
  final ChatThread thread;
  final ChatUser? peer;
  final String? subtitle;
  final VoidCallback onBack;
  final VoidCallback? onTapTitle;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headerH = ChatTheme.headerHeight(width);
    final avatarR = width < 360 ? 18.0 : 20.0;

    return Material(
      color: ChatTheme.header,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: ChatTheme.header,
          border: Border(
            bottom: BorderSide(color: ChatTheme.divider, width: 1),
          ),
        ),
        padding: EdgeInsets.only(top: topPadding),
        child: SizedBox(
          height: headerH,
          child: Row(
            children: [
              const SizedBox(width: 4),
              AppBackButton(
                onPressed: onBack,
                color: AppColors.headingBlack,
                size: 40,
                iconSize: 18,
              ),
              Expanded(
                child: InkWell(
                  onTap: onTapTitle,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ChatAvatar(
                          user: peer,
                          isGroup: thread.isGroup,
                          groupLabel: thread.title,
                          groupColor:
                              thread.isGroup ? thread.groupColor : null,
                          radius: avatarR,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thread.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: width < 360 ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.headingBlack,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: ChatTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onInfo != null)
                IconButton(
                  tooltip: 'Group info',
                  onPressed: onInfo,
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: ChatTheme.iconMuted,
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.bottomInset,
    required this.onSend,
    required this.onCamera,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final double bottomInset;
  final VoidCallback onSend;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final minH = ChatTheme.composerMinHeight(width);
    final sendSize = width < 360 ? 46.0 : 50.0;

    return Container(
      decoration: const BoxDecoration(
        color: ChatTheme.composerBar,
        border: Border(
          top: BorderSide(color: ChatTheme.divider, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        width < 360 ? 10 : 14,
        10,
        width < 360 ? 10 : 14,
        10 + bottomInset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(minHeight: minH),
              decoration: BoxDecoration(
                color: ChatTheme.inputFill,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        color: ChatTheme.textPrimary,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.inputHint,
                          fontSize: 14.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                      ),
                      onSubmitted: (_) {
                        if (hasText) onSend();
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, right: 4),
                    child: IconButton(
                      tooltip: 'Camera',
                      onPressed: onCamera,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: ChatTheme.iconMuted,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: hasText ? 1 : 0.4,
            child: Material(
              color: AppColors.primaryRed,
              shape: const CircleBorder(),
              elevation: hasText ? 2 : 0,
              shadowColor: AppColors.primaryRed.withValues(alpha: 0.35),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: hasText ? onSend : null,
                child: SizedBox(
                  width: sendSize,
                  height: sendSize,
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: ChatTheme.dateChip,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: ChatTheme.dateText,
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemBanner extends StatelessWidget {
  const _SystemBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 28),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: ChatTheme.systemChip,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: ChatTheme.dateText,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.isGroup});

  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primaryRed,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isGroup ? 'Start the conversation' : 'Say hello',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.headingBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isGroup
                  ? 'Send the first message to this group.'
                  : 'Send a message to begin chatting.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.45,
                color: ChatTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
