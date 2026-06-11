import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/core/services/push_notification_service.dart';
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
  final ScrollController _scrollController = ScrollController();

  bool get _isSelectionMode => _selectedNotificationIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<NotificationsBloc>();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    try {
      _bloc.add(MarkAllNotificationsAsRead());
    } catch (_) {}
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _bloc.add(LoadMoreNotifications());
    }
  }

  Future<void> _pickDateRange() async {
    final state = _bloc.state;
    DateTimeRange? initial;
    if (state is NotificationsLoaded &&
        state.dateFrom != null &&
        state.dateTo != null) {
      // dateTo is stored as an exclusive upper bound (end day + 1).
      initial = DateTimeRange(
        start: state.dateFrom!,
        end: state.dateTo!.subtract(const Duration(days: 1)),
      );
    }
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: initial,
    );
    if (picked == null) return;
    final from = DateTime(picked.start.year, picked.start.month, picked.start.day);
    // Exclusive upper bound = selected end day + 1, so the whole end day is included.
    final to = DateTime(picked.end.year, picked.end.month, picked.end.day)
        .add(const Duration(days: 1));
    _bloc.add(FilterNotificationsByDate(from: from, to: to));
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
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Delete Selected',
              onPressed: () {
                for (var id in _selectedNotificationIds) {
                  context.read<NotificationsBloc>().add(DeleteNotification(id));
                }
                setState(() {
                  _selectedNotificationIds.clear();
                });
              },
            )
          else
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                final active =
                    state is NotificationsLoaded && state.hasDateFilter;
                return IconButton(
                  icon: Icon(
                    active ? Icons.event_available : Icons.date_range_outlined,
                    color: active ? AppColors.primary : null,
                  ),
                  tooltip: 'Filter by date',
                  onPressed: _pickDateRange,
                );
              },
            ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsError) {
            return _buildError(isDark);
          }
          if (state is NotificationsLoaded) {
            return Column(
              children: [
                if (state.hasDateFilter) _buildFilterBanner(state, isDark),
                Expanded(
                  child: state.notifications.isEmpty
                      ? _buildEmpty(isDark, state.hasDateFilter)
                      : _buildList(state),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildList(NotificationsLoaded state) {
    final grouped = _groupNotifications(state.notifications);
    final List<dynamic> listItems = [];
    grouped.forEach((groupTitle, groupList) {
      listItems.add(groupTitle);
      listItems.addAll(groupList);
    });

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _bloc.add(LoadNotifications());
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // +1 for the trailing load-more / end indicator.
        itemCount: listItems.length + 1,
        itemBuilder: (context, index) {
          if (index == listItems.length) {
            return _buildFooter(state);
          }
          final item = listItems[index];
          if (item is String) {
            return Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
              child: AppReusableText(
                text: item,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            );
          }
          final appNotif = item as AppNotification;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NotificationCard(
              notification: appNotif,
              isSelected: _selectedNotificationIds.contains(appNotif.id),
              onTap: () {
                if (_isSelectionMode) {
                  setState(() {
                    if (_selectedNotificationIds.contains(appNotif.id)) {
                      _selectedNotificationIds.remove(appNotif.id);
                    } else {
                      _selectedNotificationIds.add(appNotif.id);
                    }
                  });
                } else {
                  if (!appNotif.isRead) {
                    context
                        .read<NotificationsBloc>()
                        .add(MarkNotificationAsRead(appNotif.id));
                  }
                  PushNotificationService.instance
                      .navigateToScreen(appNotif.data);
                }
              },
              onLongPress: () {
                setState(() {
                  _selectedNotificationIds.add(appNotif.id);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(NotificationsLoaded state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (!state.hasMore && state.notifications.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: AppReusableText(
            text: 'No more notifications',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }

  Widget _buildFilterBanner(NotificationsLoaded state, bool isDark) {
    final fmt = DateFormat('d MMM yyyy');
    final from = state.dateFrom!;
    // Display the inclusive end day (stored bound is exclusive +1 day).
    final toInclusive = state.dateTo!.subtract(const Duration(days: 1));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: AppReusableText(
              text: '${fmt.format(from)}  –  ${fmt.format(toInclusive)}',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          GestureDetector(
            onTap: () => _bloc.add(ClearNotificationDateFilter()),
            child: Icon(Icons.close, size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark, bool hasFilter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 64,
            color: isDark
                ? const Color(0xFF98A0B8).withOpacity(0.5)
                : const Color(0xFF6B7280).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          AppReusableText(
            text: hasFilter
                ? 'No notifications in this date range'
                : 'No notifications yet',
            color: isDark ? const Color(0xFF98A0B8) : const Color(0xFF6B7280),
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          AppReusableText(
            text: 'Couldn\'t load notifications',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFEAF0FF) : const Color(0xFF1F2937),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _bloc.add(LoadNotifications()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
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
    IconData icon = Icons.notifications_outlined;
    Color iconColor = AppColors.primary;

    if (type.startsWith('order') || type.startsWith('refund')) {
      icon = Icons.shopping_bag_outlined;
      iconColor = AppColors.success;
    } else if (type.startsWith('shipment') || type.startsWith('tracking')) {
      icon = Icons.local_shipping_outlined;;
      iconColor = Colors.blue;
    } else if (type.startsWith('ticket') || type.startsWith('message')) {
      icon = Icons.message_outlined;
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
