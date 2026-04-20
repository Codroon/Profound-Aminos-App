import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';
import 'package:woo_management_app/widgets/animated_dots.dart';
import '../../bloc/analytics_bloc.dart';

enum RevenueOrdersPeriod { today, lastWeek, lastMonth }

class RevenueOrdersCard extends StatefulWidget {
  const RevenueOrdersCard({super.key});

  @override
  State<RevenueOrdersCard> createState() => _RevenueOrdersCardState();
}

class _RevenueOrdersCardState extends State<RevenueOrdersCard> {
  RevenueOrdersPeriod _period = RevenueOrdersPeriod.today;

  final Map<RevenueOrdersPeriod, List<dynamic>> _ordersMap = {
    RevenueOrdersPeriod.today: [],
    RevenueOrdersPeriod.lastWeek: [],
    RevenueOrdersPeriod.lastMonth: [],
  };
  final Map<RevenueOrdersPeriod, int> _pageMap = {
    RevenueOrdersPeriod.today: 1,
    RevenueOrdersPeriod.lastWeek: 1,
    RevenueOrdersPeriod.lastMonth: 1,
  };
  final Map<RevenueOrdersPeriod, bool> _loadingMap = {
    RevenueOrdersPeriod.today: false,
    RevenueOrdersPeriod.lastWeek: false,
    RevenueOrdersPeriod.lastMonth: false,
  };
  final Map<RevenueOrdersPeriod, bool> _hasMoreMap = {
    RevenueOrdersPeriod.today: true,
    RevenueOrdersPeriod.lastWeek: true,
    RevenueOrdersPeriod.lastMonth: true,
  };

  @override
  void initState() {
    super.initState();
    // Fetch initial data for all periods to show counts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var p in RevenueOrdersPeriod.values) {
        _fetchOrders(p);
      }
    });
  }

  // ── Date Range ────────────────────────────────────────────────────────────

  (String after, String before) _getRange(RevenueOrdersPeriod p) {
    final now = DateTime.now();
    final pad = (int v) => v.toString().padLeft(2, '0');
    final iso = (DateTime d) => "${d.year}-${pad(d.month)}-${pad(d.day)}T00:00:00";
    
    final beforeStr = "${now.year}-${pad(now.month)}-${pad(now.day)}T23:59:59";
    String afterStr;
    
    switch (p) {
      case RevenueOrdersPeriod.today:
        afterStr = iso(now);
        break;
      case RevenueOrdersPeriod.lastWeek:
        afterStr = iso(now.subtract(const Duration(days: 7)));
        break;
      case RevenueOrdersPeriod.lastMonth:
        afterStr = iso(now.subtract(const Duration(days: 30)));
        break;
    }
    return (afterStr, beforeStr);
  }

  // ── Fetch Logic ──────────────────────────────────────────────────────────

  Future<void> _fetchOrders(RevenueOrdersPeriod p) async {
    if (_loadingMap[p]! || !_hasMoreMap[p]!) return;

    setState(() => _loadingMap[p] = true);

    try {
      final (after, before) = _getRange(p);
      final repo = context.read<AnalyticsBloc>().repository;
      
      final results = await repo.getOrdersByDateRange(
        after: after,
        before: before,
        page: _pageMap[p]!,
        perPage: 10,
      );

      if (mounted) {
        setState(() {
          _ordersMap[p]!.addAll(results);
          _loadingMap[p] = false;
          if (results.length < 10) {
            _hasMoreMap[p] = false;
          } else {
            _pageMap[p] = _pageMap[p]! + 1;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMap[p] = false;
          _hasMoreMap[p] = false; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _ordersMap[_period]!;
    final isLoading = _loadingMap[_period]!;
    final hasMore = _hasMoreMap[_period]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Iconsax.bag_outline, color: AppColors.primary, size: 20),
              const Gap(8),
              AppReusableText(
                text: 'Orders',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ],
          ),
          const Gap(16),

          // ── Tab chips ──────────────────────────────────────────────────────
          Row(
            children: [
              _Chip(
                label: 'Today',
                selected: _period == RevenueOrdersPeriod.today,
                onTap: () => setState(() => _period = RevenueOrdersPeriod.today),
              ),
              const Gap(8),
              _Chip(
                label: 'Last Week',
                selected: _period == RevenueOrdersPeriod.lastWeek,
                onTap: () => setState(() => _period = RevenueOrdersPeriod.lastWeek),
              ),
              const Gap(8),
              _Chip(
                label: 'Last Month',
                selected: _period == RevenueOrdersPeriod.lastMonth,
                onTap: () => setState(() => _period = RevenueOrdersPeriod.lastMonth),
              ),
            ],
          ),
          const Gap(20),

          // ── Orders list ────────────────────────────────────────────────────
          if (orders.isEmpty && !isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Iconsax.bag_outline,
                      color: AppColors.textSecondary.withValues(alpha: 0.35),
                      size: 40,
                    ),
                    const Gap(8),
                    AppReusableText(
                      text: 'No orders for this period',
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      textAlignment: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...orders.map((o) => _OrderRow(order: o)),

            // ── Load More / Spinner ─────────────────────────────────────────
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: AnimatedDots(dotSize: 10, spacing: 6),
                ),
              )
            else if (hasMore)
              GestureDetector(
                onTap: () => _fetchOrders(_period),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppReusableText(
                        text: 'Load More',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      const Gap(6),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Order row ─────────────────────────────────────────────────────────────────

class _OrderRow extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderRow({required this.order});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'processing':
        return const Color(0xFF2196F3);
      case 'pending':
        return const Color(0xFFFFC107);
      case 'refunded':
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = order['id']?.toString() ?? '-';
    final status = order['status']?.toString() ?? 'unknown';
    final total =
        '\$${double.tryParse(order['total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}';
    final dateStr = order['date_created'] as String? ?? '';
    final date = DateTime.tryParse(dateStr);
    final dateLabel = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '-';
    final billing = order['billing'] as Map? ?? {};
    final name =
        '${billing['first_name'] ?? ''} ${billing['last_name'] ?? ''}'
            .trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: AppReusableText(
                text: '#$id',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppReusableText(
                  text: name.isEmpty ? 'Order #$id' : name,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  maxLines: 1,
                ),
                const Gap(3),
                AppReusableText(
                  text: dateLabel,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppReusableText(
                text: total,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              const Gap(3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppReusableText(
                  text: status[0].toUpperCase() + status.substring(1),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
