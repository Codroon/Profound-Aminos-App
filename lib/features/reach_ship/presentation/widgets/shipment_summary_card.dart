import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../models/address.dart';
import '../../models/package.dart';
import '../../models/rate.dart';

class ShipmentSummaryCard extends StatelessWidget {
  final Address fromAddress;
  final Address toAddress;
  final List<Package> packages;
  final Rate? selectedRate;
  final bool requireSignature;
  final bool saturdayDelivery;
  final bool insuranceRequired;
  final double insuranceValue;
  final String specialInstructions;

  const ShipmentSummaryCard({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    required this.packages,
    this.selectedRate,
    this.requireSignature = false,
    this.saturdayDelivery = false,
    this.insuranceRequired = false,
    this.insuranceValue = 0.0,
    this.specialInstructions = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Shipment Summary',
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Addresses Section
          _buildSectionHeader('Addresses', Icons.location_on_outlined),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAddressCard(
                  'From',
                  fromAddress,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAddressCard('To', toAddress, AppColors.secondary),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Packages Section
          _buildSectionHeader('Packages', Icons.inventory_2_outlined),
          const SizedBox(height: 12),

          ...packages.asMap().entries.map((entry) {
            final index = entry.key;
            final package = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${package.length}" × ${package.width}" × ${package.height}"',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Weight: ${package.weight} ${package.weightUnit ?? 'lbs'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (package.declaredValue != null)
                          Text(
                            'Value: \$${package.declaredValue!.toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Shipping Options Section
          if (_hasShippingOptions()) ...[
            _buildSectionHeader('Shipping Options', Icons.tune_outlined),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (requireSignature)
                    _buildOptionRow(
                      Icons.edit_outlined,
                      'Signature Required',
                      'Delivery requires signature',
                    ),

                  if (saturdayDelivery) ...[
                    if (requireSignature) const SizedBox(height: 8),
                    _buildOptionRow(
                      Icons.weekend_outlined,
                      'Saturday Delivery',
                      'Package will be delivered on Saturday',
                    ),
                  ],

                  if (insuranceRequired) ...[
                    if (requireSignature || saturdayDelivery)
                      const SizedBox(height: 8),
                    _buildOptionRow(
                      Icons.security_outlined,
                      'Insurance Coverage',
                      'Insured for \$${insuranceValue.toStringAsFixed(2)}',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],

          // Special Instructions
          if (specialInstructions.isNotEmpty) ...[
            _buildSectionHeader('Special Instructions', Icons.note_outlined),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(specialInstructions, style: AppTextStyles.bodyMedium),
            ),

            const SizedBox(height: 24),
          ],

          // Cost Breakdown
          if (selectedRate != null) ...[
            _buildSectionHeader('Cost Breakdown', Icons.receipt_outlined),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildCostRow('Shipping Cost', selectedRate!.rate),

                  if (insuranceRequired && insuranceValue > 0) ...[
                    const SizedBox(height: 8),
                    _buildCostRow('Insurance', _calculateInsuranceCost()),
                  ],

                  if (saturdayDelivery) ...[
                    const SizedBox(height: 8),
                    _buildCostRow('Saturday Delivery', 15.00), // Example fee
                  ],

                  const Divider(color: AppColors.border, height: 24),

                  _buildCostRow(
                    'Total Cost',
                    _calculateTotalCost(),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(String label, Address address, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.name ?? '',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (address.company != null) ...[
            const SizedBox(height: 2),
            Text(
              address.company!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(address.street1, style: AppTextStyles.bodySmall),
          if (address.street2 != null) ...[
            Text(address.street2!, style: AppTextStyles.bodySmall),
          ],
          Text(
            '${address.city}, ${address.state} ${address.postalCode}',
            style: AppTextStyles.bodySmall,
          ),
          Text(address.country, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildOptionRow(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              isTotal
                  ? AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                  : AppTextStyles.bodyMedium,
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style:
              isTotal
                  ? AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  )
                  : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  bool _hasShippingOptions() {
    return requireSignature || saturdayDelivery || insuranceRequired;
  }

  double _calculateInsuranceCost() {
    // Typically insurance is calculated as a percentage of the insured value
    // For example, 1% of the insured value with a minimum fee
    return (insuranceValue * 0.01).clamp(2.50, double.infinity);
  }

  double _calculateTotalCost() {
    double total = selectedRate?.rate ?? 0.0;

    if (insuranceRequired && insuranceValue > 0) {
      total += _calculateInsuranceCost();
    }

    if (saturdayDelivery) {
      total += 15.00; // Example Saturday delivery fee
    }

    return total;
  }
}
