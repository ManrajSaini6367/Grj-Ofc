class ChatFormatters {
  ChatFormatters._();

  static String threadTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);

    if (messageDay == today) return _formatClock(time);
    if (messageDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.difference(time).inDays < 7) return _weekday(time.weekday);
    return '${time.day.toString().padLeft(2, '0')}/'
        '${time.month.toString().padLeft(2, '0')}/'
        '${(time.year % 100).toString().padLeft(2, '0')}';
  }

  static String messageTime(DateTime time) => _formatClock(time);

  static String dayLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${time.day} ${_month(time.month)} ${time.year}';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String presenceLabel({required bool isOnline, DateTime? lastSeen}) {
    if (isOnline) return 'online';
    if (lastSeen == null) return 'offline';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'last seen ${diff.inHours}h ago';
    return 'last seen ${lastSeen.day} ${_month(lastSeen.month)}';
  }

  static String _formatClock(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $period';
  }

  static String _weekday(int day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(day - 1).clamp(0, 6)];
  }

  static String _month(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
