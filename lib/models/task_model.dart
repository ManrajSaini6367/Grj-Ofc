import 'package:flutter/material.dart';
import 'package:grjoffice_apps/models/pagination_model.dart';

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

extension TaskStatusApi on TaskStatus {
  String get apiValue {
    switch (this) {
      case TaskStatus.start:
        return 'start';
      case TaskStatus.onProgress:
        return 'on_progress';
      case TaskStatus.inPending:
        return 'in_pending';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  static TaskStatus fromApi(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'start':
        return TaskStatus.start;
      case 'on_progress':
        return TaskStatus.onProgress;
      case 'in_pending':
        return TaskStatus.inPending;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.start;
    }
  }
}

extension TaskPriorityApi on TaskPriority {
  String get apiValue {
    switch (this) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.low:
        return 'low';
    }
  }

  static TaskPriority fromApi(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }
}

class Task {
  final String id;
  final int? siteId;
  final int? userId;
  final String title;
  final String projectName;
  final DateTime dueDate;
  final DateTime? endDate;
  final TaskPriority priority;
  final String? level;
  final TaskStatus status;
  final String assigneeName;
  final String? assigneeAvatarUrl;
  final Color? customColor;
  final DateTime? startDate;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    this.siteId,
    this.userId,
    required this.title,
    required this.projectName,
    required this.dueDate,
    this.endDate,
    required this.priority,
    this.level,
    required this.status,
    required this.assigneeName,
    this.assigneeAvatarUrl,
    this.customColor,
    this.startDate,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: (json['id'] ?? '').toString(),
      siteId: json['site_id'] as int?,
      userId: json['user_id'] as int?,
      title: json['title']?.toString() ?? '',
      projectName: json['project_name']?.toString() ?? '',
      dueDate: _parseDate(json['due_date']) ?? DateTime.now(),
      endDate: _parseDate(json['end_date']),
      priority: TaskPriorityApi.fromApi(
        json['priority']?.toString() ?? json['level']?.toString(),
      ),
      level: json['level']?.toString(),
      status: TaskStatusApi.fromApi(json['status']?.toString()),
      assigneeName: json['assignee_name']?.toString() ?? '',
      assigneeAvatarUrl: json['assignee_avatar_url']?.toString(),
      startDate: _parseDate(json['start_date']),
      description: json['description']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? id,
      'site_id': siteId,
      'user_id': userId,
      'title': title,
      'description': description,
      'project_name': projectName,
      'start_date': _formatDate(startDate),
      'due_date': _formatDate(dueDate),
      'end_date': _formatDate(endDate),
      'status': status.apiValue,
      'priority': priority.apiValue,
      'level': level ?? priority.apiValue,
      'assignee_name': assigneeName,
      'assignee_avatar_url': assigneeAvatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    int? siteId,
    int? userId,
    String? title,
    String? projectName,
    DateTime? dueDate,
    DateTime? endDate,
    TaskPriority? priority,
    String? level,
    TaskStatus? status,
    String? assigneeName,
    String? assigneeAvatarUrl,
    Color? customColor,
    DateTime? startDate,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      projectName: projectName ?? this.projectName,
      dueDate: dueDate ?? this.dueDate,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      level: level ?? this.level,
      status: status ?? this.status,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeAvatarUrl: assigneeAvatarUrl ?? this.assigneeAvatarUrl,
      customColor: customColor ?? this.customColor,
      startDate: startDate ?? this.startDate,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static DateTime? _parseDateTime(dynamic value) => _parseDate(value);

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class TaskSummary {
  const TaskSummary({
    required this.total,
    required this.start,
    required this.onProgress,
    required this.inPending,
    required this.completed,
  });

  final int total;
  final int start;
  final int onProgress;
  final int inPending;
  final int completed;

  factory TaskSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TaskSummary(
        total: 0,
        start: 0,
        onProgress: 0,
        inPending: 0,
        completed: 0,
      );
    }
    return TaskSummary(
      total: json['total'] as int? ?? 0,
      start: json['start'] as int? ?? 0,
      onProgress: json['on_progress'] as int? ?? 0,
      inPending: json['in_pending'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'start': start,
      'on_progress': onProgress,
      'in_pending': inPending,
      'completed': completed,
    };
  }
}

class TasksListData {
  const TasksListData({
    required this.items,
    this.pagination,
    this.summary,
  });

  final List<Task> items;
  final PaginationModel? pagination;
  final TaskSummary? summary;

  factory TasksListData.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return TasksListData(
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(Task.fromJson)
              .toList()
          : const <Task>[],
      pagination: json['pagination'] is Map<String, dynamic>
          ? PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
      summary: json['summary'] is Map<String, dynamic>
          ? TaskSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TasksListResponse {
  const TasksListResponse({
    required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String? message;
  final TasksListData? data;

  factory TasksListResponse.fromJson(Map<String, dynamic> json) {
    return TasksListResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? TasksListData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
