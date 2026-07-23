import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/task_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/tasksscreen/add_task_screen.dart';
import 'package:grjoffice_apps/tasksscreen/task_messages_screen.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ViewTaskScreen extends StatefulWidget {
  const ViewTaskScreen({super.key, required this.task});

  final Task task;

  @override
  State<ViewTaskScreen> createState() => _ViewTaskScreenState();
}

class _ViewTaskScreenState extends State<ViewTaskScreen> {
  bool _isLoading = true;
  Task? _detail;
  bool _didUpdate = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _unreadCount = widget.task.unreadCount;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTask());
  }

  Future<void> _loadTask() async {
    final taskId = int.tryParse(widget.task.id);
    if (taskId == null) {
      if (!mounted) return;
      setState(() {
        _detail = widget.task;
        _isLoading = false;
      });
      return;
    }

    final task = await getTaskApi(context, taskId);
    if (!mounted) return;
    setState(() {
      _detail = task ?? widget.task;
      _unreadCount = (task ?? widget.task).unreadCount;
      _isLoading = false;
    });
  }

  Future<void> _openMessages() async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => TaskMessagesScreen(task: _task)),
    );
    if (!mounted || result == null) return;
    setState(() {
      _unreadCount = result;
      final current = _task;
      _detail = current.copyWith(unreadCount: result);
      _didUpdate = true;
    });
  }

  Task get _task => _detail ?? widget.task;

  Future<void> _editTask() async {
    final updated = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => AddTaskScreen(task: _task)),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _detail = updated;
      _didUpdate = true;
    });
  }

  Future<void> _deleteTask() async {
    final task = _task;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Delete Task',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppColors.headingBlack,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${task.title}"?',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final taskId = int.tryParse(task.id);
    if (taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid task id.')),
      );
      return;
    }

    final ok = await deleteTaskApi(context, taskId);
    if (!mounted || !ok) return;

    Navigator.pop(context, 'deleted');
  }

  void _goBack() {
    Navigator.pop(context, _didUpdate ? _detail : null);
  }

  String _text(String? value, {String fallback = '-'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.start:
        return 'Start';
      case TaskStatus.onProgress:
        return 'On Progress';
      case TaskStatus.inPending:
        return 'In Pending';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.start:
        return const Color(0xFF06B6D4);
      case TaskStatus.onProgress:
        return const Color(0xFF8B5CF6);
      case TaskStatus.inPending:
        return const Color(0xFFF59E0B);
      case TaskStatus.completed:
        return const Color(0xFF10B981);
    }
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.primaryRed;
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return const Color(0xFF64748B);
    }
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final task = _task;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Task Details',
              onBack: _goBack,
              horizontalPadding: hPad,
              actions: [
                IconButton(
                  onPressed: _isLoading ? null : _openMessages,
                  icon: Badge(
                    isLabelVisible: _unreadCount > 0,
                    label: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.headingBlack),
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _editTask,
                  icon: const Icon(Icons.edit_outlined, color: AppColors.headingBlack),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _deleteTask,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.primaryRed),
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: _loadTask,
                      child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(task),
                              const SizedBox(height: 12),
                              _buildMessagesButton(),
                              const SizedBox(height: 16),
                              _buildQuickStats(task),
                              const SizedBox(height: 16),
                              _buildSection(
                                title: 'Details',
                                icon: Icons.assignment_outlined,
                                children: [
                                  _infoTile(Icons.title_rounded, 'Title', task.title),
                                  _infoTile(
                                    Icons.notes_rounded,
                                    'Description',
                                    _text(task.description),
                                  ),
                                  _infoTile(
                                    Icons.folder_open_outlined,
                                    'Project',
                                    _text(task.projectName),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSection(
                                title: 'Schedule',
                                icon: Icons.event_outlined,
                                children: [
                                  _infoTile(
                                    Icons.play_arrow_rounded,
                                    'Start Date',
                                    _formatDate(task.startDate),
                                  ),
                                  _infoTile(
                                    Icons.flag_outlined,
                                    'Due Date',
                                    _formatDate(task.dueDate),
                                  ),
                                  _infoTile(
                                    Icons.event_available_outlined,
                                    'End Date',
                                    _formatDate(task.endDate),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildSection(
                                title: 'Assignee',
                                icon: Icons.person_outline,
                                children: [
                                  _buildAssigneeRow(task),
                                  _infoTile(
                                    Icons.badge_outlined,
                                    'User ID',
                                    task.userId?.toString() ?? '-',
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildHeader(Task task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: GoogleFonts.poppins(
              color: AppColors.headingBlack,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _text(task.projectName, fallback: 'No project'),
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                _statusLabel(task.status),
                _statusColor(task.status),
              ),
              _chip(
                _priorityLabel(task.priority),
                _priorityColor(task.priority),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesButton() {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _isLoading ? null : _openMessages,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Messages',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.headingBlack,
                      ),
                    ),
                    Text(
                      _unreadCount > 0
                          ? '$_unreadCount unread message${_unreadCount == 1 ? '' : 's'}'
                          : 'Chat about this task',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickStats(Task task) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.flag_outlined,
            label: 'Status',
            value: _statusLabel(task.status),
            color: _statusColor(task.status),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.priority_high_rounded,
            label: 'Level',
            value: _priorityLabel(task.priority),
            color: _priorityColor(task.priority),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.tag_rounded,
            label: 'Task ID',
            value: '#${task.id}',
            color: AppColors.primaryRed,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: AppColors.headingBlack,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneeRow(Task task) {
    final avatar = mediaUrl(task.assigneeAvatarUrl);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.iconBgGray,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isNotEmpty
                ? null
                : const Icon(Icons.person, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assignee',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _text(task.assigneeName, fallback: 'Unassigned'),
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderGray.withValues(alpha: 0.45)),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
