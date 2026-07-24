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

    await _service.sendMediaMessage(
      widget.threadId,
      mediaPath: result.file.path,
      isVideo: result.isVideo,
      duration: result.duration,
    );
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
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: ChatTheme.wallpaper,
          body: Column(
            children: [
              Container(
                color: ChatTheme.header,
                padding: EdgeInsets.only(top: topPad),
                child: const SizedBox(
                  height: 56,
                  child: Center(
                    child: Text(
                      'Chat',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Center(child: Text('Conversation not found')),
              ),
            ],
          ),
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
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: ChatTheme.header,
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
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: ChatTheme.wallpaper),
                    ),
                    const Positioned.fill(
                      child: CustomPaint(painter: ChatWallpaperPainter()),
                    ),
                    if (_service.isLoadingMessages &&
                        thread.messages.isEmpty &&
                        !_initialLoadDone)
                      const Center(
                        child: CircularProgressIndicator(
                          color: ChatTheme.header,
                        ),
                      )
                    else if (thread.messages.isEmpty)
                      _EmptyChatState(isGroup: thread.isGroup)
                    else
                      ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          width < 360 ? 2 : 4,
                          10,
                          width < 360 ? 2 : 4,
                          10,
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
                          final isSystem =
                              message.text.startsWith('You created') ||
                                  message.text.startsWith('You added') ||
                                  message.text.startsWith('You removed');
                          final firstInGroup =
                              _isFirstInGroup(thread.messages, index);

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
                                  showSenderName: thread.isGroup && !isMine,
                                  senderName: sender?.name,
                                  isFirstInGroup: firstInGroup,
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sideInset),
              child: _WhatsAppComposer(
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
    final avatarR = width < 360 ? 16.0 : 18.0;

    return Material(
      color: ChatTheme.header,
      elevation: 1.5,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: SizedBox(
          height: headerH,
          child: Row(
            children: [
              const SizedBox(width: 2),
              AppBackButton(
                onPressed: onBack,
                color: Colors.white,
                size: 40,
                iconSize: 18,
              ),
              Expanded(
                child: InkWell(
                  onTap: onTapTitle,
                  borderRadius: BorderRadius.circular(8),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thread.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  fontSize: width < 360 ? 15.5 : 16.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: 12.5,
                                    color:
                                        Colors.white.withValues(alpha: 0.88),
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
                    Icons.more_vert_rounded,
                    color: Colors.white,
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

class _WhatsAppComposer extends StatelessWidget {
  const _WhatsAppComposer({
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
    final sendSize = width < 360 ? 44.0 : 48.0;

    return Material(
      color: ChatTheme.composerBar,
      elevation: 6,
      shadowColor: Colors.black12,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          width < 360 ? 4 : 6,
          7,
          width < 360 ? 4 : 6,
          7 + bottomInset,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: minH),
                decoration: BoxDecoration(
                  color: ChatTheme.inputFill,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        style: GoogleFonts.roboto(
                          fontSize: width < 360 ? 15.5 : 16,
                          color: ChatTheme.textPrimary,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: GoogleFonts.roboto(
                            color: ChatTheme.textSecondary,
                            fontSize: width < 360 ? 15.5 : 16,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.fromLTRB(
                            0,
                            width < 360 ? 11 : 12,
                            4,
                            width < 360 ? 11 : 12,
                          ),
                        ),
                        onSubmitted: (_) {
                          if (hasText) onSend();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2, right: 4),
                      child: IconButton(
                        tooltip: 'Camera',
                        onPressed: onCamera,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.camera_alt_rounded,
                          color: ChatTheme.iconMuted,
                          size: 23,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: width < 360 ? 5 : 7),
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: hasText ? 1 : 0.45,
                child: Material(
                  color: ChatTheme.header,
                  shape: const CircleBorder(),
                  elevation: hasText ? 2 : 0,
                  shadowColor: ChatTheme.header.withValues(alpha: 0.4),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: hasText ? onSend : null,
                    child: SizedBox(
                      width: sendSize,
                      height: sendSize,
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
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
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: ChatTheme.dateChip,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 1,
                offset: const Offset(0, 0.5),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ChatTheme.systemChip,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 12.5,
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5C4),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          isGroup
              ? 'Messages are end-to-end encrypted in this group. Only members can read them.'
              : 'Messages are end-to-end encrypted. No one outside this chat can read them.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 13,
            height: 1.35,
            color: const Color(0xFF54656F),
          ),
        ),
      ),
    );
  }
}
