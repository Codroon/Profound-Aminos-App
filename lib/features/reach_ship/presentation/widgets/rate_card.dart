import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../widgets/custom_button.dart';
import '../../models/rate.dart';

class RateCard extends StatelessWidget {
  final Rate rate;
  final VoidCallback onSelect;
  final bool isSelected;

  const RateCard({
    super.key,
    required this.rate,
    required this.onSelect,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with carrier and service
              Row(
                children: [
                  // Carrier Logo/Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getCarrierColor(
                        rate.carrierName,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCarrierIcon(rate.carrierName),
                      color: _getCarrierColor(rate.carrierName),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Carrier and Service Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rate.carrierName.toUpperCase(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _getCarrierColor(rate.carrierName),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rate.serviceName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${rate.rate.toStringAsFixed(2)}',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // if (rate.listCost != null &&
                      //     rate.listCost! > rate.totalCost)
                      //   Text(
                      //     '\$${rate.listCost!.toStringAsFixed(2)}',
                      //     style: AppTextStyles.bodySmall.copyWith(
                      //       color: AppColors.textSecondary,
                      //       decoration: TextDecoration.lineThrough,
                      //     ),
                      //   ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Delivery Information
              Row(
                children: [
                  // Delivery Time
                  Expanded(
                    child: _buildInfoItem(
                      Icons.schedule_outlined,
                      'Delivery Time',
                      _getDeliveryTimeText(),
                    ),
                  ),

                  // Transit Days
                  if (rate.transitDays != null)
                    Expanded(
                      child: _buildInfoItem(
                        Icons.local_shipping_outlined,
                        'Transit Days',
                        '${rate.transitDays} days',
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Additional Services
              if (rate.features?.isNotEmpty == true) ...[
                Text(
                  'Included Services',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      rate.features!.map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            service,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Delivery Guarantee
              if (rate.isResidential == true)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),

                      Text(
                        'Delivery Guarantee',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Select Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: isSelected ? 'Selected' : 'Select This Rate',
                  onPressed: isSelected ? null : onSelect,
                  backgroundColor:
                      isSelected ? AppColors.success : AppColors.primary,
                  height: 44,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDeliveryTimeText() {
    if (rate.deliveryDate != null) {
      final deliveryDate = rate.deliveryDate!;
      final now = DateTime.now();
      final difference = deliveryDate.difference(now).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Tomorrow';
      } else {
        return '${deliveryDate.month}/${deliveryDate.day}/${deliveryDate.year}';
      }
    } else if (rate.transitDays != null) {
      return '${rate.transitDays} business days';
    } else {
      return 'Standard delivery';
    }
  }

  Color _getCarrierColor(String carrier) {
    switch (carrier.toLowerCase()) {
      case 'ups':
        return const Color(0xFF8B4513);
      case 'fedex':
        return const Color(0xFF4B0082);
      case 'usps':
        return const Color(0xFF1E3A8A);
      case 'dhl':
        return const Color(0xFFFFD700);
      case 'ontrac':
        return const Color(0xFF00A651);
      default:
        return AppColors.primary;
    }
  }

  IconData _getCarrierIcon(String carrier) {
    switch (carrier.toLowerCase()) {
      case 'ups':
        return Icons.local_shipping;
      case 'fedex':
        return Icons.flight_takeoff;
      case 'usps':
        return Icons.mail_outline;
      case 'dhl':
        return Icons.speed;
      case 'ontrac':
        return Icons.delivery_dining;
      default:
        return Icons.local_shipping_outlined;
    }
  }
}
