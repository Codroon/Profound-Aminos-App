import 'package:flutter/material.dart';
import 'package:woo_management_app/core/theme/app_colors.dart';

/// Beautiful 3-dot wave animation — each dot bounces up with a staggered delay.
class AnimatedDots extends StatefulWidget {
  final Color? color;
  final double dotSize;
  final double spacing;

  const AnimatedDots({
    super.key,
    this.color,
    this.dotSize = 8,
    this.spacing = 5,
  });

  @override
  State<AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const _count = 3;
  static const _duration = Duration(milliseconds: 600);
  static const _stagger = Duration(milliseconds: 160);

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _count,
      (i) => AnimationController(vsync: this, duration: _duration),
    );

    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    // Staggered start
    for (int i = 0; i < _count; i++) {
      Future.delayed(_stagger * i, () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(_count, (i) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          child: AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) {
              final v = _animations[i].value;
              return Transform.translate(
                offset: Offset(0, -8 * v),
                child: Opacity(
                  opacity: 0.4 + 0.6 * v,
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
