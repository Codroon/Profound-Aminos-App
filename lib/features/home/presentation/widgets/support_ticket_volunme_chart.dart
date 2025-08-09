import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SupportTicketVolumeChart extends StatelessWidget {
  final List<double>
  ticketVolumes; // List of ticket counts/volumes for each bar
  final Color? backgroundColor;
  final Color? barColor; // Color for the filled part of the bar
  final Color? barTrackColor; // Color for the background track of the bar
  final double barWidth;
  final double barBorderRadius;
  final EdgeInsetsGeometry padding;
  final double maxYValue; // Maximum Y value for the chart to scale

  const SupportTicketVolumeChart({
    super.key,
    required this.ticketVolumes,
    this.backgroundColor = const Color(
      0xFF1E1E28,
    ), // Dark background from image
    this.barColor = const Color(0xFF8A2BE2), // Bright purple for filled part
    this.barTrackColor = const Color(
      0xFF383842,
    ), // Darker grey/purple for track
    this.barWidth = 16.0, // Width of each bar
    this.barBorderRadius = 8.0, // Rounded corners for the bars
    this.padding = const EdgeInsets.all(16.0),
    this.maxYValue = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(enabled: true),
          titlesData: const FlTitlesData(
            show: false, // Hide all titles (X, Y, top, right)
          ),
          borderData: FlBorderData(
            show: false, // Hide chart border
          ),
          gridData: const FlGridData(
            show: false, // Hide grid lines
          ),
          alignment: BarChartAlignment.spaceAround,
          // Distribute bars evenly with space
          maxY: maxYValue,

          // Set the maximum Y value for chart scaling
          barGroups:
              ticketVolumes.asMap().entries.map((entry) {
                int index = entry.key;
                double volume = entry.value;
                return BarChartGroupData(
                  x: index, // X-coordinate for the bar group
                  barRods: [
                    BarChartRodData(
                      toY: volume,
                      // Height of the filled bar
                      color: barColor,
                      // Color of the filled bar
                      width: barWidth,
                      borderRadius: BorderRadius.circular(barBorderRadius),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxYValue,
                        color: barTrackColor,
                        // borderRadius: BorderRadius.circular(barBorderRadius),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}
