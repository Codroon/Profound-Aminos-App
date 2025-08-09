import 'package:flutter/material.dart';

class AuthBackgroundGradient extends StatelessWidget {
  final Widget? child;
  const AuthBackgroundGradient({super.key, this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE0BBE4), // Lighter pinkish-purple
            Color(0xFF957DAD), // Medium purple
            Color(0xFF6B4B8E), // Darker purplish-blue
          ],

          /// Adjust these stops to fine-tune the color distribution
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
