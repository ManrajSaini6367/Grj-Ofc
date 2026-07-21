import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/services/api_auth.dart';

class ChatService extends ChangeNotifier {
  ChatService._();
  static final ChatService instance = ChatService._();

  final Map<int, ChatUser> _users = {};
  final List<ChatThread> _threads = [];
  Timer? _typingTimer;

  int get currentUserId => cachedUser()?.id ?? 1;

  List<ChatUser> get allUsers =>
      _users.values.where((u) => u.id != currentUserId).toList();

  List<ChatThread> get threads {
    final list = List<ChatThread>.from(_threads);
    list.sort((a, b) {
      final aTime = a.lastMessage?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessage?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  void initialize() {
    if (_threads.isNotEmpty) return;
    _seedUsers();
    _seedThreads();
  }

  ChatUser? userById(int id) => _users[id];

  ChatThread? threadById(String id) {
    for (final thread in _threads) {
      if (thread.id == id) return thread;
    }
    return null;
  }

  bool isGroupAdmin(ChatThread thread) =>
      thread.isGroup && thread.adminId == currentUserId;

  int onlineMembersCount(ChatThread thread) {
    return thread.participantIds
        .where((id) => _users[id]?.isOnline == true)
        .length;
  }

  List<ChatUser> groupMembers(ChatThread thread) {
    return thread.participantIds
        .map((id) => _users[id])
        .whereType<ChatUser>()
        .toList();
  }

  List<ChatUser> availableUsersToAdd(ChatThread thread) {
    return allUsers
        .where((user) => !thread.participantIds.contains(user.id))
        .toList();
  }

  void markThreadRead(String threadId) {
    final thread = threadById(threadId);
    if (thread == null) return;
    thread.unreadCount = 0;
    for (final message in thread.messages) {
      if (message.senderId != currentUserId &&
          message.status != MessageDeliveryStatus.read) {
        message.status = MessageDeliveryStatus.read;
      }
    }
    notifyListeners();
  }

  Future<void> sendMessage(String threadId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final thread = threadById(threadId);
    if (thread == null) return;

    final message = ChatMessage(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      threadId: threadId,
      senderId: currentUserId,
      text: trimmed,
      sentAt: DateTime.now(),
      status: MessageDeliveryStatus.sending,
    );
    thread.messages.add(message);
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 350));
    message.status = MessageDeliveryStatus.sent;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));
    message.status = MessageDeliveryStatus.delivered;
    notifyListeners();

    _simulateReply(thread);
  }

  Future<void> sendMediaMessage(
    String threadId, {
    required String mediaPath,
    required bool isVideo,
    Duration? duration,
  }) async {
    final thread = threadById(threadId);
    if (thread == null) return;

    final message = ChatMessage(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      threadId: threadId,
      senderId: currentUserId,
      text: isVideo ? 'Video' : 'Photo',
      sentAt: DateTime.now(),
      status: MessageDeliveryStatus.sending,
      mediaPath: mediaPath,
      isVideo: isVideo,
      mediaDuration: duration,
    );
    thread.messages.add(message);
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 350));
    message.status = MessageDeliveryStatus.sent;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));
    message.status = MessageDeliveryStatus.delivered;
    notifyListeners();
  }

  ChatThread createGroup({
    required String name,
    required List<int> memberIds,
    String? description,
    int? groupAvatarColor,
  }) {
    final participants = <int>{currentUserId, ...memberIds};
    final thread = ChatThread(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatThreadType.group,
      title: name.trim().isEmpty ? 'New Group' : name.trim(),
      participantIds: participants.toList(),
      messages: [],
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      adminId: currentUserId,
      groupAvatarColor: groupAvatarColor ?? 0xFF8B1D1D,
    );
    thread.messages.add(
      ChatMessage(
        id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
        threadId: thread.id,
        senderId: currentUserId,
        text: 'You created group "${thread.title}"',
        sentAt: DateTime.now(),
        status: MessageDeliveryStatus.read,
      ),
    );
    _threads.insert(0, thread);
    notifyListeners();
    return thread;
  }

  void addGroupMembers(String threadId, List<int> memberIds) {
    final thread = threadById(threadId);
    if (thread == null || !thread.isGroup) return;

    final added = <int>[];
    for (final id in memberIds) {
      if (!thread.participantIds.contains(id)) {
        thread.participantIds.add(id);
        added.add(id);
      }
    }
    if (added.isEmpty) return;

    final names = added.map((id) => _users[id]?.name.split(' ').first ?? 'User').join(', ');
    thread.messages.add(
      ChatMessage(
        id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
        threadId: threadId,
        senderId: currentUserId,
        text: 'You added $names',
        sentAt: DateTime.now(),
        status: MessageDeliveryStatus.read,
      ),
    );
    notifyListeners();
  }

  void removeGroupMember(String threadId, int memberId) {
    final thread = threadById(threadId);
    if (thread == null || !thread.isGroup || !isGroupAdmin(thread)) return;
    if (memberId == currentUserId) return;

    thread.participantIds.remove(memberId);
    final name = _users[memberId]?.name ?? 'Member';
    thread.messages.add(
      ChatMessage(
        id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
        threadId: threadId,
        senderId: currentUserId,
        text: 'You removed $name',
        sentAt: DateTime.now(),
        status: MessageDeliveryStatus.read,
      ),
    );
    notifyListeners();
  }

  bool leaveGroup(String threadId) {
    final thread = threadById(threadId);
    if (thread == null || !thread.isGroup) return false;

    thread.participantIds.remove(currentUserId);

    if (thread.participantIds.isEmpty) {
      _threads.removeWhere((t) => t.id == threadId);
      notifyListeners();
      return true;
    }

    if (thread.adminId == currentUserId) {
      thread.adminId = thread.participantIds.first;
    }
    notifyListeners();
    return true;
  }

  bool deleteGroup(String threadId) {
    final thread = threadById(threadId);
    if (thread == null || !thread.isGroup || !isGroupAdmin(thread)) return false;
    _threads.removeWhere((t) => t.id == threadId);
    notifyListeners();
    return true;
  }

  void _simulateReply(ChatThread thread) {
    if (thread.isGroup) {
      final others = thread.participantIds.where((id) => id != currentUserId).toList();
      if (others.isEmpty) return;
      final replierId = others.first;
      _showTyping(thread, replierId);
      Future<void>.delayed(const Duration(milliseconds: 1800), () {
        _clearTyping(thread);
        final reply = ChatMessage(
          id: 'm_${DateTime.now().millisecondsSinceEpoch}',
          threadId: thread.id,
          senderId: replierId,
          text: _groupReplies[DateTime.now().millisecond % _groupReplies.length],
          sentAt: DateTime.now(),
          status: MessageDeliveryStatus.delivered,
        );
        thread.messages.add(reply);
        thread.unreadCount += 1;
        notifyListeners();
      });
      return;
    }

    final peerId = thread.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
    _showTyping(thread, peerId);
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      _clearTyping(thread);
      final lastMine = thread.messages.lastWhere(
        (m) => m.senderId == currentUserId,
        orElse: () => thread.messages.last,
      );
      lastMine.status = MessageDeliveryStatus.read;

      final reply = ChatMessage(
        id: 'm_${DateTime.now().millisecondsSinceEpoch}',
        threadId: thread.id,
        senderId: peerId,
        text: _directReplies[DateTime.now().millisecond % _directReplies.length],
        sentAt: DateTime.now(),
        status: MessageDeliveryStatus.delivered,
      );
      thread.messages.add(reply);
      thread.unreadCount += 1;
      notifyListeners();
    });
  }

  void _showTyping(ChatThread thread, int userId) {
    thread.isTyping = true;
    thread.typingUserId = userId;
    notifyListeners();
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 8), () => _clearTyping(thread));
  }

  void _clearTyping(ChatThread thread) {
    thread.isTyping = false;
    thread.typingUserId = null;
    notifyListeners();
  }

  void _seedUsers() {
    final me = cachedUser();
    _users[currentUserId] = ChatUser(
      id: currentUserId,
      name: me?.name ?? 'You',
      isOnline: true,
    );

    const seeds = [
      ChatUser(id: 2, name: 'Rahul Sharma', isOnline: true),
      ChatUser(id: 3, name: 'Priya Verma', isOnline: true),
      ChatUser(id: 4, name: 'Amit Patel', isOnline: false, lastSeen: null),
      ChatUser(id: 5, name: 'Site Manager', isOnline: true),
      ChatUser(id: 6, name: 'Anita Singh', isOnline: false),
      ChatUser(id: 7, name: 'Vikram Mehta', isOnline: true),
    ];

    for (final user in seeds) {
      _users[user.id] = user.id == 4 || user.id == 6
          ? ChatUser(
              id: user.id,
              name: user.name,
              isOnline: user.isOnline,
              lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
            )
          : user;
    }
  }

  void _seedThreads() {
    final now = DateTime.now();
    final admin = currentUserId;

    _threads.addAll([
      ChatThread(
        id: 'd_1',
        type: ChatThreadType.direct,
        title: 'Rahul Sharma',
        participantIds: [currentUserId, 2],
        unreadCount: 2,
        messages: [
          ChatMessage(
            id: 'm1',
            threadId: 'd_1',
            senderId: 2,
            text: 'Good morning! Is the cement delivery confirmed for today?',
            sentAt: now.subtract(const Duration(hours: 2, minutes: 10)),
            status: MessageDeliveryStatus.read,
          ),
          ChatMessage(
            id: 'm2',
            threadId: 'd_1',
            senderId: currentUserId,
            text: 'Yes, supplier confirmed 10 AM arrival at Site A.',
            sentAt: now.subtract(const Duration(hours: 2)),
            status: MessageDeliveryStatus.read,
          ),
          ChatMessage(
            id: 'm3',
            threadId: 'd_1',
            senderId: 2,
            text: 'Perfect. I will update the store team.',
            sentAt: now.subtract(const Duration(minutes: 18)),
            status: MessageDeliveryStatus.delivered,
          ),
        ],
      ),
      ChatThread(
        id: 'g_1',
        type: ChatThreadType.group,
        title: 'River Crossing Site',
        participantIds: [currentUserId, 2, 3, 5],
        adminId: admin,
        description: 'Site coordination and daily updates.',
        groupAvatarColor: 0xFF8B1D1D,
        unreadCount: 5,
        messages: [
          ChatMessage(
            id: 'g_m1',
            threadId: 'g_1',
            senderId: 5,
            text: 'Team, please submit day-end reports before 7 PM.',
            sentAt: now.subtract(const Duration(hours: 4)),
            status: MessageDeliveryStatus.read,
          ),
          ChatMessage(
            id: 'g_m2',
            threadId: 'g_1',
            senderId: 3,
            text: 'Store inventory count is completed.',
            sentAt: now.subtract(const Duration(hours: 1, minutes: 20)),
            status: MessageDeliveryStatus.delivered,
          ),
          ChatMessage(
            id: 'g_m3',
            threadId: 'g_1',
            senderId: 2,
            text: 'Labour attendance sheet uploaded.',
            sentAt: now.subtract(const Duration(minutes: 42)),
            status: MessageDeliveryStatus.delivered,
          ),
        ],
      ),
      ChatThread(
        id: 'd_2',
        type: ChatThreadType.direct,
        title: 'Priya Verma',
        participantIds: [currentUserId, 3],
        unreadCount: 0,
        messages: [
          ChatMessage(
            id: 'm4',
            threadId: 'd_2',
            senderId: currentUserId,
            text: 'Please share the updated purchase list.',
            sentAt: now.subtract(const Duration(days: 1, hours: 3)),
            status: MessageDeliveryStatus.read,
          ),
          ChatMessage(
            id: 'm5',
            threadId: 'd_2',
            senderId: 3,
            text: 'Sent on email and uploaded in portal.',
            sentAt: now.subtract(const Duration(days: 1, hours: 2, minutes: 40)),
            status: MessageDeliveryStatus.read,
          ),
        ],
      ),
      ChatThread(
        id: 'g_2',
        type: ChatThreadType.group,
        title: 'Procurement Team',
        participantIds: [currentUserId, 3, 4, 6, 7],
        adminId: admin,
        description: 'Purchase orders and vendor discussions.',
        groupAvatarColor: 0xFF2563EB,
        unreadCount: 0,
        messages: [
          ChatMessage(
            id: 'g_m4',
            threadId: 'g_2',
            senderId: 7,
            text: 'New vendor quotation received for steel supply.',
            sentAt: now.subtract(const Duration(days: 2)),
            status: MessageDeliveryStatus.read,
          ),
        ],
      ),
      ChatThread(
        id: 'd_3',
        type: ChatThreadType.direct,
        title: 'Amit Patel',
        participantIds: [currentUserId, 4],
        unreadCount: 1,
        messages: [
          ChatMessage(
            id: 'm6',
            threadId: 'd_3',
            senderId: 4,
            text: 'Can we schedule a site visit tomorrow?',
            sentAt: now.subtract(const Duration(minutes: 55)),
            status: MessageDeliveryStatus.delivered,
          ),
        ],
      ),
    ]);
  }

  static const _directReplies = [
    'Got it, thanks!',
    'I will check and update you shortly.',
    'Noted. Please proceed.',
    'Sure, that works for me.',
  ];

  static const _groupReplies = [
    'Thanks for the update everyone.',
    'Acknowledged.',
    'I will share this with my team.',
    'Please add this to the daily log.',
  ];

  static const groupAvatarOptions = <Color>[
    Color(0xFF8B1D1D),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
  ];
}
