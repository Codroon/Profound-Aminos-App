import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CustomLoadingWidget extends StatefulWidget {
  final double size;
  final Color? color;
  final String? text;
  const CustomLoadingWidget({
    super.key,
    this.size = 56.0,
    this.color,
    this.text,
  });

  @override
  State<CustomLoadingWidget> createState() => _CustomLoadingWidgetState();
}

class _CustomLoadingWidgetState extends State<CustomLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _SpinnerPainter(
                  progress: _controller.value,
                  color: color,
                ),
              );
            },
          ),
        ),
        if (widget.text != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.text!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]
      ],
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;
  _SpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 6.28319, // 2*pi
      colors: [
        color.withOpacity(0.1),
        color.withOpacity(0.3),
        color.withOpacity(0.7),
        color,
      ],
      stops: const [0.0, 0.5, 0.85, 1.0],
      transform: GradientRotation(progress * 6.28319),
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      5.0,
      false,
      paint,
    );
    // Optional: subtle glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      5.0,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
} 