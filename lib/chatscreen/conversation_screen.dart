import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/group_info_screen.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/chatscreen/services/chat_service.dart';
import 'package:grjoffice_apps/chatscreen/utils/chat_formatters.dart';
import 'package:grjoffice_apps/chatscreen/widgets/chat_avatar.dart';
import 'package:grjoffice_apps/chatscreen/widgets/message_bubble.dart';
import 'package:grjoffice_apps/chatscreen/widgets/typing_indicator.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.threadId});

  final String threadId;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _service = ChatService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChatUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.markThreadRead(widget.threadId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _service.removeListener(_onChatUpdated);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatUpdated() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
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
  }

  void _openGroupInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupInfoScreen(threadId: widget.threadId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    if (thread == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGray,
        appBar: AppBar(
          backgroundColor: AppColors.cardWhite,
          foregroundColor: AppColors.headingBlack,
          elevation: 0,
          title: Text('Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
        body: const Center(child: Text('Conversation not found')),
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

    final onlineCount = thread.isGroup ? _service.onlineMembersCount(thread) : 0;

    final subtitle = thread.isGroup
        ? '$onlineCount of ${thread.participantIds.length} online'
        : ChatFormatters.presenceLabel(
            isOnline: peer?.isOnline ?? false,
            lastSeen: peer?.lastSeen,
          );

    final typingUser = thread.isTyping && thread.typingUserId != null
        ? _service.userById(thread.typingUserId!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.headingBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: thread.isGroup ? _openGroupInfo : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                ChatAvatar(
                  user: peer,
                  isGroup: thread.isGroup,
                  groupLabel: thread.title,
                  groupColor: thread.isGroup ? thread.groupColor : null,
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headingBlack,
                        ),
                      ),
                      Text(
                        thread.isTyping
                            ? (thread.isGroup && typingUser != null
                                ? '${typingUser.name.split(' ').first} is typing...'
                                : 'typing...')
                            : subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: thread.isTyping
                              ? AppColors.primaryRed
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (thread.isGroup)
            IconButton(
              onPressed: _openGroupInfo,
              icon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              itemCount: thread.messages.length + (thread.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (thread.isTyping && index == thread.messages.length) {
                  return TypingIndicator(
                    label: thread.isGroup && typingUser != null
                        ? '${typingUser.name.split(' ').first} is typing'
                        : 'typing',
                  );
                }

                final message = thread.messages[index];
                final isMine = message.isMine(_service.currentUserId);
                final sender = _service.userById(message.senderId);
                final isSystem = message.text.startsWith('You created') ||
                    message.text.startsWith('You added') ||
                    message.text.startsWith('You removed');

                if (isSystem) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.operationsCardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message.text,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return MessageBubble(
                  message: message,
                  isMine: isMine,
                  showSenderName: thread.isGroup && !isMine,
                  senderName: sender?.name,
                );
              },
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          top: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.inputHint,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.operationsCardBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primaryRed,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _send,
              borderRadius: BorderRadius.circular(24),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.send_rounded, color: AppColors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
