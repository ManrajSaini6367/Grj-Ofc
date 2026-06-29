import 'package:flutter/material.dart';

enum ChatThreadType { direct, group }

enum MessageDeliveryStatus { sending, sent, delivered, read }

class ChatUser {
  const ChatUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  final int id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.status = MessageDeliveryStatus.sent,
  });

  final String id;
  final String threadId;
  final int senderId;
  final String text;
  final DateTime sentAt;
  MessageDeliveryStatus status;

  bool isMine(int currentUserId) => senderId == currentUserId;
}

class ChatThread {
  ChatThread({
    required this.id,
    required this.type,
    required this.title,
    required this.participantIds,
    required this.messages,
    this.avatarUrl,
    this.description,
    this.adminId,
    this.groupAvatarColor,
    this.unreadCount = 0,
    this.isTyping = false,
    this.typingUserId,
  });

  final String id;
  final ChatThreadType type;
  String title;
  List<int> participantIds;
  String? avatarUrl;
  String? description;
  int? adminId;
  int? groupAvatarColor;
  int unreadCount;
  bool isTyping;
  int? typingUserId;
  final List<ChatMessage> messages;

  ChatMessage? get lastMessage =>
      messages.isEmpty ? null : messages.reduce((a, b) => a.sentAt.isAfter(b.sentAt) ? a : b);

  bool get isGroup => type == ChatThreadType.group;

  Color get groupColor => Color(groupAvatarColor ?? 0xFF8B1D1D);
}
