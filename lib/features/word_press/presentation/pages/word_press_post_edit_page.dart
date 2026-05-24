import 'package:flutter/material.dart';

class WordPressPostEditPage extends StatelessWidget {
  final Map<String, dynamic> post;
  final dynamic bloc;

  const WordPressPostEditPage({super.key, required this.post, this.bloc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Post')),
      body: const Center(child: Text('Coming Soon')),
    );
  }
}
