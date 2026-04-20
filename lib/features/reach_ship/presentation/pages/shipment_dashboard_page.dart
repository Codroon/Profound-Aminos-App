import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/shipment.dart';
import '../../models/address.dart';
import '../../models/shipping_rate.dart';
import '../widgets/recent_shipment_item.dart';
import 'all_shipments_page.dart';

class ShipmentDashboardPage extends StatelessWidget {
  const ShipmentDashboardPage({super.key});

  // Dummy data matching the screenshots exactly
  List<Shipment> get _dummyShipments {
    return [
      Shipment(
        id: '9021',
        fromAddress: Address(
          city: 'Warehouse',
          state: 'TX',
          name: 'Warehouse',
          street1: '123 Warehouse St',
          postalCode: '78701',
          country: 'US',
        ),
        toAddress: Address(
          city: 'Austin',
          state: 'TX',
          name: 'Sarah Jenkins',
          street1: '456 Main St',
          postalCode: '78701',
          country: 'US',
        ),
        packages: [],
        selectedRate: ShippingRate(
          id: 'rate1',
          carrierId: 'usps',
          carrierName: 'USPS Priority',
          serviceName: 'Priority',
          serviceCode: 'priority',
          rate: 8.50,
          deliveryDate: null,
        ),
        status: ShipmentStatus.inTransit,
        trackingNumber: '1Z9999999999999999',
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9020',
        fromAddress: Address(
          city: 'Warehouse',
          state: 'TX',
          name: 'Warehouse',
          street1: '123 Warehouse St',
          postalCode: '78701',
          country: 'US',
        ),
        toAddress: Address(
          city: 'Seattle',
          state: 'WA',
          name: 'Michael Chen',
          street1: '789 Pine St',
          postalCode: '98101',
          country: 'US',
        ),
        packages: [],
        selectedRate: ShippingRate(
          id: 'rate2',
          carrierId: 'ups',
          carrierName: 'UPS Ground',
          serviceName: 'Ground',
          serviceCode: 'ground',
          rate: 12.00,
          deliveryDate: null,
        ),
        status: ShipmentStatus.pending,
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9019',
        fromAddress: Address(
          city: 'Warehouse',
          state: 'TX',
          name: 'Warehouse',
          street1: '123 Warehouse St',
          postalCode: '78701',
          country: 'US',
        ),
        toAddress: Address(
          city: 'New York',
          state: 'NY',
          name: 'Emma Thompson',
          street1: '321 Broadway',
          postalCode: '10001',
          country: 'US',
        ),
        packages: [],
        selectedRate: ShippingRate(
          id: 'rate3',
          carrierId: 'fedex',
          carrierName: 'FedEx Express',
          serviceName: 'Express',
          serviceCode: 'express',
          rate: 15.50,
          deliveryDate: null,
        ),
        status: ShipmentStatus.delivered,
        trackingNumber: '1Z8888888888888888',
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9018',
        fromAddress: Address(
          city: 'Warehouse',
          state: 'TX',
          name: 'Warehouse',
          street1: '123 Warehouse St',
          postalCode: '78701',
          country: 'US',
        ),
        toAddress: Address(
          city: 'Miami',
          state: 'FL',
          name: 'David Rodriguez',
          street1: '555 Ocean Dr',
          postalCode: '33101',
          country: 'US',
        ),
        packages: [],
        selectedRate: ShippingRate(
          id: 'rate4',
          carrierId: 'dhl',
          carrierName: 'DHL Express',
          serviceName: 'Express',
          serviceCode: 'express',
          rate: 22.00,
          deliveryDate: null,
        ),
        status: ShipmentStatus.delivered,
        trackingNumber: '1Z7777777777777777',
        createdAt: DateTime.now(),
      ),
      Shipment(
        id: '9017',
        fromAddress: Address(
          city: 'Warehouse',
          state: 'TX',
          name: 'Warehouse',
          street1: '123 Warehouse St',
          postalCode: '78701',
          country: 'US',
        ),
        toAddress: Address(
          city: 'Chicago',
          state: 'IL',
          name: 'Lisa White',
          street1: '888 Michigan Ave',
          postalCode: '60601',
          country: 'US',
        ),
        packages: [],
        selectedRate: ShippingRate(
          id: 'rate5',
          carrierId: 'usps',
          carrierName: 'USPS First Class',
          serviceName: 'First Class',
          serviceCode: 'first_class',
          rate: 4.50,
          deliveryDate: null,
        ),
        status: ShipmentStatus.inTransit,
        trackingNumber: '1Z6666666666666666',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final shipments = _dummyShipments;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Text(
                  'Shipping',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Statistics Cards - 2x2 Grid with exact values from screenshot
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // First row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Pending',
                            count: 24,
                            icon: Icons.access_time_filled,
                            iconColor: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'In Transit',
                            count: 18,
                            icon: Icons.local_shipping,
                            iconColor: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Second row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Fulfilled',
                            count: 156,
                            icon: Icons.check_circle,
                            iconColor: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Shipments',
                            count: 198,
                            icon: Icons.inventory_2,
                            iconColor: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Shipments Section
              _buildRecentShipmentsSection(context, shipments),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon in colored circle background
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          // Title with color matching icon
          Text(
            title,
            style: TextStyle(
              color: iconColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // Count - large white text
          Text(
            count.toString(),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentShipmentsSection(BuildContext context, List<Shipment> shipments) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Recent Shipments',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Shipment List
          Column(
            children: shipments.map((shipment) => RecentShipmentItem(
              shipment: shipment,
            )).toList(),
          ),

          // View All Shipments Button
          Container(
            width: double.infinity,
            height: 52,
            margin: const EdgeInsets.only(bottom: 16, top: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AllShipmentsPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: const Text(
                'View All Shipments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
