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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(userId: widget.user.id!),
      FoodDiaryScreen(userId: widget.user.id!),
      ActivityLogScreen(userId: widget.user.id!),
      ProgressChartsScreen(userId: widget.user.id!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        return !await _navigatorKey.currentState!.maybePop();
      },
      child: Scaffold(
        body: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (settings) {
            Widget page;

            if (settings.name == '/food_diary') {
              page = FoodDiaryScreen(userId: widget.user.id!);
              // Switch to the nutrition tab
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _currentIndex = 1);
              });
            } else if (settings.name == '/activity_log') {
              page = ActivityLogScreen(userId: widget.user.id!);
              // Switch to the activity tab
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _currentIndex = 2);
              });
            } else {
              // Default to the current screen
              page = _screens[_currentIndex];
            }

            return MaterialPageRoute(
              builder: (context) => page,
              settings: settings,
            );
          },
          initialRoute: '/',
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // If we're already on this tab, pop to root
            if (index == _currentIndex) {
              _navigatorKey.currentState!.popUntil((route) => route.isFirst);
            }
            setState(() => _currentIndex = index);

            // Navigate to the root of the selected tab
            _navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: 'Питание',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run),
              label: 'Активность',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: 'Прогресс',
            ),
          ],
        ),
      ),
    );
  }
}
