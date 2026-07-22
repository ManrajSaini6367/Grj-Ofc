import 'package:flutter/material.dart';
import 'package:grjoffice_apps/chatmodalsclasses/getchatlistmodal.dart';
import 'package:grjoffice_apps/chatmodalsclasses/getlistmessagesmodal.dart';
import 'package:grjoffice_apps/chatmodalsclasses/threadchatmodal.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'dart:async';

class ChatService extends ChangeNotifier {
  ChatService._();
  static final ChatService instance = ChatService._();

  final Map<int, ChatUser> _users = {};
  final List<ChatThread> _threads = [];

  bool _loading = false;
  String? _error;
  bool _initialized = false;
  String _lastSearch = '';
  bool _usersLoaded = false;
  bool _loadingMessages = false;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get isInitialized => _initialized;
  bool get isLoadingMessages => _loadingMessages;

  int get currentUserId => cachedUser()?.id ?? 1;

  List<ChatUser> get allUsers =>
      _users.values.where((u) => u.id != currentUserId).toList();

  List<ChatThread> get threads {
    final list = List<ChatThread>.from(_threads);
    list.sort((a, b) {
      final aTime = a.lastMessage?.sentAt;
      final bTime = b.lastMessage?.sentAt;
      if (aTime == null && bTime == null) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  /// Loads chat threads from API.
  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force && _threads.isNotEmpty) return;
    await loadChatList();
  }

  Future<void> loadChatList({String search = ''}) async {
    _loading = true;
    _error = null;
    _lastSearch = search;
    notifyListeners();

    try {
      final result = await getChatThreadListApi(search: search);
      if (result == null || result.success != true) {
        _loading = false;
        _error = result?.message?.isNotEmpty == true
            ? result!.message
            : 'Failed to load chats. Please try again.';
        _initialized = true;
        notifyListeners();
        return;
      }

      _applyThreadList(result);
      _loading = false;
      _error = null;
      _initialized = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('[ChatService] loadChatList error: $e\n$st');
      _loading = false;
      _error = 'Failed to load chats. Please try again.';
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadChatList(search: _lastSearch);

  /// Loads users for "New group" / add members (separate from thread list).
  Future<void> loadChatUsers({String search = '', bool force = false}) async {
    if (_usersLoaded && !force && search.isEmpty && allUsers.isNotEmpty) {
      return;
    }

    try {
      final result = await getChatListApi(search: search);
      if (result == null || result.success != true) return;

      final me = cachedUser();
      _users[currentUserId] = ChatUser(
        id: currentUserId,
        name: me?.name ?? 'You',
        isOnline: true,
      );

      for (final item in result.data?.items ?? const <Item>[]) {
        final id = item.id;
        if (id == null || id == currentUserId) continue;
        _users[id] = ChatUser(
          id: id,
          name: (item.name ?? '').trim().isEmpty ? 'User' : item.name!.trim(),
          avatarUrl: (item.avatarUrl ?? '').trim().isEmpty
              ? null
              : item.avatarUrl!.trim(),
          isOnline: item.isOnline ?? false,
          lastSeen: _parseLastSeen(item.lastSeen),
        );
      }
      _usersLoaded = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('[ChatService] loadChatUsers error: $e\n$st');
    }
  }

  void _applyThreadList(Getchatthreadlistmodal result) {
    final me = cachedUser();
    _users[currentUserId] = ChatUser(
      id: currentUserId,
      name: me?.name ?? 'You',
      isOnline: true,
    );

    _threads.clear();

    final items = result.data?.items ?? const <ThreadItem>[];
    for (final item in items) {
      final threadId = (item.id ?? '').trim();
      if (threadId.isEmpty) continue;

      for (final p in item.participants ?? const <ThreadParticipant>[]) {
        final pid = p.id;
        if (pid == null) continue;
        _users[pid] = ChatUser(
          id: pid,
          name: (p.name ?? '').trim().isEmpty ? 'User' : p.name!.trim(),
          avatarUrl: (p.avatarUrl ?? '').trim().isEmpty
              ? null
              : p.avatarUrl!.trim(),
          isOnline: p.isOnline ?? false,
          lastSeen: _parseLastSeen(p.lastSeen),
        );
      }

      final isGroup = (item.type ?? '').toLowerCase() == 'group';
      final messages = <ChatMessage>[];
      final last = item.lastMessage;
      if (last != null && (last.id ?? '').isNotEmpty) {
        messages.add(
          ChatMessage(
            id: last.id!,
            threadId: last.threadId ?? threadId,
            senderId: last.senderId ?? 0,
            text: last.text ?? '',
            sentAt: last.sentAt ?? item.updatedAt ?? DateTime.now(),
            status: _mapStatus(last.status),
            mediaPath: last.mediaPath?.toString(),
            isVideo: last.isVideo ?? false,
            mediaDuration: _parseDuration(last.mediaDuration),
          ),
        );
      }

      final avatar = item.avatarUrl?.toString().trim();
      _threads.add(
        ChatThread(
          id: threadId,
          type: isGroup ? ChatThreadType.group : ChatThreadType.direct,
          title: (item.title ?? '').trim().isEmpty
              ? (isGroup ? 'Group' : 'Chat')
              : item.title!.trim(),
          participantIds: List<int>.from(item.participantIds ?? const []),
          messages: messages,
          avatarUrl: (avatar == null || avatar.isEmpty) ? null : avatar,
          description: item.description?.toString(),
          adminId: _asInt(item.adminId),
          groupAvatarColor: _parseColor(item.groupAvatarColor),
          unreadCount: item.unreadCount ?? 0,
        ),
      );
    }
  }

  MessageDeliveryStatus _mapStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'sending':
        return MessageDeliveryStatus.sending;
      case 'delivered':
        return MessageDeliveryStatus.delivered;
      case 'read':
        return MessageDeliveryStatus.read;
      case 'sent':
      default:
        return MessageDeliveryStatus.sent;
    }
  }

  Duration? _parseDuration(dynamic value) {
    if (value == null) return null;
    if (value is Duration) return value;
    if (value is int) return Duration(seconds: value);
    if (value is double) return Duration(seconds: value.round());
    final asInt = int.tryParse('$value');
    if (asInt != null) return Duration(seconds: asInt);
    return null;
  }

  int? _parseColor(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('#')) {
      final hex = raw.substring(1);
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed == null) return null;
      return hex.length <= 6 ? (0xFF000000 | parsed) : parsed;
    }
    return int.tryParse(raw);
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse('$value');
  }

  DateTime? _parseLastSeen(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty || raw == 'null') return null;
    return DateTime.tryParse(raw);
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

  Future<void> markThreadRead(String threadId) async {
    final thread = threadById(threadId);
    if (thread == null) return;

    // Update UI immediately
    thread.unreadCount = 0;
    for (final message in thread.messages) {
      if (message.senderId != currentUserId &&
          message.status != MessageDeliveryStatus.read) {
        message.status = MessageDeliveryStatus.read;
      }
    }
    notifyListeners();

    // Call API in background
    await markThreadReadApi(chatThreadId: threadId);
  }

  /// Loads messages for a thread from API and replaces local list.
  Future<void> loadMessages(String threadId, {int perPage = 50}) async {
    final thread = threadById(threadId);
    if (thread == null) return;

    _loadingMessages = true;
    notifyListeners();

    try {
      final result = await getListMessageApi(
        chatThreadId: threadId,
        perPage: perPage,
      );

      if (result != null && result.success == true) {
        final items = result.data?.items ?? const <MessageItem>[];
        thread.messages
          ..clear()
          ..addAll(items.map(_mapApiMessage).whereType<ChatMessage>());

        // Oldest → newest for chat UI
        thread.messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      }
    } catch (e) {
      debugPrint('[ChatService] loadMessages error: $e');
    }

    _loadingMessages = false;
    notifyListeners();
  }

  ChatMessage? _mapApiMessage(MessageItem item) {
    final id = (item.id ?? '').trim();
    if (id.isEmpty) return null;

    Duration? duration;
    final rawDuration = item.mediaDuration;
    if (rawDuration is int) {
      duration = Duration(seconds: rawDuration);
    } else if (rawDuration != null) {
      final parsed = int.tryParse('$rawDuration');
      if (parsed != null) duration = Duration(seconds: parsed);
    }

    return ChatMessage(
      id: id,
      threadId: item.threadId ?? '',
      senderId: item.senderId ?? 0,
      text: item.text ?? '',
      sentAt: item.sentAt ?? DateTime.now(),
      status: _mapStatus(item.status),
      mediaPath: item.mediaPath?.toString(),
      isVideo: item.isVideo ?? false,
      mediaDuration: duration,
    );
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

    final ok = await sendMessageApi(
      chatThreadId: threadId,
      message: trimmed,
    );

    message.status =
        ok ? MessageDeliveryStatus.sent : MessageDeliveryStatus.sending;
    notifyListeners();
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

  /// Creates a group via API, then refreshes the thread list.
  /// Returns the created [ChatThread] on success, or null on failure.
  /// [errorMessage] is set via the returned record's message when failed.
  Future<({ChatThread? thread, String message, bool success})> createGroupOnServer({
    required String name,
    required List<int> memberIds,
    String? description,
    int? groupAvatarColor,
  }) async {
    final trimmedName = name.trim().isEmpty ? 'New Group' : name.trim();
    final trimmedDescription =
        (description ?? '').trim().isEmpty ? '' : description!.trim();
    final color = groupAvatarColor ?? 0xFF8B1D1D;

    final result = await createGroupApi(
      name: trimmedName,
      description: trimmedDescription,
      memberIds: memberIds,
      groupAvatarColor: color,
    );

    if (!result.success) {
      return (thread: null, message: result.message, success: false);
    }

    // Prefer server thread id from response data.
    final data = result.data;
    final serverId = data?['id']?.toString().trim();
    final participants = <int>{currentUserId, ...memberIds};

    final thread = ChatThread(
      id: (serverId != null && serverId.isNotEmpty)
          ? serverId
          : 'g_${DateTime.now().millisecondsSinceEpoch}',
      type: ChatThreadType.group,
      title: data?['title']?.toString().trim().isNotEmpty == true
          ? data!['title'].toString().trim()
          : trimmedName,
      participantIds: data?['participant_ids'] is List
          ? (data!['participant_ids'] as List)
              .map((x) => x is int ? x : int.tryParse('$x'))
              .whereType<int>()
              .toList()
          : participants.toList(),
      messages: [],
      description: trimmedDescription.isEmpty ? null : trimmedDescription,
      adminId: currentUserId,
      groupAvatarColor: color,
      avatarUrl: data?['avatar_url']?.toString(),
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

    _threads.removeWhere((t) => t.id == thread.id);
    _threads.insert(0, thread);
    notifyListeners();

    // Sync inbox with server threads (best-effort).
    unawaited(loadChatList(search: _lastSearch));

    return (thread: thread, message: result.message, success: true);
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
      description:
          description?.trim().isEmpty == true ? null : description?.trim(),
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

    final names =
        added.map((id) => _users[id]?.name.split(' ').first ?? 'User').join(', ');
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

  /// Adds members via API, then updates the local group.
  Future<({bool success, String message})> addGroupMembersOnServer({
    required String threadId,
    required List<int> memberIds,
  }) async {
    final thread = threadById(threadId);
    if (thread == null || !thread.isGroup) {
      return (success: false, message: 'Group not found.');
    }
    if (!isGroupAdmin(thread)) {
      return (
        success: false,
        message: 'Only the group admin can add members.',
      );
    }

    final toAdd = memberIds
        .where((id) => id != currentUserId && !thread.participantIds.contains(id))
        .toList();
    if (toAdd.isEmpty) {
      return (success: false, message: 'No new members to add.');
    }

    final result = await addGroupMembersApi(
      chatThreadId: threadId,
      memberIds: toAdd,
    );
    if (!result.success) {
      return (success: false, message: result.message);
    }

    // Local update after successful API response.
    final added = <int>[];
    for (final id in toAdd) {
      if (!thread.participantIds.contains(id)) {
        thread.participantIds.add(id);
        added.add(id);
      }
    }

    final names =
        added.map((id) => _users[id]?.name.split(' ').first ?? 'User').join(', ');
    if (added.isNotEmpty) {
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
    }
    notifyListeners();

    return (success: true, message: result.message);
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

  /// Removes a member via API, then updates the local group.
  Future<({bool success, String message})> removeGroupMemberOnServer({
    required String threadId,
    required int memberId,
  }) async {
    final thread = threadById(threadId);
    if (thread == null || !thread.isGroup) {
      return (success: false, message: 'Group not found.');
    }
    if (!isGroupAdmin(thread)) {
      return (
        success: false,
        message: 'Only the group admin can remove members.',
      );
    }
    if (memberId == currentUserId) {
      return (success: false, message: 'You cannot remove yourself.');
    }

    final result = await removeGroupMemberApi(
      chatThreadId: threadId,
      memberId: memberId,
    );
    if (!result.success) {
      return (success: false, message: result.message);
    }

    final name = _users[memberId]?.name ?? 'Member';
    thread.participantIds.remove(memberId);
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

    return (success: true, message: result.message);
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

  /// Leaves a group via API, then removes it locally from the inbox.
  Future<({bool success, String message})> leaveGroupOnServer(
    String threadId,
  ) async {
    final thread = threadById(threadId);
    if (thread == null || !thread.isGroup) {
      return (success: false, message: 'Group not found.');
    }

    final result = await leaveGroupApi(chatThreadId: threadId);
    if (!result.success) {
      return (success: false, message: result.message);
    }

    _threads.removeWhere((t) => t.id == threadId);
    notifyListeners();
    unawaited(loadChatList(search: _lastSearch));

    return (success: true, message: result.message);
  }

  /// Deletes a group via API, then removes it locally.
  Future<({bool success, String message})> deleteGroupOnServer(
    String threadId,
  ) async {
    final thread = threadById(threadId);
    if (thread == null || !thread.isGroup) {
      return (success: false, message: 'Group not found.');
    }
    if (!isGroupAdmin(thread)) {
      return (
        success: false,
        message: 'Only the group admin can delete this group.',
      );
    }

    final result = await deleteGroupApi(chatThreadId: threadId);
    if (!result.success) {
      return (success: false, message: result.message);
    }

    _threads.removeWhere((t) => t.id == threadId);
    notifyListeners();
    unawaited(loadChatList(search: _lastSearch));

    return (success: true, message: result.message);
  }

  bool deleteGroup(String threadId) {
    final thread = threadById(threadId);
    if (thread == null || !thread.isGroup || !isGroupAdmin(thread)) return false;
    _threads.removeWhere((t) => t.id == threadId);
    notifyListeners();
    return true;
  }

  static const groupAvatarOptions = <Color>[
    Color(0xFF8B1D1D),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
  ];
}
