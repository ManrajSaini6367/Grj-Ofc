import 'dart:convert';

Getchatthreadlistmodal getchatthreadlistmodal(String str) =>
    Getchatthreadlistmodal.fromJson(json.decode(str) as Map<String, dynamic>);

String getchatthreadlistmodalToJson(Getchatthreadlistmodal data) =>
    json.encode(data.toJson());

class Getchatthreadlistmodal {
  bool? success;
  String? message;
  ThreadListData? data;

  Getchatthreadlistmodal({
    this.success,
    this.message,
    this.data,
  });

  factory Getchatthreadlistmodal.fromJson(Map<String, dynamic> json) =>
      Getchatthreadlistmodal(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? ThreadListData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class ThreadListData {
  List<ThreadItem>? items;
  ThreadPagination? pagination;

  ThreadListData({
    this.items,
    this.pagination,
  });

  factory ThreadListData.fromJson(Map<String, dynamic> json) => ThreadListData(
        items: json['items'] is List
            ? (json['items'] as List)
                .whereType<Map>()
                .map((x) => ThreadItem.fromJson(Map<String, dynamic>.from(x)))
                .toList()
            : const [],
        pagination: json['pagination'] is Map<String, dynamic>
            ? ThreadPagination.fromJson(
                json['pagination'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'items': items?.map((x) => x.toJson()).toList(),
        'pagination': pagination?.toJson(),
      };
}

class ThreadItem {
  String? id;
  String? type;
  String? title;
  List<int>? participantIds;
  dynamic description;
  dynamic adminId;
  dynamic avatarUrl;
  dynamic groupAvatarColor;
  int? unreadCount;
  bool? isGroupAdmin;
  ThreadLastMessage? lastMessage;
  DateTime? updatedAt;
  DateTime? createdAt;
  List<ThreadParticipant>? participants;

  ThreadItem({
    this.id,
    this.type,
    this.title,
    this.participantIds,
    this.description,
    this.adminId,
    this.avatarUrl,
    this.groupAvatarColor,
    this.unreadCount,
    this.isGroupAdmin,
    this.lastMessage,
    this.updatedAt,
    this.createdAt,
    this.participants,
  });

  factory ThreadItem.fromJson(Map<String, dynamic> json) => ThreadItem(
        id: json['id']?.toString(),
        type: json['type']?.toString(),
        title: json['title']?.toString(),
        participantIds: json['participant_ids'] is List
            ? (json['participant_ids'] as List)
                .map((x) => x is int ? x : int.tryParse('$x'))
                .whereType<int>()
                .toList()
            : const [],
        description: json['description'],
        adminId: json['admin_id'],
        avatarUrl: json['avatar_url'],
        groupAvatarColor: json['group_avatar_color'],
        unreadCount: _asInt(json['unread_count']),
        isGroupAdmin: json['is_group_admin'] == true,
        lastMessage: json['last_message'] is Map<String, dynamic>
            ? ThreadLastMessage.fromJson(
                json['last_message'] as Map<String, dynamic>,
              )
            : null,
        updatedAt: _asDate(json['updated_at']),
        createdAt: _asDate(json['created_at']),
        participants: json['participants'] is List
            ? (json['participants'] as List)
                .whereType<Map>()
                .map(
                  (x) => ThreadParticipant.fromJson(
                    Map<String, dynamic>.from(x),
                  ),
                )
                .toList()
            : const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'participant_ids': participantIds,
        'description': description,
        'admin_id': adminId,
        'avatar_url': avatarUrl,
        'group_avatar_color': groupAvatarColor,
        'unread_count': unreadCount,
        'is_group_admin': isGroupAdmin,
        'last_message': lastMessage?.toJson(),
        'updated_at': updatedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'participants': participants?.map((x) => x.toJson()).toList(),
      };
}

class ThreadLastMessage {
  String? id;
  String? threadId;
  int? senderId;
  String? senderName;
  String? text;
  DateTime? sentAt;
  String? status;
  dynamic mediaPath;
  bool? isVideo;
  dynamic mediaDuration;
  bool? isSystem;
  bool? isMine;

  ThreadLastMessage({
    this.id,
    this.threadId,
    this.senderId,
    this.senderName,
    this.text,
    this.sentAt,
    this.status,
    this.mediaPath,
    this.isVideo,
    this.mediaDuration,
    this.isSystem,
    this.isMine,
  });

  factory ThreadLastMessage.fromJson(Map<String, dynamic> json) =>
      ThreadLastMessage(
        id: json['id']?.toString(),
        threadId: json['thread_id']?.toString(),
        senderId: _asInt(json['sender_id']),
        senderName: json['sender_name']?.toString(),
        text: json['text']?.toString(),
        sentAt: _asDate(json['sent_at']),
        status: json['status']?.toString(),
        mediaPath: json['media_path'],
        isVideo: json['is_video'] == true,
        mediaDuration: json['media_duration'],
        isSystem: json['is_system'] == true,
        isMine: json['is_mine'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'thread_id': threadId,
        'sender_id': senderId,
        'sender_name': senderName,
        'text': text,
        'sent_at': sentAt?.toIso8601String(),
        'status': status,
        'media_path': mediaPath,
        'is_video': isVideo,
        'media_duration': mediaDuration,
        'is_system': isSystem,
        'is_mine': isMine,
      };
}

class ThreadParticipant {
  int? id;
  String? name;
  String? avatarUrl;
  bool? isOnline;
  dynamic lastSeen;

  ThreadParticipant({
    this.id,
    this.name,
    this.avatarUrl,
    this.isOnline,
    this.lastSeen,
  });

  factory ThreadParticipant.fromJson(Map<String, dynamic> json) =>
      ThreadParticipant(
        id: _asInt(json['id']),
        name: json['name']?.toString(),
        avatarUrl: json['avatar_url']?.toString(),
        isOnline: json['is_online'] == true || json['is_online'] == 1,
        lastSeen: json['last_seen'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        'is_online': isOnline,
        'last_seen': lastSeen,
      };
}

class ThreadPagination {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  int? from;
  int? to;
  dynamic prevPageUrl;
  dynamic nextPageUrl;

  ThreadPagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
    this.prevPageUrl,
    this.nextPageUrl,
  });

  factory ThreadPagination.fromJson(Map<String, dynamic> json) =>
      ThreadPagination(
        currentPage: _asInt(json['current_page']),
        lastPage: _asInt(json['last_page']),
        perPage: _asInt(json['per_page']),
        total: _asInt(json['total']),
        from: _asInt(json['from']),
        to: _asInt(json['to']),
        prevPageUrl: json['prev_page_url'],
        nextPageUrl: json['next_page_url'],
      );

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
  return int.tryParse('$value');
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  if (raw.isEmpty || raw == 'null') return null;
  return DateTime.tryParse(raw);
}
