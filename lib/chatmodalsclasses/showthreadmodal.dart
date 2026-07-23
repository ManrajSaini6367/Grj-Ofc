import 'dart:convert';

Showthreadmodaldata showthreadmodaldata(String str) =>
    Showthreadmodaldata.fromJson(json.decode(str) as Map<String, dynamic>);

String showthreadmodaldataToJson(Showthreadmodaldata data) =>
    json.encode(data.toJson());

class Showthreadmodaldata {
  bool? success;
  String? message;
  ShowThreadData? data;

  Showthreadmodaldata({
    this.success,
    this.message,
    this.data,
  });

  factory Showthreadmodaldata.fromJson(Map<String, dynamic> json) =>
      Showthreadmodaldata(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? ShowThreadData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class ShowThreadData {
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
  ShowThreadLastMessage? lastMessage;
  DateTime? updatedAt;
  DateTime? createdAt;
  List<ShowThreadParticipant>? participants;

  ShowThreadData({
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

  factory ShowThreadData.fromJson(Map<String, dynamic> json) => ShowThreadData(
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
            ? ShowThreadLastMessage.fromJson(
                json['last_message'] as Map<String, dynamic>,
              )
            : null,
        updatedAt: _asDate(json['updated_at']),
        createdAt: _asDate(json['created_at']),
        participants: json['participants'] is List
            ? (json['participants'] as List)
                .whereType<Map>()
                .map(
                  (x) => ShowThreadParticipant.fromJson(
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

class ShowThreadLastMessage {
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

  ShowThreadLastMessage({
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

  factory ShowThreadLastMessage.fromJson(Map<String, dynamic> json) =>
      ShowThreadLastMessage(
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

class ShowThreadParticipant {
  int? id;
  String? name;
  String? avatarUrl;
  bool? isOnline;
  dynamic lastSeen;

  ShowThreadParticipant({
    this.id,
    this.name,
    this.avatarUrl,
    this.isOnline,
    this.lastSeen,
  });

  factory ShowThreadParticipant.fromJson(Map<String, dynamic> json) =>
      ShowThreadParticipant(
        id: _asInt(json['id']),
        name: json['name']?.toString(),
        avatarUrl: json['avatar_url']?.toString(),
        isOnline: json['is_online'] == true,
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
