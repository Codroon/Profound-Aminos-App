import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/icons/app_logo.png', width: 148, height: 122),
    );
  }
}
