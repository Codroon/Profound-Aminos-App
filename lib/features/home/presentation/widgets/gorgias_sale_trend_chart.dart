import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';

class DailyPerformanceChart extends StatelessWidget {
  final List<FlSpot> chartData;
  final List<String> xAxisLabels;
  final Color? lineColor;
  final Color? dotColor;
  final Color? gridColor;
  final Color? axisLabelColor;
  final Color? touchedLineColor;
  final Color? touchedSpotColor;
  final Color? touchedAreaColor;
  final double lineThickness;
  final double dotRadius;
  final double axisLabelFontSize;
  final double indicatorDotRadius;
  final double indicatorLineThickness;

  DailyPerformanceChart({
    super.key,
    required this.chartData,
    this.xAxisLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    this.lineColor,
    this.dotColor,
    this.gridColor,
    this.axisLabelColor,
    this.touchedLineColor,
    this.touchedSpotColor,
    this.touchedAreaColor,
    this.lineThickness = 3.0,
    this.dotRadius = 8.0,
    this.axisLabelFontSize = 12.0,
    this.indicatorDotRadius = 12.0,
    this.indicatorLineThickness = 2.0,
  }) : assert(xAxisLabels.length >= chartData.length);

  @override
  Widget build(BuildContext context) {
    final effectiveGridColor = gridColor ?? AppColors.border.withOpacity(0.1);
    final effectiveAxisLabelColor = axisLabelColor ?? AppColors.textSecondary;
    final effectiveLineColor = lineColor ?? AppColors.primary;
    final effectiveDotColor = dotColor ?? AppColors.textPrimary;
    final effectiveTouchedSpotColor = touchedSpotColor ?? AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: false,
            drawVerticalLine: true,
            getDrawingVerticalLine: (value) {
              return FlLine(color: effectiveGridColor, strokeWidth: 0.5);
            },
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < xAxisLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        xAxisLabels[index],
                        style: TextStyle(
                          color: effectiveAxisLabelColor,
                          fontSize: axisLabelFontSize,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: chartData,
              isCurved: true,
              barWidth: lineThickness,
              color: effectiveLineColor,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (index == 5) {
                    return FlDotCirclePainter(
                      radius: dotRadius,
                      color: effectiveDotColor,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          minX: 0,
          maxX: xAxisLabels.length - 1.0,
          minY: chartData.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1,
          maxY: chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1,
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '',
                    const TextStyle(color: Colors.transparent),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: touchedLineColor ?? AppColors.primary,
                    strokeWidth: indicatorLineThickness,
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, i) {
                      return FlDotCirclePainter(
                        radius: indicatorDotRadius,
                        color: effectiveTouchedSpotColor,
                        strokeWidth: 2,
                        strokeColor: AppColors.primary,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
