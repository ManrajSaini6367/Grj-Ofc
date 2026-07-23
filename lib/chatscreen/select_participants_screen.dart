import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/chatscreen/conversation_screen.dart';
import 'package:grjoffice_apps/chatscreen/group_details_screen.dart';
import 'package:grjoffice_apps/chatscreen/services/chat_service.dart';
import 'package:grjoffice_apps/chatscreen/widgets/chat_avatar.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

/// Step 1: WhatsApp-style select participants screen.
class SelectParticipantsScreen extends StatefulWidget {
  const SelectParticipantsScreen({
    super.key,
    this.threadId,
    this.isAddMembers = false,
    this.isNewChat = false,
  });

  final String? threadId;
  final bool isAddMembers;
  /// Single-user pick → create/open direct chat.
  final bool isNewChat;

  @override
  State<SelectParticipantsScreen> createState() =>
      _SelectParticipantsScreenState();
}

class _SelectParticipantsScreenState extends State<SelectParticipantsScreen> {
  final _searchController = TextEditingController();
  final _service = ChatService.instance;
  final Set<int> _selectedIds = {};
  String _query = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_service.loadChatUsers());
    _service.addListener(_onUpdated);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
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

  List<ChatUser> get _users {
    if (widget.isAddMembers && widget.threadId != null) {
      final thread = _service.threadById(widget.threadId!);
      if (thread == null) return [];
      return _service.availableUsersToAdd(thread);
    }
    return _service.allUsers;
  }

  List<ChatUser> get _filteredUsers {
    if (_query.isEmpty) return _users;
    return _users.where((user) => user.name.toLowerCase().contains(_query)).toList();
  }

  void _toggle(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _openDirectChat(ChatUser user) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final result = await _service.openOrCreateDirectChat(user.id);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.success || result.thread == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, style: GoogleFonts.poppins()),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(threadId: result.thread!.id),
      ),
    );
  }

  Future<void> _onNext() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant.')),
      );
      return;
    }

    // ADD MEMBERS flow (from Group Info → Add members)
    if (widget.isAddMembers && widget.threadId != null) {
      if (_submitting) return;
      setState(() => _submitting = true);

      final result = await _service.addGroupMembersOnServer(
        threadId: widget.threadId!,
        memberIds: _selectedIds.toList(),
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, style: GoogleFonts.poppins()),
          backgroundColor: result.success ? null : AppColors.primaryRed,
        ),
      );

      // Only go back on success so Group Info can refresh.
      if (result.success) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    // NEW GROUP flow → next screen for name/description
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(
          memberIds: _selectedIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: widget.isAddMembers
                  ? 'Add Members'
                  : widget.isNewChat
                      ? 'New chat'
                      : 'Add participants',
              onBack: _submitting ? null : () => Navigator.pop(context),
              actions: [
                if (!widget.isNewChat)
                  TextButton(
                    onPressed: (_selectedIds.isEmpty || _submitting)
                        ? null
                        : _onNext,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryRed,
                            ),
                          )
                        : Text(
                            widget.isAddMembers ? 'Add' : 'Next',
                            style: GoogleFonts.poppins(
                              color: _selectedIds.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.primaryRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
              ],
            ),
            if (!widget.isNewChat && _selectedIds.isNotEmpty)
              Container(
                width: double.infinity,
                color: AppColors.cardWhite,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: SizedBox(
                  height: 62,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedIds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final id = _selectedIds.elementAt(index);
                      final user = _service.userById(id);
                      if (user == null) return const SizedBox.shrink();
                      return SizedBox(
                        width: 52,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ChatAvatar(user: user, radius: 20, showOnlineDot: true),
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: GestureDetector(
                                    onTap: () => _toggle(id),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.textSecondary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.name.split(' ').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 10, height: 1.1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search name or number',
                  hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardWhite,
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
              child: Stack(
                children: [
                  ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 72,
                      color: AppColors.borderGray.withValues(alpha: 0.35),
                    ),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final selected = _selectedIds.contains(user.id);
                      return Material(
                        color: AppColors.cardWhite,
                        child: InkWell(
                          onTap: _submitting
                              ? null
                              : () {
                                  if (widget.isNewChat) {
                                    unawaited(_openDirectChat(user));
                                  } else {
                                    _toggle(user.id);
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                ChatAvatar(
                                  user: user,
                                  showOnlineDot: true,
                                  radius: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.headingBlack,
                                    ),
                                  ),
                                ),
                                if (!widget.isNewChat)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primaryRed
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primaryRed
                                            : AppColors.borderGray,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: selected
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: AppColors.white,
                                          )
                                        : null,
                                  )
                                else
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (_submitting && widget.isNewChat)
                    const ColoredBox(
                      color: Color(0x66FFFFFF),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
