import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/widgets/custom_loading_widget.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';
import '../../../analytics/bloc/analytics_bloc.dart';
import '../../../analytics/bloc/analytics_state.dart';
import '../../../analytics/bloc/analytics_event.dart';

class WooAllOrdersPage extends StatelessWidget {
  const WooAllOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SharedAppbar(title: 'All Orders'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return const Center(
                child: CustomLoadingWidget(
                  size: 50,
                  text: 'Loading all orders...',
                ),
              );
            } else if (state is AnalyticsLoaded) {
              if (state.orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.shopping_cart_outline,
                        color: AppColors.greyB3.withOpacity(0.5),
                        size: 80,
                      ),
                      const Gap(16),
                      AppReusableText(
                        text: 'No orders found',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greyB3.withOpacity(0.7),
                      ),
                      const Gap(8),
                      AppReusableText(
                        text:
                            'Orders will appear here when customers place them',
                        fontSize: 14,
                        color: AppColors.greyB3.withOpacity(0.5),
                        textAlignment: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with order count
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.shopping_cart_outline,
                          color: AppColors.greyB3,
                          size: 24,
                        ),
                        const Gap(12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppReusableText(
                              text: 'Total Orders',
                              fontSize: 14,
                              color: AppColors.backgroundLight,
                            ),
                            AppReusableText(
                              text: '${state.orders.length}',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.backgroundLight,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AppReusableText(
                            text: 'Live Data',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),

                  // Orders list
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) {
                        final order = state.orders[index];
                        return _OrderItem(order: order);
                      },
                    ),
                  ),
                ],
              );
            } else if (state is AnalyticsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.withOpacity(0.7),
                      size: 80,
                    ),
                    const Gap(16),
                    AppReusableText(
                      text: 'Failed to load orders',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    const Gap(8),
                    AppReusableText(
                      text: 'Please check your connection and try again',
                      fontSize: 14,
                      color: AppColors.greyB3.withOpacity(0.5),
                      textAlignment: TextAlign.center,
                    ),
                    const Gap(24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AnalyticsBloc>().add(
                          const FetchAnalytics(0),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
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
    final lineItems = order['line_items'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with order ID and total
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppReusableText(
                        text: 'Order #$orderId',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.backgroundLight,
                      ),
                      const Gap(2),
                      AppReusableText(
                        text: customerName,
                        fontSize: 14,
                        color: AppColors.backgroundLight,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppReusableText(
                      text: '\$$total',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.backgroundLight,
                    ),
                    const Gap(4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AppReusableText(
                        text: status.toUpperCase(),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Order details
            if (lineItems.isNotEmpty) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.greyB3.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppReusableText(
                      text: 'Items (${lineItems.length})',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.backgroundLight,
                    ),
                    const Gap(6),
                    ...lineItems.take(3).map((item) {
                      final name = item['name']?.toString() ?? 'Unknown Item';
                      final quantity = item['quantity']?.toString() ?? '1';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            AppReusableText(
                              text: '• $name',
                              fontSize: 12,
                              color: AppColors.backgroundLight,
                            ),
                            const Spacer(),
                            AppReusableText(
                              text: 'x$quantity',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.backgroundLight,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    if (lineItems.length > 3)
                      AppReusableText(
                        text: '... and ${lineItems.length - 3} more items',
                        fontSize: 11,
                        color: AppColors.backgroundLight,
                        fontStyle: FontStyle.italic,
                      ),
                  ],
                ),
              ),
            ],

            // Date
            if (dateCreated.isNotEmpty) ...[
              const Gap(8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.backgroundLight,
                  ),
                  const Gap(4),
                  AppReusableText(
                    text: _formatDate(dateCreated),
                    fontSize: 12,
                    color: AppColors.backgroundLight,
                  ),
                ],
              ),
            ],
          ],
        ),
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
        return 'Today at ${_formatTime(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${_formatTime(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
