import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/chatscreen/conversation_screen.dart';
import 'package:grjoffice_apps/chatscreen/services/chat_service.dart';
import 'package:grjoffice_apps/chatscreen/widgets/chat_avatar.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

/// Step 2: Group name, description, and profile color.
class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({super.key, required this.memberIds});

  final List<int> memberIds;

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _service = ChatService.instance;
  Color _avatarColor = ChatService.groupAvatarOptions.first;
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickAvatarColor() {
    if (_creating) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose group color',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingBlack,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: ChatService.groupAvatarOptions.map((color) {
                  final selected = color.toARGB32() == _avatarColor.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      setState(() => _avatarColor = color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? color : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Icon(Icons.groups_rounded, color: color),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a group name.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    if (_creating) return;
    setState(() => _creating = true);

    final result = await _service.createGroupOnServer(
      name: name,
      memberIds: widget.memberIds,
      description: _descriptionController.text,
      groupAvatarColor: _avatarColor.toARGB32(),
    );

    if (!mounted) return;
    setState(() => _creating = false);

    if (!result.success || result.thread == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message,
          style: GoogleFonts.poppins(),
        ),
      ),
    );

    Navigator.of(context)
      ..pop()
      ..pop()
      ..push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(threadId: result.thread!.id),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'New group',
              onBack: _creating ? null : () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    GroupProfileAvatar(
                      label: _nameController.text.isEmpty
                          ? 'Group'
                          : _nameController.text,
                      color: _avatarColor,
                      radius: 56,
                      showCamera: true,
                      onTap: _pickAvatarColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to set group icon color',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      enabled: !_creating,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDecoration('Group subject'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _descriptionController,
                      enabled: !_creating,
                      minLines: 2,
                      maxLines: 3,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration:
                          _inputDecoration('Group description (optional)'),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${widget.memberIds.length + 1} participants including you',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _creating ? null : _createGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor:
                              AppColors.primaryRed.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _creating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Create group',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.inputHint),
      filled: true,
      fillColor: AppColors.cardWhite,
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
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
      ),
    );
  }
}
