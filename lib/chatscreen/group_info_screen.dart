import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/chatscreen/select_participants_screen.dart';
import 'package:grjoffice_apps/chatscreen/services/chat_service.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/chatscreen/widgets/chat_avatar.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key, required this.threadId});

  final String threadId;

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final _service = ChatService.instance;
  bool _deleting = false;
  bool _leaving = false;
  int? _removingMemberId;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.loadThreadDetails(widget.threadId);
    });
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdated);
    super.dispose();
  }

  void _onUpdated() {
    if (mounted) setState(() {});
  }

  ChatThread? get _thread => _service.threadById(widget.threadId);

  Future<void> _addMembers() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SelectParticipantsScreen(
          threadId: widget.threadId,
          isAddMembers: true,
        ),
      ),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Members added successfully.')),
      );
    }
  }

  Future<void> _removeMember(ChatUser member) async {
    if (_removingMemberId != null || _leaving || _deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Remove member?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove ${member.name} from this group?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removingMemberId = member.id);
    final result = await _service.removeGroupMemberOnServer(
      threadId: widget.threadId,
      memberId: member.id,
    );
    if (!mounted) return;
    setState(() => _removingMemberId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message, style: GoogleFonts.poppins()),
        backgroundColor: result.success ? null : AppColors.primaryRed,
      ),
    );
  }

  Future<void> _leaveGroup() async {
    if (_leaving || _deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Leave group?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You will no longer receive messages from this group.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Leave',
              style: GoogleFonts.poppins(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _leaving = true);
    final result = await _service.leaveGroupOnServer(widget.threadId);
    if (!mounted) return;
    setState(() => _leaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message, style: GoogleFonts.poppins()),
        backgroundColor: result.success ? null : AppColors.primaryRed,
      ),
    );

    if (result.success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _deleteGroup() async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete group?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently delete the group for all members.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final result = await _service.deleteGroupOnServer(widget.threadId);
    if (!mounted) return;
    setState(() => _deleting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message, style: GoogleFonts.poppins()),
        backgroundColor:
            result.success ? null : AppColors.primaryRed,
      ),
    );

    if (result.success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    if (thread == null || !thread.isGroup) {
      return Scaffold(
        backgroundColor: AppColors.backgroundGray,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar.page(
                title: 'Group info',
                onBack: () => Navigator.pop(context),
              ),
              const Expanded(child: Center(child: Text('Group not found'))),
            ],
          ),
        ),
      );
    }

    final members = _service.groupMembers(thread);
    final online = _service.onlineMembersCount(thread);
    final isAdmin = _service.isGroupAdmin(thread);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Group info',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: ChatAvatar(
                      user: null,
                      isGroup: true,
                      groupLabel: thread.title,
                      groupColor: thread.groupColor,
                      radius: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      thread.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                      ),
                    ),
                  ),
                  if (thread.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        thread.description!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Group · ${thread.participantIds.length} members · $online online',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _actionTile(
                    icon: Icons.person_add_outlined,
                    label: 'Add members',
                    onTap: _addMembers,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      '${members.length} MEMBERS',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  ...members.map((member) {
                    final isMe = member.id == _service.currentUserId;
                    final isMemberAdmin = thread.adminId == member.id;
                    return Material(
                      color: AppColors.cardWhite,
                      child: ListTile(
                        leading: ChatAvatar(user: member, showOnlineDot: true, radius: 20),
                        title: Text(
                          isMe ? '${member.name} (You)' : member.name,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          isMemberAdmin
                              ? 'Group admin'
                              : (member.isOnline ? 'online' : 'offline'),
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: isAdmin && !isMe
                            ? (_removingMemberId == member.id
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryRed,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: AppColors.primaryRed,
                                    ),
                                    onPressed: (_removingMemberId != null ||
                                            _leaving ||
                                            _deleting)
                                        ? null
                                        : () => _removeMember(member),
                                  ))
                            : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  _actionTile(
                    icon: Icons.logout_rounded,
                    label: _leaving ? 'Leaving…' : 'Leave group',
                    color: AppColors.primaryRed,
                    onTap: (_leaving || _deleting) ? null : _leaveGroup,
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    _actionTile(
                      icon: Icons.delete_outline,
                      label: _deleting ? 'Deleting…' : 'Delete group',
                      color: AppColors.primaryRed,
                      onTap: (_leaving || _deleting) ? null : _deleteGroup,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? color,
  }) {
    return Material(
      color: AppColors.cardWhite,
      child: ListTile(
        enabled: onTap != null,
        leading: Icon(icon, color: color ?? AppColors.primaryRed),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color ?? AppColors.headingBlack,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
