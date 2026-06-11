import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import '../../../analytics/bloc/analytics_bloc.dart';
import '../../../analytics/bloc/analytics_state.dart';

class CurrentOrdersWidget extends StatelessWidget {
  final List<dynamic> cachedOrders;
  
  const CurrentOrdersWidget({super.key, this.cachedOrders = const []});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteNames.wooAllOrders),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppReusableText(
                  text: 'Current Orders',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
            const Gap(24),
            BlocBuilder<AnalyticsBloc, AnalyticsState>(
  builder: (context, state) {

    // Show cached data immediately if available
    if (cachedOrders.isNotEmpty &&
        (state is AnalyticsInitial ||
         state is AnalyticsLoading)) {
      return Column(
        children: cachedOrders.map((order) {
          return _OrderItem(order: order);
        }).toList(),
      );
    }

    // Initial state -> shimmer
    if (state is AnalyticsInitial) {
      return _buildOrdersShimmer();
    }

    // Loading state -> shimmer
    if (state is AnalyticsLoading) {
      return _buildOrdersShimmer();
    }

    // Loaded state
    if (state is AnalyticsLoaded) {

      final orders = state.allOrders.take(3).toList();

      if (orders.isEmpty) {
        return Center(
          child: Column(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                size: 40,
              ),
              const Gap(8),
              AppReusableText(
                text: 'No orders found',
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        );
      }

      return Column(
        children: orders.map((order) {
          return _OrderItem(order: order);
        }).toList(),
      );
    }

    // Error state
    if (state is AnalyticsError) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 40,
            ),
            const Gap(8),
            AppReusableText(
              text: 'No data available',
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  },
),
          ],
        ),
      ),
    );
  }

  /// Build shimmer effect for orders loading state
  Widget _buildOrdersShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: const Color(0xFF2D3142), // Lighter than cardDark for visible shimmer
      child: Column(
        children: [
          _buildOrderShimmerItem(),
          const Gap(12),
          _buildOrderShimmerItem(),
          const Gap(12),
          _buildOrderShimmerItem(),
        ],
      ),
    );
  }

  Widget _buildOrderShimmerItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // White so shimmer gradient is visible
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white, // White so shimmer gradient is visible
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID and price row
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white, // White so shimmer gradient is visible
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 50,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white, // White so shimmer gradient is visible
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                // Customer and status row
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white, // White so shimmer gradient is visible
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white, // White so shimmer gradient is visible
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final dynamic order;

  const _OrderItem({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order['id']?.toString() ?? 'N/A';
    final customerName = _getCustomerName();
    final total = order['total']?.toString() ?? '0';
    final status = order['status']?.toString() ?? 'unknown';
    final dateCreated = order['date_created']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greyB3.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyB3.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 20,
            ),
          ),
          Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppReusableText(
                      text: '#$orderId',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    Spacer(),
                    AppReusableText(
                      text: '\$$total',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
                Gap(4),
                Row(
                  children: [
                    AppReusableText(
                      text: customerName,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AppReusableText(
                        text: status.toUpperCase(),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
                if (dateCreated.isNotEmpty) ...[
                  Gap(2),
                  AppReusableText(
                    text: _formatDate(dateCreated),
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCustomerName() {
    final billing = order['billing'];
    if (billing != null) {
      final firstName = billing['first_name']?.toString() ?? '';
      final lastName = billing['last_name']?.toString() ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }
    return 'Guest Customer';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'refunded':
        return Colors.red;
      case 'failed':
        return Colors.red.shade700;
      default:
        return AppColors.greyB3;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.hourglass_empty;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'refunded':
        return Icons.money_off;
      case 'failed':
        return Icons.error_outline;
      default:
        return Icons.shopping_cart_outlined;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
