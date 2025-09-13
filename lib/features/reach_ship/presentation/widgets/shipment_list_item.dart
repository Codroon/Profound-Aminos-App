import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../models/shipment.dart';

class ShipmentListItem extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ShipmentListItem({
    super.key,
    required this.shipment,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(
      shipment.status.toString() ?? 'unknown',
    );
    final statusIcon = _getStatusIcon(shipment.status.toString() ?? 'unknown');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Status Indicator
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Tracking Number
                    Expanded(
                      child: Text(
                        shipment.trackingNumber ?? 'No tracking number',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Actions Menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      color: AppColors.backgroundDark,
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status and Carrier Row
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusDisplayText(
                              shipment.status.toString() ?? 'unknown',
                            ),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Carrier
                    if (shipment.selectedRate.carrierName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shipment.selectedRate.carrierName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Cost
                    Text(
                      '\$${shipment.selectedRate.rate.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Addresses Row
                Row(
                  children: [
                    // From Address
                    Expanded(
                      child: _buildAddressInfo(
                        'From',
                        shipment.fromAddress.name ??
                            shipment.fromAddress.company ??
                            'Unknown',
                        '${shipment.fromAddress.city}, ${shipment.fromAddress.state}',
                        Icons.location_on_outlined,
                      ),
                    ),

                    // Arrow
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    // To Address
                    Expanded(
                      child: _buildAddressInfo(
                        'To',
                        shipment.toAddress.name ??
                            shipment.toAddress.company ??
                            'Unknown',
                        '${shipment.toAddress.city}, ${shipment.toAddress.state}',
                        Icons.place_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Footer Row
                Row(
                  children: [
                    // Package Count
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${shipment.packages.length} package${shipment.packages.length != 1 ? 's' : ''}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Created Date
                    Icon(
                      Icons.schedule_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(shipment.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const Spacer(),

                    // Estimated Delivery
                    if (shipment.selectedRate.deliveryDate != null) ...[
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Est. ${_formatDate(shipment.selectedRate.deliveryDate!)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressInfo(
    String label,
    String name,
    String location,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          location,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
        return Icons.check_circle;
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
        return Icons.check_circle_outline;
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
        return 'Delivered';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'picked_up':
        return 'Picked Up';
      case 'pending':
        return 'Pending';
      case 'label_created':
        return 'Label Created';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'exception':
        return 'Exception';
      case 'failed':
        return 'Failed';
      case 'returned':
        return 'Returned';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
