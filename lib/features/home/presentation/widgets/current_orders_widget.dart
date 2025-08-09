import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/widgets/custom_loading_widget.dart';
import '../../../analytics/bloc/analytics_bloc.dart';
import '../../../analytics/bloc/analytics_state.dart';

class CurrentOrdersWidget extends StatelessWidget {
  const CurrentOrdersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.shopping_cart_outline,
                  color: AppColors.greyB3,
                  size: 20,
                ),
                const Gap(8),
                AppReusableText(
                  text: 'Current Orders',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greyB3,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, RouteNames.wooAllOrders);
                  },
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.greyB3,
                    size: 16,
                  ),
                ),
              ],
            ),
            const Gap(16),
            BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, state) {
                if (state is AnalyticsLoading) {
                  return const Center(
                    child: CustomLoadingWidget(
                      size: 30,
                      text: 'Loading orders...',
                    ),
                  );
                } else if (state is AnalyticsLoaded) {
                  if (state.orders.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.shopping_cart_outline,
                            color: AppColors.greyB3.withOpacity(0.5),
                            size: 40,
                          ),
                          const Gap(8),
                          AppReusableText(
                            text: 'No orders found',
                            fontSize: 14,
                            color: AppColors.greyB3.withOpacity(0.7),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show only the first 3 orders
                  final ordersToShow = state.orders.take(3).toList();

                  return Column(
                    children:
                        ordersToShow.map((order) {
                          return _OrderItem(order: order);
                        }).toList(),
                  );
                } else if (state is AnalyticsError) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.withOpacity(0.7),
                          size: 40,
                        ),
                        const Gap(8),
                        AppReusableText(
                          text: 'Failed to load orders',
                          fontSize: 14,
                          color: Colors.red.withOpacity(0.7),
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
        color: AppColors.greyB3.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyB3.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 20,
            ),
          ),
          const Gap(12),
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
                      color: AppColors.backgroundLight,
                    ),
                    const Spacer(),
                    AppReusableText(
                      text: '\$$total',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.backgroundLight,
                    ),
                  ],
                ),
                const Gap(4),
                Row(
                  children: [
                    AppReusableText(
                      text: customerName,
                      fontSize: 12,
                      color: AppColors.greyB3.withOpacity(0.8),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
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
                  const Gap(2),
                  AppReusableText(
                    text: _formatDate(dateCreated),
                    fontSize: 10,
                    color: AppColors.backgroundLight,
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
        return Iconsax.shopping_cart_outline;
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
