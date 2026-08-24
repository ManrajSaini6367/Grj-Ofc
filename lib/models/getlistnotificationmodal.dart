class Getlistnotification {
  Getlistnotification({
    this.success,
    this.message,
    this.data,
  });

  bool? success;
  String? message;
  GetListNotification? data;

  factory Getlistnotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return Getlistnotification(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: rawData is Map
          ? GetListNotification.fromJson(Map<String, dynamic>.from(rawData))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class GetListNotification {
  GetListNotification({
    this.items,
    this.pagination,
    this.unreadCount,
  });

  List<NotificationListItem>? items;
  NotificationListPagination? pagination;
  int? unreadCount;

  factory GetListNotification.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return GetListNotification(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => NotificationListItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
      pagination: json['pagination'] is Map
          ? NotificationListPagination.fromJson(
              Map<String, dynamic>.from(json['pagination'] as Map),
            )
          : null,
      unreadCount: _asInt(json['unread_count'] ?? json['unreadCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (items != null)
          'items': items!.map((item) => item.toJson()).toList(),
        if (pagination != null) 'pagination': pagination!.toJson(),
        'unread_count': unreadCount,
      };
}

class NotificationListItem {
  NotificationListItem({
    this.id,
    this.userId,
    this.siteId,
    this.title,
    this.text,
    this.module,
    this.type,
    this.icon,
    this.isRead,
    this.readAt,
    this.createdAt,
  });

  int? id;
  int? userId;
  int? siteId;
  String? title;
  String? text;
  String? module;
  String? type;
  String? icon;
  bool? isRead;
  DateTime? readAt;
  DateTime? createdAt;

  factory NotificationListItem.fromJson(Map<String, dynamic> json) {
    return NotificationListItem(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      siteId: _asInt(json['site_id'] ?? json['siteId']),
      title: _asString(json['title']),
      text: _asString(json['text'] ?? json['body'] ?? json['message']),
      module: _asString(json['module']),
      type: _asString(json['type']),
      icon: _asString(json['icon']),
      isRead: _asBool(json['is_read'] ?? json['isRead']),
      readAt: _asDate(json['read_at'] ?? json['readAt']),
      createdAt: _asDate(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'site_id': siteId,
        'title': title,
        'text': text,
        'module': module,
        'type': type,
        'icon': icon,
        'is_read': isRead,
        'read_at': readAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };
}

class NotificationListPagination {
  NotificationListPagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
    this.prevPageUrl,
    this.nextPageUrl,
  });

  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  int? from;
  int? to;
  dynamic prevPageUrl;
  dynamic nextPageUrl;

  factory NotificationListPagination.fromJson(Map<String, dynamic> json) {
    return NotificationListPagination(
      currentPage: _asInt(json['current_page'] ?? json['currentPage']),
      lastPage: _asInt(json['last_page'] ?? json['lastPage']),
      perPage: _asInt(json['per_page'] ?? json['perPage']),
      total: _asInt(json['total']),
      from: _asInt(json['from']),
      to: _asInt(json['to']),
      prevPageUrl: json['prev_page_url'] ?? json['prevPageUrl'],
      nextPageUrl: json['next_page_url'] ?? json['nextPageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
        'from': from,
        'to': to,
        'prev_page_url': prevPageUrl,
        'next_page_url': nextPageUrl,
      };
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is bool) return value ? 1 : 0;
  return int.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value == true || value == 1 || value == '1' || value == 'true') {
    return true;
  }
  return false;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
