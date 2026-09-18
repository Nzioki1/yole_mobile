import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/core_api_service.dart';
import '../l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Notifications center screen
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _api = CoreApiService();
  bool _loading = false;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final response = await _api.getNotifications();
      setState(() {
        _notifications = response['notifications'] as List<dynamic>? ?? [];
        _unreadCount = _notifications.where((n) => n['read'] == false).length;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _api.markNotificationAsRead(notificationId);
      setState(() {
        final notification = _notifications.firstWhere(
          (n) => n['id'] == notificationId,
          orElse: () => null,
        );
        if (notification != null) {
          notification['read'] = true;
          _unreadCount = _notifications.where((n) => n['read'] == false).length;
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.markAllNotificationsAsRead();
      setState(() {
        for (var notification in _notifications) {
          notification['read'] = true;
        }
        _unreadCount = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.notifications),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(theme, l10n)
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _NotificationTile(
                        notification: notification,
                        onTap: () => _markAsRead(notification['id'] as String),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual notification tile
class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case 'payment':
        return Icons.payment;
      case 'kyc':
        return Icons.verified_user;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type, ThemeData theme) {
    switch (type) {
      case 'payment':
        return Colors.green;
      case 'kyc':
        return Colors.blue;
      case 'system':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = notification['type'] as String? ?? 'system';
    final isRead = notification['read'] as bool? ?? false;
    final title = notification['title'] as String? ?? '';
    final message = notification['message'] as String? ?? '';
    final createdAt = notification['createdAt'] as String?;

    DateTime? createdDateTime;
    if (createdAt != null) {
      try {
        createdDateTime = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    return InkWell(
      onTap: isRead ? null : onTap,
      child: Container(
        color: isRead ? null : theme.colorScheme.primary.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getColorForType(type, theme).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getIconForType(type),
                color: _getColorForType(type, theme),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (createdDateTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(createdDateTime, locale: 'en_short'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
