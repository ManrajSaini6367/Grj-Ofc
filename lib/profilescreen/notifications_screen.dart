import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/getlistnotificationmodal.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  int? _apiUnreadCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  int get _unreadCount =>
      _apiUnreadCount ?? _items.where((n) => !n.isRead).length;

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner && mounted) setState(() => _loading = true);
    final result = await getListNotificationApi(context, perPage: 50);
    if (!mounted) return;
    final items = result?.items ?? const <NotificationListItem>[];
    setState(() {
      _items = items.map(_fromApiItem).toList();
      _apiUnreadCount = result?.unreadCount;
      _loading = false;
    });
  }

  AppNotification _fromApiItem(NotificationListItem item) {
    return AppNotification(
      id: '${item.id ?? 0}',
      title: (item.title ?? '').trim().isEmpty ? 'Notification' : item.title!,
      body: item.text ?? '',
      timeLabel: _timeLabel(item.createdAt),
      icon: _iconForType(item.type, item.module, item.icon),
      isRead: item.isRead == true,
    );
  }

  Future<void> _markAllRead() async {
    final unread = _items.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    setState(() {
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
      _apiUnreadCount = 0;
    });

    final ok = await markAllNotificationsReadApi(context);
    if (!mounted || ok) return;

    setState(() {
      _items = _items
          .map(
            (n) => unread.any((u) => u.id == n.id)
                ? n.copyWith(isRead: false)
                : n,
          )
          .toList();
      _apiUnreadCount = _items.where((n) => !n.isRead).length;
    });
  }

  Future<void> _openNotification(AppNotification item) async {
    if (!item.isRead) {
      setState(() {
        final index = _items.indexWhere((n) => n.id == item.id);
        if (index != -1) {
          _items[index] = item.copyWith(isRead: true);
        }
        if (_apiUnreadCount != null && _apiUnreadCount! > 0) {
          _apiUnreadCount = _apiUnreadCount! - 1;
        }
      });
      final ok = await markNotificationReadApi(
        context,
        notificationId: item.id,
        showError: false,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() {
          final index = _items.indexWhere((n) => n.id == item.id);
          if (index != -1) {
            _items[index] = item.copyWith(isRead: false);
          }
          if (_apiUnreadCount != null) {
            _apiUnreadCount = _apiUnreadCount! + 1;
          }
        });
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(notification: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Notifications',
              useShellPop: true,
              horizontalPadding: 20,
              actions: [
                if (_unreadCount > 0)
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text(
                      'Mark all',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () => _load(showSpinner: false),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          Text(
                            'Recent',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.headingBlack,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_items.isEmpty)
                            _emptyState()
                          else
                            ..._items.map(_buildNotificationTile),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: item.isRead
            ? AppColors.cardWhite
            : AppColors.primaryRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _openNotification(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: AppColors.primaryRed, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: AppColors.headingBlack,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (item.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.body,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        item.timeLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      timeLabel: timeLabel,
      icon: icon,
      isRead: isRead ?? this.isRead,
    );
  }
}

IconData _iconForType(String? type, [String? module, String? icon]) {
  final value = '${icon ?? ''} ${type ?? ''} ${module ?? ''}'.toLowerCase();
  if (value.contains('task')) return Icons.task_alt_outlined;
  if (value.contains('purchase')) return Icons.shopping_cart_outlined;
  if (value.contains('punch') || value.contains('attendance')) {
    return Icons.access_time_rounded;
  }
  if (value.contains('stock') || value.contains('item')) {
    return Icons.inventory_2_outlined;
  }
  if (value.contains('leave')) return Icons.event_busy_outlined;
  if (value.contains('kyc')) return Icons.badge_outlined;
  return Icons.notifications_outlined;
}

String _timeLabel(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
  }
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return DateFormat('dd MMM yyyy').format(local);
}

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key, required this.notification});

  final AppNotification notification;

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late AppNotification _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _item = widget.notification;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await getNotificationApi(
      context,
      notificationId: widget.notification.id,
    );
    if (!mounted) return;
    final data = result?.data;
    setState(() {
      if (data != null) {
        _item = AppNotification(
          id: '${data.id ?? widget.notification.id}',
          title: (data.title ?? '').trim().isEmpty
              ? widget.notification.title
              : data.title!,
          body: data.text ?? widget.notification.body,
          timeLabel: _timeLabel(data.createdAt).isEmpty
              ? widget.notification.timeLabel
              : _timeLabel(data.createdAt),
          icon: _iconForType(data.type, data.module, data.icon),
          isRead: data.isRead ?? widget.notification.isRead,
        );
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Notification',
              useShellPop: true,
              horizontalPadding: 20,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.borderGray.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRed
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _item.icon,
                                      color: AppColors.primaryRed,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _item.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.headingBlack,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _item.timeLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (_item.body.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _item.body,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: AppColors.headingBlack,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
