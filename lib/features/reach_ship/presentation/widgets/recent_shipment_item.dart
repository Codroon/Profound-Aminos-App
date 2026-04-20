import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../models/shipment.dart';
import 'shipment_detail_bottom_sheet.dart';

class RecentShipmentItem extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onTap;

  const RecentShipmentItem({
    super.key,
    required this.shipment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(shipment.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _showShipmentDetail(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Left content - Order info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order number
                      Text(
                        '#ORD-${shipment.id.substring(0, 4).toUpperCase()}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Customer name • Location
                      Text(
                        '${shipment.toAddress.name ?? shipment.toAddress.company ?? 'Unknown'} • ${shipment.toAddress.city}, ${shipment.toAddress.state}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Status badge - text only, no icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    shipment.statusDisplayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Chevron icon
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.delivered:
        return AppColors.success;
      case ShipmentStatus.inTransit:
      case ShipmentStatus.outForDelivery:
        return AppColors.info;
      case ShipmentStatus.pending:
      case ShipmentStatus.created:
      case ShipmentStatus.labelGenerated:
        return AppColors.warning;
      case ShipmentStatus.exception:
      case ShipmentStatus.returned:
      case ShipmentStatus.cancelled:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showShipmentDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: ShipmentDetailBottomSheet(shipment: shipment),
          );
        },
      ),
    );
  }
}
