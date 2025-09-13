import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../widgets/shared_appbar.dart';
import '../../../../widgets/custom_button.dart';
import '../../bloc/reach_ship_bloc.dart';
import '../../bloc/reach_ship_event.dart';
import '../../bloc/reach_ship_state.dart';
import '../../models/shipment.dart';
import '../widgets/shipping_overview_card.dart';
import '../widgets/quick_action_card.dart';
import 'shipping_rates_page.dart';
import 'create_shipment_page.dart';
import 'shipment_tracking_page.dart';
import 'shipment_management_page.dart';

class ReachShipMainPage extends StatefulWidget {
  const ReachShipMainPage({super.key});

  @override
  State<ReachShipMainPage> createState() => _ReachShipMainPageState();
}

class _ReachShipMainPageState extends State<ReachShipMainPage> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    context.read<ReachShipBloc>().add(const GetShipmentsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const SharedAppbar(
        title: 'ReachShip',
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: BlocBuilder<ReachShipBloc, ReachShipState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                _buildWelcomeSection(),
                const SizedBox(height: 24),

                // Overview Cards
                _buildOverviewSection(state),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActionsSection(),
                const SizedBox(height: 24),

                // Recent Shipments
                _buildRecentShipmentsSection(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to ReachShip',
            style: AppTextStyles.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your shipments, track packages, and compare shipping rates all in one place.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(ReachShipState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: AppTextStyles.h4),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ShippingOverviewCard(
                title: 'Active Shipments',
                value: _getActiveShipmentsCount(state).toString(),
                icon: Icons.local_shipping,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ShippingOverviewCard(
                title: 'In Transit',
                value: _getInTransitCount(state).toString(),
                icon: Icons.flight_takeoff,
                color: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ShippingOverviewCard(
                title: 'Delivered',
                value: _getDeliveredCount(state).toString(),
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ShippingOverviewCard(
                title: 'Pending',
                value: _getPendingCount(state).toString(),
                icon: Icons.pending,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.h4),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            QuickActionCard(
              title: 'Compare Rates',
              subtitle: 'Find best shipping rates',
              icon: Icons.compare_arrows,
              color: AppColors.primary,
              onTap: () => _navigateToRatesComparison(),
            ),
            QuickActionCard(
              title: 'Create Shipment',
              subtitle: 'Ship new package',
              icon: Icons.add_box,
              color: AppColors.secondary,
              onTap: () => _navigateToShipmentCreation(),
            ),
            QuickActionCard(
              title: 'Track Package',
              subtitle: 'Track your shipments',
              icon: Icons.track_changes,
              color: AppColors.info,
              onTap: () => _navigateToTracking(),
            ),
            QuickActionCard(
              title: 'Manage Shipments',
              subtitle: 'View all shipments',
              icon: Icons.inventory,
              color: AppColors.success,
              onTap: () => _navigateToManagement(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentShipmentsSection(ReachShipState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Shipments', style: AppTextStyles.h4),
            TextButton(
              onPressed: () => _navigateToManagement(),
              child: Text(
                'View All',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRecentShipmentsList(state),
      ],
    );
  }

  Widget _buildRecentShipmentsList(ReachShipState state) {
    if (state is ShipmentsLoaded) {
      final recentShipments = state.shipments.take(3).toList();

      if (recentShipments.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        children:
            recentShipments.map((shipment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          shipment.status,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(shipment.status),
                        color: _getStatusColor(shipment.status),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shipment.id,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${shipment.fromAddress.city} → ${shipment.toAddress.city}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          shipment.status,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        shipment.status.name.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: _getStatusColor(shipment.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      );
    } else if (state is ReachShipLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else {
      return _buildEmptyState();
    }
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
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No shipments yet', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Text(
            'Create your first shipment to get started',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Create Shipment',
            onPressed: () => _navigateToShipmentCreation(),
            // width: 200,
          ),
        ],
      ),
    );
  }

  // Helper methods
  int _getActiveShipmentsCount(ReachShipState state) {
    if (state is ShipmentsLoaded) {
      return state.shipments
          .where(
            (s) =>
                s.status != ShipmentStatus.delivered &&
                s.status != ShipmentStatus.cancelled,
          )
          .length;
    }
    return 0;
  }

  int _getInTransitCount(ReachShipState state) {
    if (state is ShipmentsLoaded) {
      return state.shipments
          .where((s) => s.status == ShipmentStatus.inTransit)
          .length;
    }
    return 0;
  }

  int _getDeliveredCount(ReachShipState state) {
    if (state is ShipmentsLoaded) {
      return state.shipments
          .where((s) => s.status == ShipmentStatus.delivered)
          .length;
    }
    return 0;
  }

  int _getPendingCount(ReachShipState state) {
    if (state is ShipmentsLoaded) {
      return state.shipments
          .where((s) => s.status == ShipmentStatus.pending)
          .length;
    }
    return 0;
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending:
        return AppColors.warning;
      case ShipmentStatus.created:
        return AppColors.info;
      case ShipmentStatus.confirmed:
        return AppColors.info;
      case ShipmentStatus.labelGenerated:
        return AppColors.primary;
      case ShipmentStatus.inTransit:
        return AppColors.primary;
      case ShipmentStatus.outForDelivery:
        return AppColors.primary;
      case ShipmentStatus.delivered:
        return AppColors.success;
      case ShipmentStatus.exception:
        return AppColors.error;
      case ShipmentStatus.returned:
        return AppColors.warning;
      case ShipmentStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending:
        return Icons.pending;
      case ShipmentStatus.created:
        return Icons.create;
      case ShipmentStatus.confirmed:
        return Icons.check_circle_outline;
      case ShipmentStatus.labelGenerated:
        return Icons.label;
      case ShipmentStatus.inTransit:
        return Icons.local_shipping;
      case ShipmentStatus.outForDelivery:
        return Icons.delivery_dining;
      case ShipmentStatus.delivered:
        return Icons.store_sharp;
      case ShipmentStatus.exception:
        return Icons.error;
      case ShipmentStatus.returned:
        return Icons.keyboard_return;
      case ShipmentStatus.cancelled:
        return Icons.cancel;
    }
  }

  // Navigation methods
  void _navigateToRatesComparison() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShippingRatesPage()),
    );
  }

  void _navigateToShipmentCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateShipmentPage()),
    );
  }

  void _navigateToTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShipmentTrackingPage()),
    );
  }

  void _navigateToManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShipmentManagementPage()),
    );
  }
}
