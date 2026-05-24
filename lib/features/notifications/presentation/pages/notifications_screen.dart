import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/core/services/push_notification_service.dart';
import 'package:woo_management_app/features/notifications/services/notification_preference_service.dart';
import '../../bloc/notifications_bloc.dart';
import '../../models/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationsBloc _bloc;
  final Set<String> _selectedNotificationIds = {};

  bool get _isSelectionMode => _selectedNotificationIds.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<NotificationsBloc>();
  }

  @override
  void dispose() {
    try {
      _bloc.add(MarkAllNotificationsAsRead());
    } catch (_) {}
    super.dispose();
  }

  Future<List<AppNotification>> _filterNotifications(
    List<AppNotification> notifications,
  ) async {
    final List<AppNotification> filtered = [];
    for (var notification in notifications) {
      final type = notification.data['type']?.toString() ?? '';
      final isEnabled =
          await NotificationPreferenceService.isNotificationEnabled(
            type: type,
            title: notification.title,
            body: notification.body,
          );
      if (isEnabled) {
        filtered.add(notification);
      }
    }
    return filtered;
  }

  Map<String, List<AppNotification>> _groupNotifications(
    List<AppNotification> notifications,
  ) {
    final Map<String, List<AppNotification>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Sort notifications by timestamp descending to ensure chronological grouping
    final sorted = List<AppNotification>.from(notifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (var notification in sorted) {
      final date = notification.timestamp;
      final compareDate = DateTime(date.year, date.month, date.day);

      String groupKey;
      if (compareDate == today) {
        groupKey = 'Today';
      } else if (compareDate == yesterday) {
        groupKey = 'Yesterday';
      } else {
        groupKey = DateFormat('d-MMM-yyyy').format(date); // e.g., 17-May-2026
      }

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(notification);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading:
            _isSelectionMode
                ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color:
                        isDark
                            ? const Color(0xFFEAF0FF)
                            : const Color(0xFF1F2937),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedNotificationIds.clear();
                    });
                  },
                )
                : null,
        title: AppReusableText(
          text:
              _isSelectionMode
                  ? '${_selectedNotificationIds.length} Selected'
                  : 'Notifications',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFEAF0FF) : const Color(0xFF1F2937),
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: Icon(Iconsax.trash_bold, color: AppColors.error),
              tooltip: 'Delete Selected',
              onPressed: () {
                for (var id in _selectedNotificationIds) {
                  context.read<NotificationsBloc>().add(DeleteNotification(id));
                }
                setState(() {
                  _selectedNotificationIds.clear();
                });
              },
            ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsLoaded) {
            return FutureBuilder<List<AppNotification>>(
              future: _filterNotifications(state.notifications),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filteredNotifications = snapshot.data!;

                if (filteredNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.notification_bing_outline,
                          size: 64,
                          color:
                              isDark
                                  ? const Color(0xFF98A0B8).withOpacity(0.5)
                                  : const Color(0xFF6B7280).withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        AppReusableText(
                          text: 'No notifications yet',
                          color:
                              isDark
                                  ? const Color(0xFF98A0B8)
                                  : const Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                      ],
                    ),
                  );
                }

                final grouped = _groupNotifications(filteredNotifications);
                final List<dynamic> listItems = [];

                grouped.forEach((groupTitle, groupList) {
                  listItems.add(groupTitle);
                  listItems.addAll(groupList);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    final item = listItems[index];
                    if (item is String) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          top: 20,
                          bottom: 10,
                          left: 4,
                        ),
                        child: AppReusableText(
                          text: item,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      );
                    } else {
                      final appNotif = item as AppNotification;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NotificationCard(
                          notification: appNotif,
                          isSelected: _selectedNotificationIds.contains(
                            appNotif.id,
                          ),
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                if (_selectedNotificationIds.contains(
                                  appNotif.id,
                                )) {
                                  _selectedNotificationIds.remove(appNotif.id);
                                } else {
                                  _selectedNotificationIds.add(appNotif.id);
                                }
                              });
                            } else {
                              if (!appNotif.isRead) {
                                context.read<NotificationsBloc>().add(
                                  MarkNotificationAsRead(appNotif.id),
                                );
                              }
                              PushNotificationService.instance.navigateToScreen(
                                appNotif.data,
                              );
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              _selectedNotificationIds.add(appNotif.id);
                            });
                          },
                        ),
                      );
                    }
                  },
                );
              },
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotificationCard({
    required this.notification,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final type = notification.data['type']?.toString() ?? '';

    // Determine icon based on type
    IconData icon = Iconsax.notification_outline;
    Color iconColor = AppColors.primary;

    if (type.startsWith('order') || type.startsWith('refund')) {
      icon = Iconsax.shopping_bag_outline;
      iconColor = AppColors.success;
    } else if (type.startsWith('shipment') || type.startsWith('tracking')) {
      icon = Iconsax.truck_outline;
      iconColor = Colors.blue;
    } else if (type.startsWith('ticket') || type.startsWith('message')) {
      icon = Iconsax.message_outline;
      iconColor = Colors.orange;
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.12)
                  : (notification.isRead
                      ? theme.cardColor
                      : AppColors.primary.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary
                    : (notification.isRead
                        ? theme.dividerColor.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.5)),
            width: isSelected || !notification.isRead ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected || !notification.isRead)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isSelected
                ? Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 24),
                )
                : Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AppReusableText(
                          text: notification.title,
                          fontWeight:
                              notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                          fontSize: 15,
                          color:
                              isDark
                                  ? const Color(0xFFEAF0FF)
                                  : const Color(0xFF1F2937),
                        ),
                      ),
                      if (!notification.isRead && !isSelected)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppReusableText(
                    text: notification.body,
                    fontSize: 13,
                    color:
                        isDark
                            ? const Color(0xFF98A0B8)
                            : const Color(0xFF6B7280),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  AppReusableText(
                    text: _formatDate(notification.timestamp),
                    fontSize: 11,
                    color: (isDark
                            ? const Color(0xFF98A0B8)
                            : const Color(0xFF6B7280))
                        .withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('jm').format(date);
  }
}
