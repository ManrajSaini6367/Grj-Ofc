import 'dart:convert';

Getlistmessagemodal getlistmessagemodal(String str) =>
    Getlistmessagemodal.fromJson(json.decode(str) as Map<String, dynamic>);

String getlistmessagemodalToJson(Getlistmessagemodal data) =>
    json.encode(data.toJson());

class Getlistmessagemodal {
  bool? success;
  String? message;
  MessageListData? data;

  Getlistmessagemodal({
    this.success,
    this.message,
    this.data,
  });

  factory Getlistmessagemodal.fromJson(Map<String, dynamic> json) =>
      Getlistmessagemodal(
        success: json['success'] as bool?,
        message: json['message']?.toString(),
        data: json['data'] is Map<String, dynamic>
            ? MessageListData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
      };
}

class MessageListData {
  String? threadId;
  List<MessageItem>? items;
  MessagePagination? pagination;

  MessageListData({
    this.threadId,
    this.items,
    this.pagination,
  });

  factory MessageListData.fromJson(Map<String, dynamic> json) =>
      MessageListData(
        threadId: json['thread_id']?.toString(),
        items: json['items'] is List
            ? (json['items'] as List)
                .whereType<Map>()
                .map((x) => MessageItem.fromJson(Map<String, dynamic>.from(x)))
                .toList()
            : const [],
        pagination: json['pagination'] is Map<String, dynamic>
            ? MessagePagination.fromJson(
                json['pagination'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'thread_id': threadId,
        'items': items?.map((x) => x.toJson()).toList(),
        'pagination': pagination?.toJson(),
      };
}

class MessageItem {
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

  MessageItem({
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

  factory MessageItem.fromJson(Map<String, dynamic> json) => MessageItem(
        id: json['id']?.toString(),
        threadId: json['thread_id']?.toString(),
        senderId: json['sender_id'] is int
            ? json['sender_id'] as int
            : int.tryParse('${json['sender_id']}'),
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

class MessagePagination {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  int? from;
  int? to;
  dynamic prevPageUrl;
  dynamic nextPageUrl;

  MessagePagination({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
    this.prevPageUrl,
    this.nextPageUrl,
  });

  factory MessagePagination.fromJson(Map<String, dynamic> json) =>
      MessagePagination(
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
