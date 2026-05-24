import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../widgets/shared_appbar.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../bloc/reach_ship_bloc.dart';
import '../../bloc/reach_ship_event.dart';
import '../../bloc/reach_ship_state.dart';
import '../../models/shipment.dart';
import '../utils/reach_ship_utils.dart';
import '../widgets/tracking_timeline_widget.dart';
import '../widgets/shipment_info_card.dart';

class ShipmentTrackingPage extends StatefulWidget {
  final String? trackingNumber;
  final Shipment? shipment;

  const ShipmentTrackingPage({super.key, this.trackingNumber, this.shipment});

  @override
  State<ShipmentTrackingPage> createState() => _ShipmentTrackingPageState();
}

class _ShipmentTrackingPageState extends State<ShipmentTrackingPage>
    with TickerProviderStateMixin {
  final _trackingController = TextEditingController();
  late TabController _tabController;

  Shipment? _currentShipment;
  List<TrackingEvent> _trackingUpdates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.trackingNumber != null) {
      _trackingController.text = widget.trackingNumber!;
      _trackShipment(widget.trackingNumber!);
    }

    if (widget.shipment != null) {
      _currentShipment = widget.shipment;
      if (_currentShipment!.trackingNumber != null) {
        _trackingController.text = _currentShipment!.trackingNumber!;
        _trackShipment(_currentShipment!.trackingNumber!);
      }
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: SharedAppbar(title: 'Track Shipment'),
      body: BlocListener<ReachShipBloc, ReachShipState>(
        listener: (context, state) {
          if (state is TrackingUpdatesLoaded) {
            setState(() {
              _trackingUpdates = state.events;
            });
          } else if (state is ShipmentLoaded) {
            setState(() {
              _currentShipment = state.shipment;
            });
          } else if (state is ReachShipError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Search Section
            _buildSearchSection(),

            // Content
            Expanded(
              child:
                  _currentShipment != null
                      ? _buildTrackingContent()
                      : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Tracking Number',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _trackingController,
                  hintText: 'Enter tracking number...',
                  prefixIcon: Icons.search,
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _trackShipment(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              BlocBuilder<ReachShipBloc, ReachShipState>(
                builder: (context, state) {
                  final isLoading = state is ReachShipLoading;
                  return CustomButton(
                    text: 'Track',
                    onPressed:
                        isLoading
                            ? null
                            : () {
                              if (_trackingController.text.isNotEmpty) {
                                _trackShipment(_trackingController.text);
                              }
                            },
                    isLoading: isLoading,
                    width: 80,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingContent() {
    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
              Tab(icon: Icon(Icons.info_outline), text: 'Details'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildTimelineTab(), _buildDetailsTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab() {
    return BlocBuilder<ReachShipBloc, ReachShipState>(
      builder: (context, state) {
        if (state is ReachShipLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Loading tracking information...',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Status Card
              _buildCurrentStatusCard(),

              const SizedBox(height: 24),

              // Tracking Timeline
              Text(
                'Tracking History',
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TrackingTimelineWidget(
                updates: _trackingUpdates,
                currentStatus: _currentShipment?.status.toString() ?? 'unknown',
              ),

              const SizedBox(height: 24),

              // Refresh Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Refresh Tracking',
                  onPressed: () {
                    if (_currentShipment?.trackingNumber != null) {
                      _trackShipment(_currentShipment!.trackingNumber!);
                    }
                  },
                  backgroundColor: AppColors.cardDark,
                  textColor: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shipment Info
          ShipmentInfoCard(shipment: _currentShipment!),

          const SizedBox(height: 24),

          // Actions
          Text(
            'Actions',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildActionCard(
            'Get Shipping Label',
            'Download or print the shipping label',
            Icons.print_outlined,
            () => _getShippingLabel(),
          ),

          const SizedBox(height: 12),

          _buildActionCard(
            'Share Tracking',
            'Share tracking information with others',
            Icons.share_outlined,
            () => _shareTracking(),
          ),

          const SizedBox(height: 12),

          if (_canCancelShipment())
            _buildActionCard(
              'Cancel Shipment',
              'Cancel this shipment if not yet picked up',
              Icons.cancel_outlined,
              () => _showCancelDialog(),
              isDestructive: true,
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final status = _currentShipment?.status ?? 'unknown';
    final statusColor = _getStatusColor(status.toString());
    final statusIcon = _getStatusIcon(status.toString());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Status Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),

          SizedBox(height: 16),

          // Status Text
          Text(
            _getStatusDisplayText(status.toString()),
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8),

          // Tracking Number
          Text(
            'Tracking: ${_currentShipment?.trackingNumber ?? 'N/A'}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: 16),

          // Estimated Delivery
          if (_currentShipment != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Est. Delivery: ${ReachShipUtils.getEstimatedDeliveryDate(_currentShipment!.selectedRate)}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isDestructive ? AppColors.error : AppColors.primary)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.error : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('Enter a tracking number', style: AppTextStyles.h4),
          SizedBox(height: 8),
          Text(
            'Enter a tracking number above to view\nshipment details and tracking history',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _trackShipment(String trackingNumber) {
    context.read<ReachShipBloc>().add(
      GetTrackingUpdatesEvent(shipmentId: trackingNumber),
    );
  }

  void _getShippingLabel() {
    if (_currentShipment?.id != null) {
      context.read<ReachShipBloc>().add(
        GetLabelEvent(shipmentId: _currentShipment!.id),
      );
    }
  }

  void _shareTracking() {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing functionality coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Text('Cancel Shipment', style: AppTextStyles.h4),
            content: Text(
              'Are you sure you want to cancel this shipment? This action cannot be undone.',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Keep Shipment',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelShipment();
                },
                child: Text(
                  'Cancel Shipment',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _cancelShipment() {
    if (_currentShipment?.id != null) {
      // Note: ReachShip API doesn't support shipment cancellation
      // Use delete shipments functionality instead
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shipment cancellation is not supported by ReachShip API. Use delete shipments instead.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  bool _canCancelShipment() {
    // Note: ReachShip API doesn't support shipment cancellation
    // Always return false to disable cancel functionality
    return false;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'in_transit':
      case 'out_for_delivery':
        return AppColors.primary;
      case 'pending':
      case 'label_created':
        return AppColors.warning;
      case 'exception':
      case 'failed':
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
      case 'pending':
        return Icons.schedule;
      case 'label_created':
        return Icons.label;
      case 'exception':
      case 'failed':
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
      case 'pending':
        return 'Pending Pickup';
      case 'label_created':
        return 'Label Created';
      case 'exception':
        return 'Delivery Exception';
      case 'failed':
        return 'Delivery Failed';
      default:
        return 'Unknown Status';
    }
  }
}
