import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/models/task_model.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/tasksscreen/add_task_screen.dart';
import 'package:grjoffice_apps/tasksscreen/task_messages_screen.dart';
import 'package:grjoffice_apps/tasksscreen/view_task_screen.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Task> _tasks = [];
  TaskSummary? _summary;
  bool _isLoading = true;

  // Filter and Search states
  String _selectedFilter = 'All'; // 'All', 'Start', 'On Progress', 'In Pending', 'Completed'
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Sort states: 'dueDate', 'priority', 'title'
  String _sortBy = 'dueDate';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTasks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);

    final sortBy = switch (_sortBy) {
      'priority' => 'priority',
      'title' => 'title',
      _ => 'due_date',
    };

    final response = await getTasksApi(
      context,
      status: 'all',
      search: _searchQuery,
      sortBy: sortBy,
      sortDir: _sortAscending ? 'asc' : 'desc',
      perPage: 50,
    );

    if (!mounted) return;
    setState(() {
      _tasks = response?.data?.items ?? [];
      _summary = response?.data?.summary;
      _isLoading = false;
    });
  }

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }

  // Stats — prefer API summary when available
  int get _totalCount => _summary?.total ?? _tasks.length;
  int get _startCount =>
      _summary?.start ?? _tasks.where((t) => t.status == TaskStatus.start).length;
  int get _onProgressCount =>
      _summary?.onProgress ??
      _tasks.where((t) => t.status == TaskStatus.onProgress).length;
  int get _inPendingCount =>
      _summary?.inPending ??
      _tasks.where((t) => t.status == TaskStatus.inPending).length;
  int get _completedCount =>
      _summary?.completed ??
      _tasks.where((t) => t.status == TaskStatus.completed).length;

  // Toggle check/complete status of a task
  Future<void> _toggleTaskStatus(Task task) async {
    final nextStatus = task.status == TaskStatus.completed
        ? TaskStatus.start
        : TaskStatus.completed;
    await _setTaskStatus(task, nextStatus);
  }

  // Change task status via menu / checkbox
  Future<void> _setTaskStatus(Task task, TaskStatus newStatus) async {
    final taskId = int.tryParse(task.id);
    if (taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid task id.')),
      );
      return;
    }

    if (task.status == newStatus) return;

    final updated = await updateTaskStatusApi(
      context,
      taskId: taskId,
      status: newStatus.apiValue,
    );
    if (!mounted) return;
    if (updated == null) return;

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updated;
      }
      _summary = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task marked as ${_statusLabel(newStatus)}'),
        duration: const Duration(seconds: 2),
      ),
    );
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

  // Delete a task
  Future<void> _deleteTask(Task task) async {
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

    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
      _summary = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task "${task.title}" deleted')),
    );
  }

  // Filter tasks based on current criteria
  List<Task> get _filteredTasks {
    List<Task> filtered = _tasks;

    if (_selectedFilter == 'Start') {
      filtered = filtered.where((t) => t.status == TaskStatus.start).toList();
    } else if (_selectedFilter == 'On Progress') {
      filtered = filtered.where((t) => t.status == TaskStatus.onProgress).toList();
    } else if (_selectedFilter == 'In Pending') {
      filtered = filtered.where((t) => t.status == TaskStatus.inPending).toList();
    } else if (_selectedFilter == 'Completed') {
      filtered = filtered.where((t) => t.status == TaskStatus.completed).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (t) =>
                t.title.toLowerCase().contains(query) ||
                t.projectName.toLowerCase().contains(query) ||
                t.assigneeName.toLowerCase().contains(query),
          )
          .toList();
    }

    filtered.sort((a, b) {
      int comparison = 0;
      if (_sortBy == 'dueDate') {
        comparison = a.dueDate.compareTo(b.dueDate);
      } else if (_sortBy == 'priority') {
        comparison = a.priority.index.compareTo(b.priority.index);
      } else if (_sortBy == 'title') {
        comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // Date formatter helpers
  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  String _formatDate(DateTime date) {
    final dayStr = date.day.toString().padLeft(2, '0');
    final monthStr = _monthName(date.month);
    return '$dayStr $monthStr ${date.year}';
  }

  String _todayLabel() {
    final now = DateTime.now();
    return 'Today, ${now.day} ${_monthName(now.month)}';
  }

  // Toggle Search Text Field
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
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
    final tasksList = _filteredTasks;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(selectedIndex: DrawerIndex.tasks, onItemTap: _onDrawerItemTap),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar.shell(
              title: 'Tasks',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    color: AppColors.headingBlack,
                  ),
                  onPressed: _toggleSearch,
                ),
              ],
            ),
            if (_isSearching)
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.headingBlack),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
              ),
            // Filter Chips Bar
            _buildFilterChips(),
            
            // Summary Cards Carousel/Row
            _buildSummaryCards(),
            
            // List Header: "Today, 4 July" and "Sort" button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _todayLabel(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headingBlack,
                    ),
                  ),
                  InkWell(
                    onTap: _showSortOptions,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sort',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.headingBlack,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.tune_rounded, color: AppColors.headingBlack, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Task List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () => _loadTasks(showLoader: false),
                      child: tasksList.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                                _buildEmptyState(),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 80),
                              itemCount: tasksList.length,
                              itemBuilder: (context, index) {
                                return _buildTaskCard(tasksList[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
          if (newTask != null && newTask is Task && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Task "${newTask.title}" created successfully')),
            );
            await _loadTasks();
          }
        },
        backgroundColor: AppColors.primaryRed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // 1. Filter Chips Section
  Widget _buildFilterChips() {
    final chips = [
      _FilterChipItem('All', Icons.format_list_bulleted_rounded),
      _FilterChipItem('Start', Icons.play_circle_outline_rounded),
      _FilterChipItem('On Progress', Icons.donut_large_rounded),
      _FilterChipItem('In Pending', Icons.access_time_rounded),
      _FilterChipItem('Completed', Icons.check_circle_outline_rounded),
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isSelected = _selectedFilter == chip.label || 
              (_selectedFilter == 'All' && chip.label == 'All');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = chip.label;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRed : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey.shade200.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      chip.icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip.label,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 2. Summary Cards Section
  Widget _buildSummaryCards() {
    return Container(
      height: 108,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _buildStatCard(
            title: 'All Tasks',
            count: _totalCount,
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildStatCard(
            title: 'Start',
            count: _startCount,
            icon: Icons.play_circle_outline_rounded,
            iconColor: const Color(0xFF06B6D4),
            bgColor: const Color(0xFFECFEFF),
          ),
          _buildStatCard(
            title: 'On Progress',
            count: _onProgressCount,
            icon: Icons.incomplete_circle_outlined,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
          ),
          _buildStatCard(
            title: 'In Pending',
            count: _inPendingCount,
            icon: Icons.watch_later_outlined,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFF7ED),
          ),
          _buildStatCard(
            title: 'Completed',
            count: _completedCount,
            icon: Icons.verified_outlined,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      width: 104,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingBlack,
                  height: 1.1,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Empty State Screen
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No tasks found',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          Text(
            _searchQuery.isNotEmpty 
              ? 'Try adjusting your search criteria'
              : 'Add tasks using the + button below',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Custom Task Card Widget
  Widget _buildTaskCard(Task task) {
    final isCompleted = task.status == TaskStatus.completed;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openTask(task),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox status indicator on the left
                GestureDetector(
                  onTap: () => _toggleTaskStatus(task),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    child: _buildTaskStatusWidget(task),
                  ),
                ),
                
                // Title and Project Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title
                      Text(
                        task.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? AppColors.textSecondary : AppColors.headingBlack,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 5),
                      
                      // Folder/Project metadata row
                      Row(
                        children: [
                          Icon(
                            Icons.folder_open_outlined, 
                            size: 14, 
                            color: isCompleted ? AppColors.textSecondary : Colors.grey.shade500
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.projectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Calendar/Date metadata row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined, 
                            size: 14, 
                            color: isCompleted ? Colors.grey.shade400 : const Color(0xFF10B981)
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(task.dueDate),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isCompleted ? Colors.grey.shade400 : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Priority Badge, messages and Action Menu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPriorityBadge(task.priority),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                          onPressed: () => _showTaskMenu(task),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          splashRadius: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMessageIcon(task),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.grey.shade100,
                          child: ClipOval(
                            child: Image.network(
                              task.assigneeAvatarUrl ?? '',
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFECEFF1),
                                  alignment: Alignment.center,
                                  child: Text(
                                    task.assigneeName.isNotEmpty
                                        ? task.assigneeName[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMessageIcon(Task task) {
    final unread = task.unreadCount;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTaskMessages(task),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Badge(
            isLabelVisible: unread > 0,
            label: Text(
              unread > 99 ? '99+' : '$unread',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
            child: Icon(
              unread > 0 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
              size: 20,
              color: unread > 0 ? AppColors.primaryRed : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openTaskMessages(Task task) async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => TaskMessagesScreen(task: task)),
    );
    if (!mounted) return;

    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index < 0) return;

    setState(() {
      _tasks[index] = _tasks[index].copyWith(
        unreadCount: result ?? 0,
      );
    });
  }

  Future<void> _openTask(Task task) async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute(builder: (_) => ViewTaskScreen(task: task)),
    );
    if (!mounted || result == null) return;

    if (result == 'deleted') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task "${task.title}" deleted')),
      );
      await _loadTasks();
      return;
    }

    if (result is Task) {
      await _loadTasks();
    }
  }

  Future<void> _editTask(Task task) async {
    final updated = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)),
    );
    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task "${updated.title}" updated')),
      );
      await _loadTasks();
    }
  }

  // Helper widget to paint the checkbox/progress circle
  Widget _buildTaskStatusWidget(Task task) {
    switch (task.status) {
      case TaskStatus.completed:
        return Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981), // Solid green
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
        );
      case TaskStatus.onProgress:
        return SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            value: 0.35, // partial circle (partially done)
            strokeWidth: 3,
            backgroundColor: Colors.blue.shade50,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)), // custom blue
          ),
        );
      case TaskStatus.inPending:
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: task.customColor ?? const Color(0xFFF59E0B), 
              width: 2,
            ),
          ),
          child: const Center(
            child: Icon(Icons.access_time_rounded, size: 15, color: Color(0xFFF59E0B)),
          ),
        );
      case TaskStatus.start:
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: task.customColor ?? const Color(0xFF9CA3AF), // Custom pending border color or Gray
              width: 2,
            ),
          ),
        );
    }
  }

  // Priority Badge widget
  Widget _buildPriorityBadge(TaskPriority priority) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (priority) {
      case TaskPriority.high:
        bg = const Color(0xFFFFF1F2); // very light pink/red
        fg = const Color(0xFFEF4444); // red
        label = 'High';
        icon = Icons.trending_up_rounded;
        break;
      case TaskPriority.medium:
        bg = const Color(0xFFFFFBEB); // light orange/yellow
        fg = const Color(0xFFF59E0B); // orange
        label = 'Medium';
        icon = Icons.remove_rounded;
        break;
      case TaskPriority.low:
        bg = const Color(0xFFF0FDF4); // light green/blue
        fg = const Color(0xFF3B82F6); // blue
        label = 'Low';
        icon = Icons.trending_down_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // Task Options Bottom Sheet Menu
  void _showTaskMenu(Task task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Task Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headingBlack,
                  ),
                ),
              ),
              const Divider(height: 1),
              
              // Status suboptions
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF06B6D4)),
                        title: Text('Mark as Start', style: GoogleFonts.poppins(fontSize: 13.5)),
                        onTap: () {
                          Navigator.pop(context);
                          _setTaskStatus(task, TaskStatus.start);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.donut_large_rounded, color: Color(0xFF2563EB)),
                        title: Text('Mark as On Progress', style: GoogleFonts.poppins(fontSize: 13.5)),
                        onTap: () {
                          Navigator.pop(context);
                          _setTaskStatus(task, TaskStatus.onProgress);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.access_time_rounded, color: Color(0xFFF59E0B)),
                        title: Text('Mark as In Pending', style: GoogleFonts.poppins(fontSize: 13.5)),
                        onTap: () {
                          Navigator.pop(context);
                          _setTaskStatus(task, TaskStatus.inPending);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
                        title: Text('Mark as Completed', style: GoogleFonts.poppins(fontSize: 13.5)),
                        onTap: () {
                          Navigator.pop(context);
                          _setTaskStatus(task, TaskStatus.completed);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryRed),
                        title: Text('Messages', style: GoogleFonts.poppins(fontSize: 13.5)),
                        onTap: () {
                          Navigator.pop(context);
                          _openTaskMessages(task);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined, color: AppColors.headingBlack),
                        title: Text('Edit Task', style: GoogleFonts.poppins(fontSize: 13.5)),
                        onTap: () {
                          Navigator.pop(context);
                          _editTask(task);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        title: Text('Delete Task', style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          _deleteTask(task);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Sort Menu
  void _showSortOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Sort Tasks By',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headingBlack,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSortRadio(
                    setModalState,
                    label: 'Due Date',
                    value: 'dueDate',
                    icon: Icons.calendar_today_outlined,
                  ),
                  _buildSortRadio(
                    setModalState,
                    label: 'Priority',
                    value: 'priority',
                    icon: Icons.trending_up_rounded,
                  ),
                  _buildSortRadio(
                    setModalState,
                    label: 'Title (A-Z)',
                    value: 'title',
                    icon: Icons.sort_by_alpha_rounded,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      'Ascending Order',
                      style: GoogleFonts.poppins(fontSize: 13.5, color: AppColors.textDark),
                    ),
                    value: _sortAscending,
                    activeColor: AppColors.primaryRed,
                    onChanged: (val) {
                      setModalState(() {
                        _sortAscending = val;
                      });
                      setState(() {
                        _sortAscending = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildSortRadio(StateSetter setModalState, {required String label, required String value, required IconData icon}) {
    final isSelected = _sortBy == value;
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? AppColors.primaryRed : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.5, 
              color: isSelected ? AppColors.primaryRed : AppColors.textDark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
      value: value,
      groupValue: _sortBy,
      activeColor: AppColors.primaryRed,
      onChanged: (val) {
        if (val != null) {
          setModalState(() {
            _sortBy = val;
          });
          setState(() {
            _sortBy = val;
          });
          Navigator.pop(context);
        }
      },
    );
  }

}

// Model helper for UI filter items
class _FilterChipItem {
  final String label;
  final IconData icon;

  _FilterChipItem(this.label, this.icon);
}
