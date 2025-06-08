import 'package:flutter/material.dart';

class FoodDiaryScreen extends StatelessWidget {
  const FoodDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Diary')),
      body: const Center(child: Text('Food Diary Content')),
    );
  }
}