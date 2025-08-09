import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<double> data;

  const WeeklyBarChart({
    super.key,
    this.data = const [3, 5, 8, 6, 4, 2, 7, 9, 3, 6, 8, 4, 5, 6],
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic maxY based on actual data
    final List<double> actualData = widget.data.isNotEmpty ? widget.data : [3, 5, 8, 6, 4, 2, 7];
    final double maxValue = actualData.isNotEmpty ? actualData.reduce((a, b) => a > b ? a : b) : 10;
    final double dynamicMaxY = maxValue > 0 ? (maxValue * 1.2).ceilToDouble() : 10; // Add 20% padding and round up
    
    // Debug information
    print('[WeeklyBarChart] Received data: ${widget.data}');
    print('[WeeklyBarChart] Using data: $actualData');
    print('[WeeklyBarChart] Max value: $maxValue, Dynamic maxY: $dynamicMaxY');
    
    return Container(
      height: 317,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return BarChart(
                  BarChartData(
                    maxY: dynamicMaxY,
                    minY: 0,
                    groupsSpace: 10,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const labels = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            final dayIndex = (value.toInt() / 2).floor();
                            if (dayIndex >= 0 && dayIndex < labels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[dayIndex],
                                  style: const TextStyle(
                                    color: Color(0xFF8B8B9A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          interval: 2,
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: _buildBarGroups(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final List<BarChartGroupData> groups = [];
    
    // Use real data passed from parent, fallback to default if empty
    final List<double> actualData = widget.data.isNotEmpty ? widget.data : [3, 5, 8, 6, 4, 2, 7];
    
    // Ensure we have exactly 7 days of data
    final List<double> weekData = List.generate(7, (index) {
      return index < actualData.length ? actualData[index] : 0.0;
    });

    for (int i = 0; i < weekData.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i * 2,
          groupVertically: false,
          barRods: [
            BarChartRodData(
              toY: weekData[i] * _animation.value,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.primaryGradient,
              ),
              width: 13.6,
              borderRadius: BorderRadius.all(Radius.circular(3.2)),
            ),
          ],
        ),
      );
    }

    return groups;
  }
}

// class AnimatedBarChart extends StatefulWidget {
//   final List<double> data;
//   final List<String> labels;
//   final Duration animationDuration;
//   final Color? backgroundColor;
//   final List<Color>? barColors;
//   final double barWidth;
//   final double spacing;
//   final double maxHeight;
//   final TextStyle? labelStyle;
//   final EdgeInsets padding;
//
//   const AnimatedBarChart({
//     Key? key,
//     required this.data,
//     required this.labels,
//     this.animationDuration = const Duration(milliseconds: 1500),
//     this.backgroundColor,
//     this.barColors,
//     this.barWidth = 24.0,
//     this.spacing = 20.0,
//     this.maxHeight = 200.0,
//     this.labelStyle,
//     this.padding = const EdgeInsets.all(20.0),
//   }) : assert(data.length == labels.length, 'Data and labels must have same length'),
//         super(key: key);
//
//   @override
//   State<AnimatedBarChart> createState() => _AnimatedBarChartState();
// }
//
// class _AnimatedBarChartState extends State<AnimatedBarChart>
//     with TickerProviderStateMixin {
//   late AnimationController _animationController;
//   late List<Animation<double>> _barAnimations;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _setupAnimations();
//     _startAnimation();
//   }
//
//   void _setupAnimations() {
//     _animationController = AnimationController(
//       duration: widget.animationDuration,
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
//     ));
//
//     // Create staggered animations for each bar
//     _barAnimations = List.generate(widget.data.length, (index) {
//       final double startTime = 0.2 + (index * 0.1);
//       final double endTime = (startTime + 0.6).clamp(0.0, 1.0);
//
//       return Tween<double>(
//         begin: 0.0,
//         end: 1.0,
//       ).animate(CurvedAnimation(
//         parent: _animationController,
//         curve: Interval(
//           startTime,
//           endTime,
//           curve: Curves.elasticOut,
//         ),
//       ));
//     });
//   }
//
//   void _startAnimation() {
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: widget.padding,
//       decoration: BoxDecoration(
//         color: widget.backgroundColor ?? const Color(0xFF1A1B2E),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: AnimatedBuilder(
//         animation: _animationController,
//         builder: (context, child) {
//           return FadeTransition(
//             opacity: _fadeAnimation,
//             child: _buildChart(),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildChart() {
//     final double maxValue = widget.data.reduce((a, b) => a > b ? a : b);
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Chart bars
//         Container(
//           height: widget.maxHeight,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: List.generate(widget.data.length, (index) {
//               return _buildBar(index, maxValue);
//             }),
//           ),
//         ),
//         const SizedBox(height: 20),
//         // Labels
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: List.generate(widget.labels.length, (index) {
//             return _buildLabel(index);
//           }),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBar(int index, double maxValue) {
//     final double normalizedHeight = (widget.data[index] / maxValue) * widget.maxHeight;
//
//     return AnimatedBuilder(
//       animation: _barAnimations[index],
//       builder: (context, child) {
//         return Container(
//           width: widget.barWidth,
//           height: normalizedHeight * _barAnimations[index].value,
//           decoration: BoxDecoration(
//             gradient: _getBarGradient(index),
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: _getBarColor(index).withOpacity(0.3),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildLabel(int index) {
//     return AnimatedBuilder(
//       animation: _fadeAnimation,
//       builder: (context, child) {
//         return Opacity(
//           opacity: _fadeAnimation.value,
//           child: Text(
//             widget.labels[index],
//             style: widget.labelStyle ?? const TextStyle(
//               color: Color(0xFF8B8FA8),
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   LinearGradient _getBarGradient(int index) {
//     final Color barColor = _getBarColor(index);
//     return LinearGradient(
//       begin: Alignment.bottomCenter,
//       end: Alignment.topCenter,
//       colors: [
//         barColor.withOpacity(0.8),
//         barColor,
//         barColor.withOpacity(0.9),
//       ],
//       stops: const [0.0, 0.5, 1.0],
//     );
//   }
//
//   Color _getBarColor(int index) {
//     if (widget.barColors != null && widget.barColors!.isNotEmpty) {
//       return widget.barColors![index % widget.barColors!.length];
//     }
//
//     // Default purple gradient colors
//     final List<Color> defaultColors = [
//       const Color(0xFF6C5CE7),
//       const Color(0xFF8B7CF5),
//       const Color(0xFFA29BFE),
//       const Color(0xFF74B9FF),
//       const Color(0xFF0984E3),
//     ];
//
//     return defaultColors[index % defaultColors.length];
//   }
// }
