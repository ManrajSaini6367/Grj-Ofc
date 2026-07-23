import 'dart:convert';

Createopendirectmodaldata createopendirectmodaldata(String str) =>
    Createopendirectmodaldata.fromJson(
      json.decode(str) as Map<String, dynamic>,
    );

String createopendirectmodaldataToJson(Createopendirectmodaldata data) =>
    json.encode(data.toJson());

class Createopendirectmodaldata {
  bool? success;
  String? message;
  DirectThreadData? data;

  Createopendirectmodaldata({
    this.success,
    this.message,
    this.data,
  });

  factory Createopendirectmodaldata.fromJson(Map<String, dynamic> json) =>
      Createopendirectmodaldata(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? DirectThreadData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class DirectThreadData {
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
  dynamic lastMessage;
  DateTime? updatedAt;
  DateTime? createdAt;
  List<DirectParticipant>? participants;

  DirectThreadData({
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

  factory DirectThreadData.fromJson(Map<String, dynamic> json) =>
      DirectThreadData(
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
        lastMessage: json['last_message'],
        updatedAt: _asDate(json['updated_at']),
        createdAt: _asDate(json['created_at']),
        participants: json['participants'] is List
            ? (json['participants'] as List)
                .whereType<Map>()
                .map(
                  (x) => DirectParticipant.fromJson(
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
        'last_message': lastMessage,
        'updated_at': updatedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'participants': participants?.map((x) => x.toJson()).toList(),
      };
}

class DirectParticipant {
  int? id;
  String? name;
  String? avatarUrl;
  bool? isOnline;
  dynamic lastSeen;

  DirectParticipant({
    this.id,
    this.name,
    this.avatarUrl,
    this.isOnline,
    this.lastSeen,
  });

  factory DirectParticipant.fromJson(Map<String, dynamic> json) =>
      DirectParticipant(
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
