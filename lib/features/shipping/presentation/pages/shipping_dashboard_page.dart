import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../bloc/shipping_bloc.dart';
import '../../bloc/shipping_event.dart';
import '../../bloc/shipping_state.dart';
import '../../data/models/shipment_order.dart';
import '../../data/models/shipment_period.dart';
import '../../../../core/utils/store_time.dart';

class ShippingDashboardPage extends StatefulWidget {
  const ShippingDashboardPage({super.key});

  @override
  State<ShippingDashboardPage> createState() => _ShippingDashboardPageState();
}

class _ShippingDashboardPageState extends State<ShippingDashboardPage> {
  ShipmentPeriod _period = ShipmentPeriod.today;

  /// True while a filter-change background refresh is in flight (data already
  /// on screen, fresh numbers loading). Drives the small header spinner.
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Wait for the store timezone offset so the very first "today" window uses
    // the store's calendar day, not the device's, then fetch.
    StoreTime.ensureLoaded().then((_) {
      if (mounted) _fetchForPeriod();
    });
  }

  void _fetchForPeriod() {
    context.read<ShippingBloc>().add(
          FetchShipments(after: _period.after, before: _period.before),
        );
  }

  void _onPeriodChanged(ShipmentPeriod period) {
    if (period == _period) return;
    // Data stays on screen while fresh numbers load in the background — show a
    // small spinner in the header so the user knows an update is happening.
    setState(() {
      _period = period;
      _isUpdating = true;
    });
    _fetchForPeriod();
  }

  Future<void> _showPeriodPicker() async {
    final selected = await showModalBottomSheet<ShipmentPeriod>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PeriodPickerSheet(selected: _period),
    );
    if (selected != null) _onPeriodChanged(selected);
  }
  Future<void> _onRefresh() async {
    final bloc = context.read<ShippingBloc>();
    bloc.add(const RefreshShipments());
    await bloc.stream
        .firstWhere((s) => s is ShipmentsLoaded || s is ShippingError)
        .timeout(const Duration(seconds: 35), onTimeout: () => bloc.state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: BlocConsumer<ShippingBloc, ShippingState>(
          listener: (context, state) {
            if (_isUpdating &&
                (state is ShipmentsLoaded || state is ShippingError)) {
              setState(() => _isUpdating = false);
            }
          },
          builder: (context, state) {
            if (state is ShippingLoading) {
              return _buildShimmerLoading();
            }

            if (state is ShippingError) {
              return _buildErrorState(state.message);
            }

            if (state is ShipmentsLoaded) {
              return _buildDashboardWithData(state);
            }

            return _buildShimmerLoading();
          },
        ),
      ),
    );
  }

  Widget _buildDashboardWithData(ShipmentsLoaded state) {
    final stats = state.stats;
    final recentShipments = state.shipments.take(5).toList();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              AppReusableText(
                text: 'Shipping',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              const Spacer(),
              if (_isUpdating)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const Gap(24),

          // Stats Cards Grid — Total Shipments card carries the period selector
          _buildTotalShipmentsCard(stats.total),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Pending',
                  count: stats.pending,
                  icon: Icons.timer_outlined,
                  color: Colors.orange,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _buildStatCard(
                  title: 'Fulfilled',
                  count: stats.delivered,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const Gap(24),

          // Recent Shipments Header
          AppReusableText(
            text: 'Recent Shipments',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          const Gap(16),

          // Recent Shipments List
          if (recentShipments.isEmpty)
            _buildEmptyShipments()
          else
            Column(
              children: recentShipments.map((shipment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRecentShipmentItem(shipment),
                );
              }).toList(),
            ),

          const Gap(24),

          // View All Shipments Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.shipments,
                  arguments: _period,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
      ),
    );
  }

  /// Total Shipments card with the time-period selector pinned to the right.
  Widget _buildTotalShipmentsCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        color: Colors.grey, size: 20),
                    const Gap(8),
                    AppReusableText(
                      text: 'Total Shipments',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const Gap(8),
                AppReusableText(
                  text: count.toString(),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
          _buildPeriodButton(),
        ],
      ),
    );
  }

  /// Pill button showing the active period; tap opens the picker bottom sheet.
  Widget _buildPeriodButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showPeriodPicker,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            // border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppReusableText(
                text: _period.label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              const Gap(4),
              Icon(Icons.keyboard_arrow_down,
                  color: AppColors.primary, size: 18),
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
    required Color color,
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
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Gap(8),
              AppReusableText(
                text: title,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const Gap(8),
          AppReusableText(
            text: count.toString(),
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentShipmentItem(ShipmentOrder shipment) {
    return GestureDetector(
      onTap: () => _showShipmentDetail(shipment),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppReusableText(
                    text: shipment.displayId,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  const Gap(4),
                  AppReusableText(
                    text: '${shipment.customerName} • ${shipment.toAddress.city}, ${shipment.toAddress.state}',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            _buildStatusBadge(shipment.status),
            const Gap(8),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showShipmentDetail(ShipmentOrder shipment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _ShipmentDetailBottomSheet(
          shipment: shipment,
          scrollController: scrollController,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'in_transit':
        color = Colors.blue;
        label = 'In Transit';
        break;
      case 'delivered':
        color = Colors.green;
        label = 'Fulfilled';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppReusableText(
        text: label,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildEmptyShipments() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textSecondary.withOpacity(0.5),
              size: 48,
            ),
            const Gap(12),
            AppReusableText(
              text: 'No shipments found',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: const Color(0xFF2D3142),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Gap(24),
            Row(
              children: [
                Expanded(child: _buildShimmerCard(height: 100)),
                const Gap(12),
                Expanded(child: _buildShimmerCard(height: 100)),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(child: _buildShimmerCard(height: 100)),
                const Gap(12),
                Expanded(child: _buildShimmerCard(height: 100)),
              ],
            ),
            const Gap(24),
            Container(
              width: 140,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Gap(16),
            _buildShimmerCard(height: 80),
            const Gap(12),
            _buildShimmerCard(height: 80),
            const Gap(12),
            _buildShimmerCard(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const Gap(16),
            AppReusableText(
              text: 'Failed to load shipments',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
            const Gap(8),
            AppReusableText(
              text: message,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: () {
                context.read<ShippingBloc>().add(const FetchShipments());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to pick the dashboard's time period. Returns the chosen
/// [ShipmentPeriod] via Navigator.pop (or null if dismissed).
class _PeriodPickerSheet extends StatelessWidget {
  final ShipmentPeriod selected;

  const _PeriodPickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppReusableText(
                  text: 'Select Period',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Gap(4),
            ...ShipmentPeriod.values.map((period) {
              final isSelected = period == selected;
              return ListTile(
                onTap: () => Navigator.pop(context, period),
                title: AppReusableText(
                  text: period.label,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
              );
            }),
            const Gap(12),
          ],
        ),
      ),
    );
  }
}

class _ShipmentDetailBottomSheet extends StatelessWidget {
  final ShipmentOrder shipment;
  final ScrollController scrollController;

  const _ShipmentDetailBottomSheet({
    required this.shipment,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with order ID and status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                AppReusableText(
                  text: shipment.displayId,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(6),
                      AppReusableText(
                        text: _getStatusLabel(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppReusableText(
                text: _formatDateTime(shipment.dateCreated),
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Gap(20),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Section
                  _buildSectionTitle(Icons.person_outline, 'CUSTOMER'),
                  const Gap(12),
                  _buildInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppReusableText(
                          text: shipment.customerName.isNotEmpty ? shipment.customerName : '-',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        const Gap(4),
                        AppReusableText(
                          text: shipment.toAddress.street1.isNotEmpty ? shipment.toAddress.street1 : '-',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        AppReusableText(
                          text: '${shipment.toAddress.city}, ${shipment.toAddress.state} ${shipment.toAddress.postalCode}',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const Gap(20),

                  // Products Section
                  _buildSectionTitle(Icons.inventory_2_outlined, 'PRODUCTS'),
                  const Gap(12),
                  _buildInfoCard(
                    child: Column(
                      children: shipment.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppReusableText(
                                      text: item.name,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    AppReusableText(
                                      text: 'Qty: ${item.quantity}',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                              AppReusableText(
                                text: '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Gap(20),

                  // Totals Section
                  _buildSectionTitle(Icons.receipt_long, 'TOTALS'),
                  const Gap(12),
                  _buildInfoCard(
                    child: Column(
                      children: [
                        _buildTotalRow('Subtotal', '\$${_calculateSubtotal().toStringAsFixed(2)}'),
                        const Gap(8),
                        _buildTotalRow('Shipping', '\$${shipment.shippingCost.toStringAsFixed(2)}'),
                        const Gap(12),
                        Container(
                          padding: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
                            ),
                          ),
                          child: _buildTotalRow(
                            'Total',
                            '\$${shipment.total.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(20),

                  // Shipment Info Section
                  _buildSectionTitle(Icons.local_shipping, 'SHIPMENT INFO'),
                  const Gap(12),
                  _buildInfoCard(
                    child: _buildShipmentInfoRow(
                      'Carrier',
                      shipment.carrier ?? shipment.service ?? '-',
                    ),
                  ),
                  const Gap(32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const Gap(8),
        AppReusableText(
          text: title,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppReusableText(
          text: label,
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        AppReusableText(
          text: value,
          fontSize: isTotal ? 18 : 14,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          color: isTotal ? AppColors.primary : AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _buildShipmentInfoRow(String label, String value, {bool isLink = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppReusableText(
          text: label,
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        isLink && value != '-'
          ? Row(
              children: [
                AppReusableText(
                  text: value,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                const Gap(4),
                Icon(Icons.open_in_new, color: AppColors.primary, size: 14),
              ],
            )
          : AppReusableText(
              text: value,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
      ],
    );
  }

  double _calculateSubtotal() {
    return shipment.items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

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
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (shipment.status) {
      case 'pending':
        return 'Pending';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Fulfilled';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
