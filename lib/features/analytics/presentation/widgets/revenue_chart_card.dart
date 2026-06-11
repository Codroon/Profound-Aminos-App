import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/features/analytics/models/revenue_period.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

/// Revenue graph card — same look & behaviour as the product-performance chart,
/// plotting net revenue over fixed time buckets for the selected period.
class RevenueChartCard extends StatelessWidget {
  final RevenuePeriod period;
  final double revenue;
  final List<FlSpot> chartSpots;
  final List<String> xLabels;
  final ValueChanged<RevenuePeriod> onPeriodChanged;
  final bool isLoadingRevenue;

  const RevenueChartCard({
    super.key,
    required this.period,
    required this.revenue,
    required this.chartSpots,
    required this.xLabels,
    required this.onPeriodChanged,
    this.isLoadingRevenue = false,
  });

  /// True when every bucket has zero sales — fixed buckets are never empty.
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
          // ── Header row ────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.bar_chart_outlined, color: AppColors.primary, size: 22),
              const Gap(8),
              AppReusableText(
                text: 'Revenue',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              const Spacer(),
              _PeriodDropdown(
                selected: period,
                onChanged: onPeriodChanged,
              ),
            ],
          ),
          const Gap(20),

          // ── Net Revenue label + amount ────────────────────────────────────
          AppReusableText(
            text: 'Net Revenue',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          const Gap(4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppReusableText(
              text: '\$${revenue.toStringAsFixed(2)}',
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(20),

          // ── Chart ─────────────────────────────────────────────────────────
          SizedBox(
            height: 140,
            child: isLoadingRevenue
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : _hasNoData
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        AppReusableText(
                          text: 'No revenue data for this period',
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          textAlignment: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : LineChart(_buildChartData()),
          ),
          const Gap(8),

          // ── X-axis labels (scrollable) ────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: xLabels.asMap().entries.map((e) {
                return SizedBox(
                  width: _labelWidth,
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
        ],
      ),
    );
  }

  double get _labelWidth {
    // Distribute equally to fill the card content width (~320px minus padding)
    // For many labels (year = 12), shrink to fit.
    if (xLabels.length <= 7) return 320 / xLabels.length;
    return 44; // scrollable for many labels
  }

  LineChartData _buildChartData() {
    final maxY = chartSpots.isEmpty
        ? 1.0
        : chartSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxY < 1 ? 1.0 : maxY * 1.2;

    return LineChartData(
      gridData: FlGridData(show: false),
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
            getDotPainter: (spot, percent, bar, index) {
              // Only show dot at the peak value
              final peak = chartSpots
                  .map((s) => s.y)
                  .reduce((a, b) => a > b ? a : b);
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

// ── Period Dropdown ──────────────────────────────────────────────────────────

class _PeriodDropdown extends StatelessWidget {
  final RevenuePeriod selected;
  final ValueChanged<RevenuePeriod> onChanged;

  const _PeriodDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
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

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(12),
          Container(
            width: 40, height: 4,
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
