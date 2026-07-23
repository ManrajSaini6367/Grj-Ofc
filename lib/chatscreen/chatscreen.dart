import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/conversation_screen.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/chatscreen/select_participants_screen.dart';
import 'package:grjoffice_apps/chatscreen/services/chat_service.dart';
import 'package:grjoffice_apps/chatscreen/widgets/chat_thread_tile.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _service = ChatService.instance;
  Timer? _searchDebounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdated);
    unawaited(_service.initialize());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _service.removeListener(_onUpdated);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdated() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() => _searchQuery = query.toLowerCase());
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_service.loadChatList(search: query));
    });
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
      final haystack =
          '${thread.title} ${thread.lastMessage?.text ?? ''}'.toLowerCase();
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

  void _openNewChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SelectParticipantsScreen(isNewChat: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final threads = _filteredThreads;
    final loading = _service.isLoading && !_service.isInitialized;
    final refreshing = _service.isLoading && _service.isInitialized;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: -1,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.tab(
              title: 'Chats',
              scaffoldKey: _scaffoldKey,
              showProfile: true,
              horizontalPadding: hPad,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  color: AppColors.cardWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'new_chat') _openNewChat();
                    if (value == 'new_group') _openNewGroup();
                    if (value == 'refresh') unawaited(_service.refresh());
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'new_chat',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_outlined,
                            color: AppColors.primaryRed,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'New chat',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.headingBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'new_group',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.group_add_outlined,
                            color: AppColors.primaryRed,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'New group',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.headingBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.refresh,
                            color: AppColors.primaryRed,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Refresh',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.headingBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search chats',
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.inputHint,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: AppColors.cardWhite,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.borderGray.withValues(alpha: 0.6),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.borderGray.withValues(alpha: 0.6),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryRed,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            if (refreshing)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primaryRed,
                backgroundColor: Colors.transparent,
              ),
            Expanded(child: _buildBody(threads, loading)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<ChatThread> threads, bool loading) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    if (_service.error != null && threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                _service.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.headingBlack,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => unawaited(_service.refresh()),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (threads.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: _service.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
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
              'Pull down to refresh, or start a new group.',
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
