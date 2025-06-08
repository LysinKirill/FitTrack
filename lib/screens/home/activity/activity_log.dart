import 'package:flutter/material.dart';

class ActivityLogScreen extends StatelessWidget {
  final int userId;
  const ActivityLogScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Log')),
      body: const Center(child: Text('Activity Log Content')),
    );
  }
}