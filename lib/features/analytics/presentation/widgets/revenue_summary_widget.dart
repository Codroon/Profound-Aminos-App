import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';
import 'package:woo_management_app/widgets/app_reusable_text.dart';

import '../../../../widgets/percent_badge.dart'; // Import fl_chart

class SalesOverviewCard extends StatelessWidget {
  final String title;
  final double salesAmount;
  final String currencySymbol;
  final double percentageChange; // e.g., -21.0 for -21%
  final List<FlSpot> chartData; // Data points for the line chart
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? salesAmountColor;
  final Color? percentageChangeColor; // Color for the percentage text
  final Color?
  percentageChangeBackgroundColor; // Color for the percentage badge background
  final Color? chartLineColor;
  final Color? chartAreaColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double titleFontSize;
  final double salesAmountFontSize;
  final double percentageFontSize;

  SalesOverviewCard({
    super.key,
    this.title = 'Total Sales',
    required this.salesAmount,
    this.currencySymbol = '\$',
    required this.percentageChange,
    required this.chartData,
    this.backgroundColor,
    this.titleColor,
    this.salesAmountColor = Colors.white,
    this.percentageChangeColor = Colors.white,
    this.percentageChangeBackgroundColor,
    this.chartLineColor,
    this.chartAreaColor,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(16.0),
    this.titleFontSize = 16.0,
    this.salesAmountFontSize = 26.0,
    this.percentageFontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    Color effectivePercentageChangeBgColor = percentageChangeBackgroundColor ?? AppColors.chartRed;
    // You could add logic here to change color based on positive/negative change
    // For now, based on image, it's red.
    // if (percentageChange > 0) {
    //   effectivePercentageChangeBgColor = Colors.green;
    // }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Sales Title
        AppReusableText(
          maxLines: 2,
          text: title,
          fontSize: titleFontSize,
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.greyB3,
        ),
        const SizedBox(height: 4.0),
        // Sales Amount
        AppReusableText(
          text: '$currencySymbol${salesAmount.toStringAsFixed(2)}',
          fontWeight: FontWeight.w400,
          color: salesAmountColor,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PercentageBadge(
                percentageChange: "$percentageChange",
                backgroundColor: effectivePercentageChangeBgColor,
                textColor: percentageChangeColor!,
                fontSize: percentageFontSize,
              ),
              const SizedBox(width: 16.0),
              // Line Chart
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(
                        show: false,
                      ), // Hide grid lines
                      titlesData: const FlTitlesData(
                        show: false,
                      ), // Hide axis titles
                      borderData: FlBorderData(show: false), // Hide border
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData.isNotEmpty 
                              ? chartData 
                              : [const FlSpot(0, 0), const FlSpot(1, 0)], // Show flat line when no data
                          isCurved: false,
                          barWidth: 3,
                          color: chartLineColor ?? AppColors.chartRed,
                          dotData: const FlDotData(
                            show: false,
                          ), // Hide data points
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                (chartAreaColor ?? AppColors.chartRed).withOpacity(0.5),
                                (chartAreaColor ?? AppColors.chartRed).withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: chartData.length <= 1 
                          ? 1.0 
                          : chartData.length.toDouble() - 1,
                      minY: chartData.isNotEmpty 
                          ? chartData.map((e) => e.y).reduce((a, b) => a < b ? a : b) 
                          : 0, // Dynamic min Y
                      maxY: chartData.isNotEmpty 
                          ? chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.1 
                          : 1, // Dynamic max Y with some buffer
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
