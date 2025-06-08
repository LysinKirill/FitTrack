import 'package:flutter/material.dart';

class ProgressChartsScreen extends StatelessWidget {
  final int userId;
  const ProgressChartsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Charts')),
      body: const Center(child: Text('Progress Charts Content')),
    );
  }
}