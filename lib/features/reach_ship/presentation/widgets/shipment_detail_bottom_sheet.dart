import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/shipment.dart';

class ShipmentDetailBottomSheet extends StatelessWidget {
  final Shipment shipment;

  const ShipmentDetailBottomSheet({
    super.key,
    required this.shipment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order number and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${shipment.id}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Date
                  Text(
                    'Oct 25, 2023 at 10:42 AM',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Customer Section
                  _buildSection(
                    icon: Icons.person_outline,
                    title: 'CUSTOMER',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipment.toAddress.name ?? 'Alex Johnson',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shipment.toAddress.street1.isNotEmpty 
                              ? shipment.toAddress.street1 
                              : '123 Fitness Ave, Suite 4B',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${shipment.toAddress.city}, ${shipment.toAddress.state} ${shipment.toAddress.postalCode}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Products Section
                  _buildSection(
                    icon: Icons.inventory_2_outlined,
                    title: 'PRODUCTS',
                    child: Column(
                      children: [
                        _buildProductItem(
                          name: 'Profound Isolate Protein',
                          quantity: 2,
                          price: 89.98,
                        ),
                        Divider(color: AppColors.border, height: 24),
                        _buildProductItem(
                          name: 'Creatine Monohydrate',
                          quantity: 1,
                          price: 24.99,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Totals Section
                  _buildSection(
                    icon: Icons.receipt_outlined,
                    title: 'TOTALS',
                    child: Column(
                      children: [
                        _buildTotalRow('Subtotal', 114.97),
                        const SizedBox(height: 8),
                        _buildTotalRow('Shipping', 5.00),
                        Divider(color: AppColors.border, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '\$119.97',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Shipment Info Section
                  _buildSection(
                    icon: Icons.local_shipping_outlined,
                    title: 'SHIPMENT INFO',
                    child: Column(
                      children: [
                        _buildInfoRow(
                          label: 'Carrier',
                          value: shipment.selectedRate.carrierName.isNotEmpty 
                              ? shipment.selectedRate.carrierName.split(' ').first 
                              : 'UPS',
                          isLink: false,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          label: 'Tracking Number',
                          value: shipment.trackingNumber ?? '1Z9999999999999999',
                          isLink: true,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          label: 'Date Shipped',
                          value: 'Oct 26, 2023',
                          isLink: false,
                          valueStyle: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Track Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to tracking page or open tracking URL
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Track with ${shipment.selectedRate.carrierName.isNotEmpty ? shipment.selectedRate.carrierName.split(' ').first : 'UPS'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final statusColor = _getStatusColor(shipment.status);
    final statusText = _getStatusText(shipment.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildProductItem({
    required String name,
    required int quantity,
    required double price,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Qty: $quantity',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isLink,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: valueStyle ?? TextStyle(
                color: isLink ? AppColors.primary : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: isLink ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isLink) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new,
                color: AppColors.primary,
                size: 14,
              ),
            ],
          ],
        ),
      ],
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

  String _getStatusText(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.delivered:
        return 'Fulfilled';
      case ShipmentStatus.inTransit:
      case ShipmentStatus.outForDelivery:
        return 'In Transit';
      case ShipmentStatus.pending:
      case ShipmentStatus.created:
      case ShipmentStatus.labelGenerated:
        return 'Pending';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
      case ShipmentStatus.exception:
        return 'Exception';
      case ShipmentStatus.returned:
        return 'Returned';
      default:
        return 'Unknown';
    }
  }
}
