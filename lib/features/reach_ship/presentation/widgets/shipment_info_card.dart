import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../models/shipment.dart';
import '../../models/address.dart';
import '../../models/package.dart';

class ShipmentInfoCard extends StatelessWidget {
  final Shipment shipment;

  const ShipmentInfoCard({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Shipment Details',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Basic Info Card
        _buildInfoSection('Basic Information', [
          _buildInfoRow('Shipment ID', shipment.id),
          _buildInfoRow(
            'Tracking Number',
            shipment.trackingNumber ?? 'Not assigned',
          ),
          _buildInfoRow('Carrier', shipment.selectedRate.carrierName),
          _buildInfoRow('Service', shipment.selectedRate.serviceName),
          _buildInfoRow('Created', _formatDate(shipment.createdAt)),
          if (shipment.selectedRate.deliveryDate != null)
            _buildInfoRow(
              'Est. Delivery',
              _formatDate(shipment.selectedRate.deliveryDate!),
            ),
        ]),

        const SizedBox(height: 16),

        // Addresses Section
        _buildAddressesSection(),

        const SizedBox(height: 16),

        // Packages Section
        _buildPackagesSection(),

        const SizedBox(height: 16),

        // Cost Information
        _buildCostSection(),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
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
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildAddressesSection() {
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
          Text(
            'Addresses',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // From Address
          _buildAddressCard(
            'From',
            shipment.fromAddress,
            Icons.location_on_outlined,
            AppColors.primary,
          ),

          const SizedBox(height: 12),

          // To Address
          _buildAddressCard(
            'To',
            shipment.toAddress,
            Icons.place_outlined,
            AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    String title,
    Address address,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Contact Info
          if (address.name != null && address.name!.isNotEmpty)
            Text(
              address.name!,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),

          if (address.company != null && address.company!.isNotEmpty)
            Text(
              address.company!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

          const SizedBox(height: 4),

          // Address Lines
          Text(address.street1, style: AppTextStyles.bodySmall),

          if (address.street2 != null && address.street2!.isNotEmpty)
            Text(address.street2!, style: AppTextStyles.bodySmall),

          Text(
            '${address.city}, ${address.state} ${address.postalCode}',
            style: AppTextStyles.bodySmall,
          ),

          Text(address.country, style: AppTextStyles.bodySmall),

          // Contact Details
          if (address.phone != null && address.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  address.phone!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          if (address.email != null && address.email!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address.email!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackagesSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Packages',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${shipment.packages.length} package${shipment.packages.length != 1 ? 's' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Package List
          for (int i = 0; i < shipment.packages.length; i++) ...[
            _buildPackageCard(shipment.packages[i], i + 1),
            if (i < shipment.packages.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageCard(Package package, int index) {
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
          // Package Header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    index.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  package.description ?? 'Package $index',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Package Details
          Row(
            children: [
              Expanded(
                child: _buildPackageDetail(
                  'Dimensions',
                  '${package.length}" × ${package.width}" × ${package.height}"',
                  Icons.straighten,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPackageDetail(
                  'Weight',
                  '${package.weight} ${package.weightUnit}',
                  Icons.scale,
                ),
              ),
            ],
          ),

          if (package.declaredValue != null) ...[
            const SizedBox(height: 8),
            _buildPackageDetail(
              'Declared Value',
              '\$${package.declaredValue!.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCostSection() {
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
          Text(
            'Cost Breakdown',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          _buildCostRow('Shipping Cost', shipment.selectedRate.rate, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
