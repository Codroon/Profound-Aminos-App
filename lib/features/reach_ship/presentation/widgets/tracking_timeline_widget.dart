import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../models/shipment.dart';

class TrackingTimelineWidget extends StatelessWidget {
  final List<TrackingEvent> updates;
  final String currentStatus;

  const TrackingTimelineWidget({
    super.key,
    required this.updates,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        for (int i = 0; i < updates.length; i++)
          _buildTimelineItem(
            updates[i],
            isLast: i == updates.length - 1,
            isActive: i == 0, // Most recent update is active
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    TrackingEvent update, {
    required bool isLast,
    required bool isActive,
  }) {
    final statusColor = _getStatusColor(update.status);
    final statusIcon = _getStatusIcon(update.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              // Status dot
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isActive ? statusColor : AppColors.cardDark,
                  border: Border.all(color: statusColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  size: 12,
                  color: isActive ? Colors.white : statusColor,
                ),
              ),

              // Connecting line
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Container(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getStatusDisplayText(update.status),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.w500,
                            color:
                                isActive ? statusColor : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatDateTime(update.timestamp),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Description
                  if (update.description != null &&
                      update.description!.isNotEmpty)
                    Text(
                      update.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                  // Location
                  if (update.location != null &&
                      update.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            update.location!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Location info
                  if (update.location != null &&
                      update.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        update.location!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Tracking Updates',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tracking information will appear here once\nthe shipment is processed by the carrier.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'in_transit':
      case 'out_for_delivery':
      case 'picked_up':
        return AppColors.primary;
      case 'pending':
      case 'label_created':
      case 'ready_for_pickup':
        return AppColors.warning;
      case 'exception':
      case 'failed':
      case 'returned':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check;
      case 'in_transit':
        return Icons.local_shipping;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'picked_up':
        return Icons.inventory;
      case 'pending':
        return Icons.schedule;
      case 'label_created':
        return Icons.label;
      case 'ready_for_pickup':
        return Icons.storefront;
      case 'exception':
        return Icons.warning;
      case 'failed':
      case 'returned':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Package Delivered';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'picked_up':
        return 'Picked Up by Carrier';
      case 'pending':
        return 'Shipment Pending';
      case 'label_created':
        return 'Shipping Label Created';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'exception':
        return 'Delivery Exception';
      case 'failed':
        return 'Delivery Failed';
      case 'returned':
        return 'Package Returned';
      default:
        return status
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? word[0].toUpperCase() + word.substring(1)
                      : '',
            )
            .join(' ');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else {
      // Older - show date
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
