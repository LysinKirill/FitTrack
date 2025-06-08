import 'package:flutter/material.dart';
import 'package:fit_track/screens/home/dashboard.dart';
import 'package:fit_track/screens/home/nutrition/food_diary.dart';
import 'package:fit_track/screens/home/activity/activity_log.dart';
import 'package:fit_track/screens/home/progress/progress_charts.dart';

import '../../models/user.dart';

class MainApp extends StatefulWidget {
  final User user;

  const MainApp({Key? key, required this.user}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const FoodDiaryScreen(),
    const ActivityLogScreen(),
    const ProgressChartsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}