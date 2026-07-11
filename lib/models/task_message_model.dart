import 'package:grjoffice_apps/models/pagination_model.dart';

class TaskMessagePerson {
  const TaskMessagePerson({
    required this.id,
    required this.name,
    this.email,
  });

  final int id;
  final String name;
  final String? email;

  factory TaskMessagePerson.fromJson(Map<String, dynamic> json) {
    return TaskMessagePerson(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (email != null) 'email': email,
      };
}

class TaskMessageTaskInfo {
  const TaskMessageTaskInfo({
    required this.id,
    required this.title,
    this.userId,
    this.assigneeName,
  });

  final int id;
  final String title;
  final int? userId;
  final String? assigneeName;

  factory TaskMessageTaskInfo.fromJson(Map<String, dynamic> json) {
    return TaskMessageTaskInfo(
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      userId: json['user_id'] as int?,
      assigneeName: json['assignee_name']?.toString(),
    );
  }
}

class TaskMessage {
  const TaskMessage({
    required this.id,
    required this.taskId,
    required this.message,
    required this.status,
    required this.isMine,
    this.sender,
    this.receiver,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int taskId;
  final String message;
  final String status;
  final bool isMine;
  final TaskMessagePerson? sender;
  final TaskMessagePerson? receiver;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isUnread => status.toLowerCase() == 'unread';

  factory TaskMessage.fromJson(Map<String, dynamic> json) {
    return TaskMessage(
      id: json['id'] as int? ?? 0,
      taskId: json['task_id'] as int? ?? 0,
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isMine: json['is_mine'] == true,
      sender: json['sender'] is Map<String, dynamic>
          ? TaskMessagePerson.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      receiver: json['receiver'] is Map<String, dynamic>
          ? TaskMessagePerson.fromJson(json['receiver'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_id': taskId,
        'message': message,
        'status': status,
        'is_mine': isMine,
        if (sender != null) 'sender': sender!.toJson(),
        if (receiver != null) 'receiver': receiver!.toJson(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class TaskMessagesListData {
  const TaskMessagesListData({
    this.task,
    this.items = const [],
    this.pagination,
    this.unreadCount = 0,
  });

  final TaskMessageTaskInfo? task;
  final List<TaskMessage> items;
  final PaginationModel? pagination;
  final int unreadCount;

  factory TaskMessagesListData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return TaskMessagesListData(
      task: json['task'] is Map<String, dynamic>
          ? TaskMessageTaskInfo.fromJson(json['task'] as Map<String, dynamic>)
          : null,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => TaskMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      pagination: json['pagination'] is Map<String, dynamic>
          ? PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}

class TaskMessagesListResponse {
  const TaskMessagesListResponse({
    this.success,
    this.message,
    this.data,
  });

  final bool? success;
  final String? message;
  final TaskMessagesListData? data;

  factory TaskMessagesListResponse.fromJson(Map<String, dynamic> json) {
    return TaskMessagesListResponse(
      success: json['success'] as bool?,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? TaskMessagesListData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
