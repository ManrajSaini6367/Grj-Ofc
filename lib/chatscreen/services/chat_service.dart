import 'package:flutter/material.dart';
import 'package:grjoffice_apps/chatmodalsclasses/createopendirectmodal.dart';
import 'package:grjoffice_apps/chatmodalsclasses/getchatlistmodal.dart';
import 'package:grjoffice_apps/chatmodalsclasses/getlistmessagesmodal.dart';
import 'package:grjoffice_apps/chatmodalsclasses/showthreadmodal.dart';
import 'package:grjoffice_apps/chatmodalsclasses/threadchatmodal.dart';
import 'package:grjoffice_apps/chatscreen/models/chat_models.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

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
  Timer? _messagePollTimer;
  String? _pollingThreadId;
  bool _syncingMessages = false;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get isInitialized => _initialized;
  bool get isLoadingMessages => _loadingMessages;
  String? get pollingThreadId => _pollingThreadId;

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
          avatarUrl: _resolveAvatar(item.avatarUrl),
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
          avatarUrl: _resolveAvatar(p.avatarUrl),
          isOnline: p.isOnline ?? false,
          lastSeen: _parseLastSeen(p.lastSeen),
        );
      }

      final isGroup = (item.type ?? '').toLowerCase() == 'group';
      final messages = <ChatMessage>[];
      final last = item.lastMessage;
      if (last != null && (last.id ?? '').isNotEmpty) {
        final lastMedia = () {
          final url = last.mediaUrl?.trim();
          if (url != null && url.isNotEmpty && url != 'null') return url;
          final path = last.mediaPath?.toString().trim();
          if (path == null || path.isEmpty || path == 'null') return null;
          final resolved = mediaUrl(path);
          return resolved.isEmpty ? path : resolved;
        }();
        messages.add(
          ChatMessage(
            id: last.id!,
            threadId: last.threadId ?? threadId,
            senderId: last.senderId ?? 0,
            text: last.text ?? '',
            sentAt: last.sentAt ?? item.updatedAt ?? DateTime.now(),
            status: _mapStatus(last.status),
            mediaPath: lastMedia,
            isVideo: last.isVideo ??
                ((last.type ?? '').toLowerCase() == 'video'),
            mediaDuration: _parseDuration(last.mediaDuration),
          ),
        );
      }

      final avatar = _resolveAvatar(item.avatarUrl);
      _threads.add(
        ChatThread(
          id: threadId,
          type: isGroup ? ChatThreadType.group : ChatThreadType.direct,
          title: (item.title ?? '').trim().isEmpty
              ? (isGroup ? 'Group' : 'Chat')
              : item.title!.trim(),
          participantIds: List<int>.from(item.participantIds ?? const []),
          messages: messages,
          avatarUrl: avatar,
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

  String? _resolveAvatar(dynamic value) {
    final url = mediaUrl(value?.toString());
    return url.isEmpty ? null : url;
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

  /// Loads single thread details (title, members, admin, etc.).
  Future<void> loadThreadDetails(String threadId) async {
    try {
      final result = await showThreadApi(threadId);
      if (result == null || result.success != true || result.data == null) {
        return;
      }
      _applyShowThread(result.data!);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatService] loadThreadDetails error: $e');
    }
  }

  void _applyShowThread(ShowThreadData item) {
    final threadId = (item.id ?? '').trim();
    if (threadId.isEmpty) return;

    for (final p in item.participants ?? const <ShowThreadParticipant>[]) {
      final pid = p.id;
      if (pid == null) continue;
      _users[pid] = ChatUser(
        id: pid,
        name: (p.name ?? '').trim().isEmpty ? 'User' : p.name!.trim(),
        avatarUrl: _resolveAvatar(p.avatarUrl),
        isOnline: p.isOnline ?? false,
        lastSeen: _parseLastSeen(p.lastSeen),
      );
    }

    final isGroup = (item.type ?? '').toLowerCase() == 'group';
    final title = (item.title ?? '').trim().isEmpty
        ? (isGroup ? 'Group' : 'Chat')
        : item.title!.trim();
    final avatar = _resolveAvatar(item.avatarUrl);
    final participantIds = List<int>.from(item.participantIds ?? const []);

    final existing = threadById(threadId);
    if (existing != null) {
      existing.title = title;
      existing.participantIds = participantIds;
      existing.avatarUrl = avatar;
      existing.description = item.description?.toString();
      existing.adminId = _asInt(item.adminId);
      existing.groupAvatarColor = _parseColor(item.groupAvatarColor);
      existing.unreadCount = item.unreadCount ?? existing.unreadCount;
      return;
    }

    _threads.add(
      ChatThread(
        id: threadId,
        type: isGroup ? ChatThreadType.group : ChatThreadType.direct,
        title: title,
        participantIds: participantIds,
        messages: [],
        avatarUrl: avatar,
        description: item.description?.toString(),
        adminId: _asInt(item.adminId),
        groupAvatarColor: _parseColor(item.groupAvatarColor),
        unreadCount: item.unreadCount ?? 0,
      ),
    );
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

  /// Starts polling while a conversation is open (WhatsApp-style live updates).
  void startMessagePolling(
    String threadId, {
    Duration interval = const Duration(seconds: 2),
  }) {
    if (_pollingThreadId == threadId && _messagePollTimer != null) return;
    stopMessagePolling();
    _pollingThreadId = threadId;
    _messagePollTimer = Timer.periodic(interval, (_) {
      unawaited(syncMessages(threadId));
    });
  }

  void stopMessagePolling() {
    _messagePollTimer?.cancel();
    _messagePollTimer = null;
    _pollingThreadId = null;
  }

  /// Quietly merges latest server messages into the open thread.
  Future<bool> syncMessages(String threadId, {int perPage = 50}) async {
    if (_syncingMessages) return false;
    final thread = threadById(threadId);
    if (thread == null) return false;

    _syncingMessages = true;
    try {
      final result = await getListMessageApi(
        chatThreadId: threadId,
        perPage: perPage,
      );
      if (result == null || result.success != true) return false;

      final serverMessages = (result.data?.items ?? const <MessageItem>[])
          .map(_mapApiMessage)
          .whereType<ChatMessage>()
          .toList();

      final previousIds = thread.messages.map((m) => m.id).toSet();
      final previousFingerprint = _messagesFingerprint(thread.messages);
      final merged = _mergeMessages(thread.messages, serverMessages);
      final nextFingerprint = _messagesFingerprint(merged);

      if (previousFingerprint == nextFingerprint) return false;

      thread.messages
        ..clear()
        ..addAll(merged);

      final hasNewFromOthers = merged.any(
        (m) => !previousIds.contains(m.id) && m.senderId != currentUserId,
      );

      notifyListeners();

      if (hasNewFromOthers) {
        unawaited(markThreadRead(threadId));
      }
      return true;
    } catch (e) {
      debugPrint('[ChatService] syncMessages error: $e');
      return false;
    } finally {
      _syncingMessages = false;
    }
  }

  String _messagesFingerprint(List<ChatMessage> messages) {
    return messages
        .map((m) => '${m.id}:${m.status.index}:${m.text}:${m.mediaPath ?? ''}')
        .join('|');
  }

  /// Keeps optimistic local messages until the same content appears from API.
  /// Also preserves local media files when server returns null media_path.
  List<ChatMessage> _mergeMessages(
    List<ChatMessage> local,
    List<ChatMessage> server,
  ) {
    final localMedia = local.where((m) => m.hasMedia).toList();

    final byId = <String, ChatMessage>{};
    for (final serverMsg in server) {
      var merged = serverMsg;
      if (!serverMsg.hasMedia && localMedia.isNotEmpty) {
        final match = _findLocalMediaMatch(localMedia, serverMsg);
        if (match != null) {
          merged = ChatMessage(
            id: serverMsg.id,
            threadId: serverMsg.threadId,
            senderId: serverMsg.senderId,
            text: serverMsg.text,
            sentAt: serverMsg.sentAt,
            status: serverMsg.status,
            mediaPath: match.mediaPath,
            isVideo: match.isVideo || serverMsg.isVideo,
            mediaDuration: serverMsg.mediaDuration ?? match.mediaDuration,
          );
          if (match.mediaPath != null) {
            unawaited(_cacheLocalMediaPath(serverMsg.id, match.mediaPath!));
          }
        }
      }
      byId[merged.id] = merged;
    }

    for (final pending in local) {
      if (!pending.id.startsWith('m_')) continue;
      final alreadyOnServer = server.any(
        (s) => _isLikelySameMessage(pending, s) &&
            (!pending.hasMedia || s.hasMedia),
      );
      if (!alreadyOnServer) {
        byId[pending.id] = pending;
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return merged;
  }

  ChatMessage? _findLocalMediaMatch(
    List<ChatMessage> localMedia,
    ChatMessage serverMsg,
  ) {
    for (final local in localMedia) {
      if (!_isLikelySameMessage(local, serverMsg)) continue;
      return local;
    }
    return null;
  }

  bool _isLikelySameMessage(ChatMessage a, ChatMessage b) {
    if (a.senderId != b.senderId) return false;
    if (a.sentAt.difference(b.sentAt).abs().inSeconds > 180) return false;
    if (a.text.isNotEmpty && b.text.isNotEmpty && a.text == b.text) {
      return true;
    }
    if (a.isVideo &&
        (b.isVideo || b.mediaDuration != null) &&
        a.mediaDuration != null &&
        b.mediaDuration != null &&
        a.mediaDuration!.inSeconds == b.mediaDuration!.inSeconds) {
      return true;
    }
    return a.hasMedia && b.hasMedia && a.isVideo == b.isVideo;
  }

  String _localMediaPrefKey(String messageId) => 'chat_local_media_$messageId';

  Future<void> _cacheLocalMediaPath(String messageId, String path) async {
    try {
      await Preference.pref.setString(_localMediaPrefKey(messageId), path);
    } catch (e) {
      debugPrint('[ChatService] cache local media failed: $e');
    }
  }

  String? _cachedLocalMediaPath(String messageId) {
    try {
      return Preference.pref.getString(_localMediaPrefKey(messageId));
    } catch (_) {
      return null;
    }
  }

  Future<String> _persistMediaFile(String sourcePath, {required bool isVideo}) async {
    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;
    final dir = await getApplicationDocumentsDirectory();
    final chatDir = Directory('${dir.path}/chat_media');
    if (!await chatDir.exists()) {
      await chatDir.create(recursive: true);
    }
    final ext = isVideo
        ? 'mp4'
        : (sourcePath.toLowerCase().endsWith('.png')
            ? 'png'
            : sourcePath.toLowerCase().endsWith('.webp')
                ? 'webp'
                : 'jpg');
    final dest = File(
      '${chatDir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await source.copy(dest.path);
    return dest.path;
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

    String? mediaPath;
    final rawUrl = item.mediaUrl?.trim();
    final rawPath = item.mediaPath?.toString().trim();
    if (rawUrl != null && rawUrl.isNotEmpty && rawUrl != 'null') {
      mediaPath = rawUrl;
    } else if (rawPath != null && rawPath.isNotEmpty && rawPath != 'null') {
      final resolved = mediaUrl(rawPath);
      mediaPath = resolved.isEmpty ? rawPath : resolved;
    } else {
      // Fallback to device cache if server has no media yet.
      final cached = _cachedLocalMediaPath(id);
      if (cached != null && cached.isNotEmpty && File(cached).existsSync()) {
        mediaPath = cached;
      }
    }

    final type = (item.type ?? '').toLowerCase();
    final isVideo = item.isVideo == true ||
        type == 'video' ||
        (mediaPath != null && mediaPath.toLowerCase().endsWith('.mp4'));

    return ChatMessage(
      id: id,
      threadId: item.threadId ?? '',
      senderId: item.senderId ?? 0,
      text: item.text ?? '',
      sentAt: item.sentAt ?? DateTime.now(),
      status: _mapStatus(item.status),
      mediaPath: mediaPath,
      isVideo: isVideo,
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
        ok ? MessageDeliveryStatus.sent : MessageDeliveryStatus.failed;
    notifyListeners();

    if (ok) {
      // Pull server copy so both devices stay in sync quickly.
      unawaited(syncMessages(threadId));
    }
  }

  Future<bool> sendMediaMessage(
    String threadId, {
    required String mediaPath,
    required bool isVideo,
    Duration? duration,
    String caption = '',
  }) async {
    final thread = threadById(threadId);
    if (thread == null) return false;

    _error = null;

    // Keep a durable copy so reopen still shows media if server path is null.
    final persistedPath = await _persistMediaFile(
      mediaPath,
      isVideo: isVideo,
    );

    final tempId = 'm_${DateTime.now().millisecondsSinceEpoch}';
    final message = ChatMessage(
      id: tempId,
      threadId: threadId,
      senderId: currentUserId,
      text: caption.trim().isNotEmpty
          ? caption.trim()
          : (isVideo ? 'Video' : 'Photo'),
      sentAt: DateTime.now(),
      status: MessageDeliveryStatus.sending,
      mediaPath: persistedPath,
      isVideo: isVideo,
      mediaDuration: duration,
    );
    thread.messages.add(message);
    notifyListeners();

    ChatMediaSendResult result;
    if (isVideo) {
      final seconds = (duration?.inSeconds ?? 1).clamp(1, 120);
      result = await sendVideoMessageApi(
        threadId: threadId,
        text: caption.trim(),
        mediaDuration: '$seconds',
        videoFile: File(persistedPath),
      );
    } else {
      result = await sendPhotoMessageApi(
        threadId: threadId,
        text: caption.trim(),
        photoFile: File(persistedPath),
      );
    }

    final index = thread.messages.indexWhere((m) => m.id == tempId);
    if (index < 0) return false;

    if (!result.success) {
      // Keep local preview so user can see what failed to upload.
      thread.messages[index] = ChatMessage(
        id: result.messageId?.trim().isNotEmpty == true
            ? result.messageId!.trim()
            : tempId,
        threadId: threadId,
        senderId: currentUserId,
        text: message.text,
        sentAt: message.sentAt,
        status: MessageDeliveryStatus.failed,
        mediaPath: persistedPath,
        isVideo: isVideo,
        mediaDuration: duration,
      );
      _error = result.errorMessage;
      notifyListeners();
      return false;
    }

    final serverId = result.messageId?.trim();
    final serverMedia = result.hasServerMedia
        ? (mediaUrl(result.mediaPath).isEmpty
            ? result.mediaPath
            : mediaUrl(result.mediaPath))
        : null;
    final displayPath = serverMedia ?? persistedPath;
    final finalId =
        (serverId != null && serverId.isNotEmpty) ? serverId : tempId;

    if (serverId != null && serverId.isNotEmpty) {
      await _cacheLocalMediaPath(serverId, persistedPath);
    }

    thread.messages[index] = ChatMessage(
      id: finalId,
      threadId: threadId,
      senderId: currentUserId,
      text: message.text,
      sentAt: message.sentAt,
      status: MessageDeliveryStatus.sent,
      mediaPath: displayPath,
      isVideo: isVideo || result.isVideo,
      mediaDuration: duration ??
          (result.mediaDuration != null
              ? Duration(seconds: result.mediaDuration!)
              : null),
    );
    notifyListeners();

    unawaited(syncMessages(threadId));
    return true;
  }

  /// Creates or opens a 1:1 direct thread with [userId].
  Future<({ChatThread? thread, String message, bool success})>
      openOrCreateDirectChat(int userId) async {
    try {
      final result = await createOpenDirectApi(userId);
      if (result == null || result.success != true || result.data == null) {
        return (
          thread: null,
          message: result?.message?.trim().isNotEmpty == true
              ? result!.message!
              : 'Failed to open chat. Please try again.',
          success: false,
        );
      }

      final thread = _applyDirectThread(result.data!);
      notifyListeners();
      unawaited(loadChatList(search: _lastSearch));

      return (
        thread: thread,
        message: result.message?.trim().isNotEmpty == true
            ? result.message!
            : 'Chat opened',
        success: thread != null,
      );
    } catch (e) {
      debugPrint('[ChatService] openOrCreateDirectChat error: $e');
      return (
        thread: null,
        message: 'Failed to open chat. Please try again.',
        success: false,
      );
    }
  }

  ChatThread? _applyDirectThread(DirectThreadData item) {
    final threadId = (item.id ?? '').trim();
    if (threadId.isEmpty) return null;

    for (final p in item.participants ?? const <DirectParticipant>[]) {
      final pid = p.id;
      if (pid == null) continue;
      _users[pid] = ChatUser(
        id: pid,
        name: (p.name ?? '').trim().isEmpty ? 'User' : p.name!.trim(),
        avatarUrl: _resolveAvatar(p.avatarUrl),
        isOnline: p.isOnline ?? false,
        lastSeen: _parseLastSeen(p.lastSeen),
      );
    }

    final title = (item.title ?? '').trim().isEmpty
        ? 'Chat'
        : item.title!.trim();
    final avatar = _resolveAvatar(item.avatarUrl);
    final participantIds = List<int>.from(item.participantIds ?? const []);

    final existing = threadById(threadId);
    if (existing != null) {
      existing.title = title;
      existing.participantIds = participantIds;
      existing.avatarUrl = avatar;
      existing.description = item.description?.toString();
      existing.adminId = _asInt(item.adminId);
      existing.groupAvatarColor = _parseColor(item.groupAvatarColor);
      existing.unreadCount = item.unreadCount ?? existing.unreadCount;
      return existing;
    }

    final thread = ChatThread(
      id: threadId,
      type: ChatThreadType.direct,
      title: title,
      participantIds: participantIds,
      messages: [],
      avatarUrl: avatar,
      description: item.description?.toString(),
      adminId: _asInt(item.adminId),
      groupAvatarColor: _parseColor(item.groupAvatarColor),
      unreadCount: item.unreadCount ?? 0,
    );
    _threads.insert(0, thread);
    return thread;
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
      avatarUrl: _resolveAvatar(data?['avatar_url']?.toString()),
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
