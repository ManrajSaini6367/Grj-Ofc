import 'package:flutter/material.dart';

enum TaskStatus {
  start,
  onProgress,
  inPending,
  completed,
}

enum TaskPriority {
  high,
  medium,
  low,
}

class Task {
  final String id;
  final String title;
  final String projectName;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String assigneeName;
  final String? assigneeAvatarUrl;
  final Color? customColor; // Used for customizing the pending circle outline color
  final DateTime? startDate;
  final String? description;

  Task({
    required this.id,
    required this.title,
    required this.projectName,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.assigneeName,
    this.assigneeAvatarUrl,
    this.customColor,
    this.startDate,
    this.description,
  });

  Task copyWith({
    String? id,
    String? title,
    String? projectName,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    String? assigneeName,
    String? assigneeAvatarUrl,
    Color? customColor,
    DateTime? startDate,
    String? description,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      projectName: projectName ?? this.projectName,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeAvatarUrl: assigneeAvatarUrl ?? this.assigneeAvatarUrl,
      customColor: customColor ?? this.customColor,
      startDate: startDate ?? this.startDate,
      description: description ?? this.description,
    );
  }
}

// Default mock tasks representing the screenshot's items
final List<Task> kMockTasks = [
  Task(
    id: '1',
    title: 'Design Homepage UI',
    projectName: 'Web App Redesign',
    dueDate: DateTime(2026, 7, 5),
    priority: TaskPriority.high,
    status: TaskStatus.start,
    assigneeName: 'Amit',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop',
    customColor: const Color(0xFF6366F1), // Indigo/Blue
  ),
  Task(
    id: '2',
    title: 'Develop Login API',
    projectName: 'Backend Development',
    dueDate: DateTime(2026, 7, 6),
    priority: TaskPriority.high,
    status: TaskStatus.inPending,
    assigneeName: 'Sumit',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100&h=100&fit=crop',
    customColor: const Color(0xFFF59E0B), // Orange/Yellow
  ),
  Task(
    id: '3',
    title: 'Create User Dashboard',
    projectName: 'Web App Redesign',
    dueDate: DateTime(2026, 7, 7),
    priority: TaskPriority.medium,
    status: TaskStatus.start,
    assigneeName: 'Nehal',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',
    customColor: const Color(0xFF9CA3AF), // Gray
  ),
  Task(
    id: '4',
    title: 'Fix Mobile Responsive Issues',
    projectName: 'Web App Redesign',
    dueDate: DateTime(2026, 7, 9),
    priority: TaskPriority.medium,
    status: TaskStatus.onProgress,
    assigneeName: 'Rahul',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
  ),
  Task(
    id: '5',
    title: 'Integrate Payment Gateway',
    projectName: 'Backend Development',
    dueDate: DateTime(2026, 7, 8),
    priority: TaskPriority.high,
    status: TaskStatus.start,
    assigneeName: 'Pooja',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop',
    customColor: const Color(0xFF9CA3AF), // Gray
  ),
  Task(
    id: '6',
    title: 'Optimize Database Queries',
    projectName: 'Backend Development',
    dueDate: DateTime(2026, 7, 3),
    priority: TaskPriority.high,
    status: TaskStatus.completed,
    assigneeName: 'Raj',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop',
  ),
  Task(
    id: '7',
    title: 'Setup CI/CD Pipeline',
    projectName: 'Devops Infrastructure',
    dueDate: DateTime(2026, 7, 10),
    priority: TaskPriority.high,
    status: TaskStatus.onProgress,
    assigneeName: 'Vikram',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&h=100&fit=crop',
  ),
  Task(
    id: '8',
    title: 'Write Unit Tests for Auth',
    projectName: 'Backend Development',
    dueDate: DateTime(2026, 7, 11),
    priority: TaskPriority.low,
    status: TaskStatus.start,
    assigneeName: 'Neha',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop',
    customColor: const Color(0xFF6366F1),
  ),
  Task(
    id: '9',
    title: 'Draft API Documentation',
    projectName: 'Backend Development',
    dueDate: DateTime(2026, 7, 12),
    priority: TaskPriority.low,
    status: TaskStatus.onProgress,
    assigneeName: 'Priya',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&h=100&fit=crop',
  ),
  Task(
    id: '10',
    title: 'Conduct User Testing',
    projectName: 'Web App Redesign',
    dueDate: DateTime(2026, 7, 15),
    priority: TaskPriority.high,
    status: TaskStatus.onProgress,
    assigneeName: 'Karan',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&h=100&fit=crop',
  ),
  Task(
    id: '11',
    title: 'Refactor State Management',
    projectName: 'Web App Redesign',
    dueDate: DateTime(2026, 7, 1),
    priority: TaskPriority.medium,
    status: TaskStatus.completed,
    assigneeName: 'Simran',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100&h=100&fit=crop',
  ),
  Task(
    id: '12',
    title: 'Configure Push Notifications',
    projectName: 'Backend Development',
    dueDate: DateTime(2026, 7, 2),
    priority: TaskPriority.medium,
    status: TaskStatus.completed,
    assigneeName: 'Arjun',
    assigneeAvatarUrl: 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=100&h=100&fit=crop',
  ),
];
