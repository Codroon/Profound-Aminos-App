import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OrderDonutChart extends StatelessWidget {
  final double total;
  final Map<String, double> values;
  final Map<String, Color> colors;

  const OrderDonutChart({
    super.key,
    required this.total,
    required this.values,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = Colors.white;

    final totalSum = values.values.fold(0.0, (a, b) => a + b);

    return Column(
      children: [
        SizedBox(
          height: 200,
          width: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: 270,
                  sectionsSpace: 3,
                  centerSpaceRadius: 65,
                  sections:
                      values.entries.map((entry) {
                        final value = entry.value;
                        final label = entry.key;
                        final color = colors[label] ?? Colors.grey;

                        return PieChartSectionData(
                          color: color,
                          value: value,
                          radius: 25,
                          showTitle: false,
                        );
                      }).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Total',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.white10),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              values.keys.map((label) {
                return Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[label],
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ],
    );
  }
}
