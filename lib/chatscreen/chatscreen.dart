import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/conversation_screen.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/chatscreen/select_participants_screen.dart';
import 'package:grjoffice_apps/chatscreen/services/chat_service.dart';
import 'package:grjoffice_apps/chatscreen/widgets/chat_thread_tile.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  final _service = ChatService.instance;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.initialize();
    _service.addListener(_onUpdated);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdated() {
    if (mounted) setState(() {});
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  List<ChatThread> get _filteredThreads {
    final threads = _service.threads;
    if (_searchQuery.isEmpty) return threads;
    return threads.where((thread) {
      final haystack = '${thread.title} ${thread.lastMessage?.text ?? ''}'.toLowerCase();
      return haystack.contains(_searchQuery);
    }).toList();
  }

  void _openConversation(String threadId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ConversationScreen(threadId: threadId)),
    );
  }

  void _openNewGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SelectParticipantsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final threads = _filteredThreads;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
              color: AppColors.cardWhite,
              child: _buildTopBar(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search chats',
                  hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                  filled: true,
                  fillColor: AppColors.cardWhite,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: threads.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: threads.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 72,
                        color: AppColors.borderGray.withValues(alpha: 0.35),
                      ),
                      itemBuilder: (context, index) {
                        final thread = threads[index];
                        return ChatThreadTile(
                          thread: thread,
                          onTap: () => _openConversation(thread.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.headingBlack,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Chats',
            style: GoogleFonts.poppins(
              color: AppColors.headingBlack,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 22),
          color: AppColors.cardWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'new_group') _openNewGroup();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'new_group',
              child: Row(
                children: [
                  const Icon(Icons.group_add_outlined, color: AppColors.primaryRed, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'New group',
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.headingBlack),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 52,
              color: AppColors.textSecondary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              'No chats found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.headingBlack,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap ⋮ and choose New group to start.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
