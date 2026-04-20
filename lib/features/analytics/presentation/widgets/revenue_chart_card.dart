import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/animated_dots.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

/// Shared period enum — same options as product performance.
enum RevenuePeriod {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  thisYear('This Year'),
  allTime('All Time');

  const RevenuePeriod(this.label);
  final String label;
}

class RevenueChartCard extends StatelessWidget {
  final RevenuePeriod period;
  final double revenue;
  final int totalOrders;       // ALL-time order count
  final List<FlSpot> chartSpots;
  final List<String> xLabels;
  final ValueChanged<RevenuePeriod> onPeriodChanged;
  final bool isLoadingRevenue;

  const RevenueChartCard({
    super.key,
    required this.period,
    required this.revenue,
    required this.totalOrders,
    required this.chartSpots,
    required this.xLabels,
    required this.onPeriodChanged,
    this.isLoadingRevenue = false,
  });

  bool get _hasNoData =>
      chartSpots.isEmpty || chartSpots.every((s) => s.y == 0);

  @override
  Widget build(BuildContext context) {
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
              Icon(Iconsax.chart_2_outline, color: AppColors.primary, size: 22),
              const Gap(8),
              AppReusableText(
                text: 'Revenue',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              const Spacer(),
              _RevenuePeriodDropdown(
                selected: period,
                onChanged: onPeriodChanged,
              ),
            ],
          ),
          const Gap(20),

          // ── Net Revenue label + amount ─────────────────────────────────────
          AppReusableText(
            text: 'Net Revenue',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          const Gap(4),
          isLoadingRevenue
              ? SizedBox(
                  height: 48,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedDots(
                        color: AppColors.primary,
                        dotSize: 12,
                        spacing: 6,
                      ),
                    ],
                  ),
                )
              : AppReusableText(
                  text: '\$${revenue.toStringAsFixed(2)}',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          const Gap(20),

          // ── Chart ──────────────────────────────────────────────────────────
          SizedBox(
            height: 140,
            child: _hasNoData
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          color: AppColors.textSecondary.withValues(alpha: 0.35),
                          size: 40,
                        ),
                        const Gap(8),
                        AppReusableText(
                          text: 'No revenue data for this period',
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          textAlignment: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : LineChart(_buildChart()),
          ),
          const Gap(8),

          // ── X-axis labels ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: xLabels.asMap().entries.map((e) {
                return SizedBox(
                  width: xLabels.length <= 7
                      ? 320 / xLabels.length
                      : 44,
                  child: Center(
                    child: AppReusableText(
                      text: e.value,
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      textAlignment: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Gap(20),

          // ── Divider ────────────────────────────────────────────────────────
          Divider(color: AppColors.border, height: 1),
          const Gap(16),

          // ── Stats row: Total Orders ────────────────────────────────────────
          Row(
            children: [
              _StatBox(
                label: 'TOTAL ORDERS',
                value: totalOrders.toString(),
                valueColor: AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _buildChart() {
    final maxY = chartSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxY < 1 ? 1.0 : maxY * 1.2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.border.withValues(alpha: 0.5),
          strokeWidth: 0.5,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      clipData: const FlClipData.all(),
      minX: 0,
      maxX: (chartSpots.length - 1).toDouble(),
      minY: 0,
      maxY: effectiveMax,
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: chartSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.primary,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) {
              final peak =
                  chartSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
              if (spot.y == peak) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.primary,
                );
              }
              return FlDotCirclePainter(radius: 0, color: Colors.transparent);
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.35),
                AppColors.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat box ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppReusableText(
          text: label,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        const Gap(4),
        AppReusableText(
          text: value,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: valueColor ?? AppColors.textPrimary,
        ),
      ],
    );
  }
}

// ── Dropdown ──────────────────────────────────────────────────────────────────

class _RevenuePeriodDropdown extends StatelessWidget {
  final RevenuePeriod selected;
  final ValueChanged<RevenuePeriod> onChanged;

  const _RevenuePeriodDropdown(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppReusableText(
              text: selected.label,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            const Gap(4),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyB3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(12),
          ...RevenuePeriod.values.map((p) => ListTile(
                title: Text(p.label,
                    style: TextStyle(
                      color: p == selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: p == selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    )),
                trailing: p == selected
                    ? Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onChanged(p);
                },
              )),
          const Gap(16),
        ],
      ),
    );
  }
}
