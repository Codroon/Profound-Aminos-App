import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../data/models/shipment_order.dart';

/// List item widget for displaying a shipment in the list
class ShipmentListItem extends StatelessWidget {
  final ShipmentOrder shipment;
  final VoidCallback? onTap;

  const ShipmentListItem({
    super.key,
    required this.shipment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Icon with status color
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 22,
              ),
            ),
            const Gap(12),
            
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID and Price row
                  Row(
                    children: [
                      AppReusableText(
                        text: shipment.displayId,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      const Spacer(),
                      AppReusableText(
                        text: '\$${shipment.total.toStringAsFixed(0)}',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const Gap(6),
                  
                  // Customer name
                  AppReusableText(
                    text: shipment.customerName.isNotEmpty
                        ? shipment.customerName
                        : 'Guest Customer',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    maxLines: 1,
                  ),
                  const Gap(6),
                  
                  // Status badge and date row
                  Row(
                    children: [
                      _buildStatusBadge(),
                      const Gap(8),
                      AppReusableText(
                        text: _formatDate(shipment.dateCreated),
                        fontSize: 11,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                      if (shipment.hasTracking) ...[
                        const Gap(8),
                        Icon(
                          Icons.qr_code_scanner,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Get color based on shipment status
  Color _getStatusColor() {
    switch (shipment.status) {
      case 'pending':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get icon based on shipment status
  IconData _getStatusIcon() {
    switch (shipment.status) {
      case 'pending':
        return Icons.pending_actions;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  /// Build status badge widget
  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    final label = _getStatusLabel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppReusableText(
        text: label,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  /// Get human-readable status label
  String _getStatusLabel() {
    switch (shipment.status) {
      case 'pending':
        return 'Pending';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
