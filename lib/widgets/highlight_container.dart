import 'package:flutter/material.dart';

class HighlightContainer extends StatefulWidget {
  final Widget child;
  final bool isHighlighted;
  final Color? highlightColor;
  final Duration duration;
  final BorderRadius borderRadius;

  const HighlightContainer({
    super.key,
    required this.child,
    required this.isHighlighted,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 2000),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<HighlightContainer> createState() => _HighlightContainerState();
}

class _HighlightContainerState extends State<HighlightContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Fade-in, hold, fade-out animation sequence
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15.0, // Fade in quickly (15% of total time)
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70.0, // Hold highlight (70% of total time)
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15.0, // Fade out smoothly (15% of total time)
      ),
    ]).animate(_controller);

    if (widget.isHighlighted) {
      // Delay slightly for smoother visual entry when page transitions
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant HighlightContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).primaryColor.withOpacity(0.18);
    final activeColor = widget.highlightColor ?? defaultColor;

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            children: [
              widget.child,
              if (_opacityAnimation.value > 0.0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(
                          activeColor.opacity * _opacityAnimation.value,
                        ),
                        borderRadius: widget.borderRadius,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
