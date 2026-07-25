import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/chatscreen/services/chat_service.dart';
import 'package:grjoffice_apps/chatscreen/utils/chat_formatters.dart';
import 'package:grjoffice_apps/chatscreen/widgets/chat_avatar.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

class ChatThreadTile extends StatelessWidget {
  const ChatThreadTile({
    super.key,
    required this.thread,
    required this.onTap,
  });

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final service = ChatService.instance;
    final last = thread.lastMessage;
    final peer = thread.isGroup
        ? null
        : service.userById(
            thread.participantIds.firstWhere(
              (id) => id != service.currentUserId,
              orElse: () => service.currentUserId,
            ),
          );
    final hasUnread = thread.unreadCount > 0;
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width < 360 ? 14.0 : 16.0;
    final avatarR = width < 360 ? 24.0 : 26.0;

    return Material(
      color: AppColors.cardWhite,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 13),
          child: Row(
            children: [
              ChatAvatar(
                user: peer,
                isGroup: thread.isGroup,
                groupLabel: thread.title,
                groupColor: thread.isGroup ? thread.groupColor : null,
                showOnlineDot: false,
                radius: avatarR,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: AppColors.headingBlack,
                              fontSize: 15,
                              fontWeight:
                                  hasUnread ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (last != null)
                          Text(
                            ChatFormatters.threadTime(last.sentAt),
                            style: GoogleFonts.poppins(
                              color: hasUnread
                                  ? AppColors.primaryRed
                                  : AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _previewText(last, service),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: hasUnread
                                  ? AppColors.textDark
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 10),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              thread.unreadCount > 99
                                  ? '99+'
                                  : '${thread.unreadCount}',
                              style: GoogleFonts.poppins(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
    );
  }

  String _previewText(ChatMessage? last, ChatService service) {
    if (last == null) return 'No messages yet';
    final body = last.hasMedia
        ? (last.isVideo ? 'Video' : 'Photo')
        : last.text;
    if (thread.isGroup) {
      final sender = service.userById(last.senderId);
      final prefix = last.senderId == service.currentUserId
          ? 'You: '
          : '${sender?.name.split(' ').first ?? 'User'}: ';
      return '$prefix$body';
    }
    if (last.senderId == service.currentUserId) return 'You: $body';
    return body;
  }
}
