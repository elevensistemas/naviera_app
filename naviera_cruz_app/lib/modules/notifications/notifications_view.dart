import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../../app/ncs_hero_header.dart';
import '../../core/storage.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = NotificationService();
      final list = await service.fetchNotifications();
      setState(() {
        _notifications.clear();
        _notifications.addAll(list);
      });
      final unreadCount = _notifications.where((n) => !n.isRead).length;
      SessionManager.shared.setUnreadCount(unreadCount);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _isLoading = true);
    try {
      final service = NotificationService();
      await service.markAllAsRead();
      SessionManager.shared.clearUnreadCount();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Todas las notificaciones marcadas como leídas.")),
        );
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAll() async {
    setState(() => _isLoading = true);
    try {
      final service = NotificationService();
      await service.clearAll();
      SessionManager.shared.clearUnreadCount();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Historial de notificaciones limpio.")),
        );
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markSingleRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      final service = NotificationService();
      await service.markAsRead(notification.id);
      SessionManager.shared.decrementUnreadCount();
      // Local state update for immediate feedback
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            timestamp: notification.timestamp,
            isRead: true,
          );
        }
      });
    } catch (_) {}
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return "Hace ${diff.inMinutes} m";
    } else if (diff.inHours < 24) {
      return "Hace ${diff.inHours} h";
    }
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final captionColor = isDark ? Colors.white38 : Colors.black38;
    final dividerColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF1F5F9);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NcsHeroHeader(
            title: "Notificaciones",
            subtitle: "Historial de avisos y alertas del sistema.",
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _markAllRead,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text("Marcar leídas"),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text("Limpiar"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),

          // Notification list
          Expanded(
            child: _isLoading && _notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: _notifications.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 80.0),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.notifications_off_outlined,
                                      size: 70,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage ?? "No tienes notificaciones.",
                                      style: TextStyle(color: secondaryTextColor, fontSize: 15),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              final isUnread = !notification.isRead;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                elevation: isUnread ? 1.0 : 0.0,
                                child: InkWell(
                                  onTap: () => _markSingleRead(notification),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Left Indicator Icon
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: isUnread 
                                                ? ColorTheme.primary.withOpacity(0.1) 
                                                : Colors.grey.withOpacity(0.05),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isUnread 
                                                ? Icons.notifications_active_outlined 
                                                : Icons.notifications_none_outlined,
                                            color: isUnread ? ColorTheme.primary : captionColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Notification Texts
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      notification.title,
                                                      style: TextStyle(
                                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                        fontSize: 14,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatTime(notification.timestamp),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: captionColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                notification.message,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: secondaryTextColor,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Unread dot indicator on the right
                                        if (isUnread) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(top: 4.0),
                                            decoration: const BoxDecoration(
                                              color: ColorTheme.accent, // Orange unread dot
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
