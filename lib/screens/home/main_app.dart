import 'package:flutter/material.dart';
import 'package:fit_track/screens/home/dashboard.dart';
import 'package:fit_track/screens/home/nutrition/food_diary.dart';
import 'package:fit_track/screens/home/activity/activity_log.dart';
import 'package:fit_track/screens/home/progress/progress_charts.dart';
import 'package:fit_track/services/database/db_helper.dart';

import '../../models/user.dart';

class MainApp extends StatefulWidget {
  final User user;

  const MainApp({super.key, required this.user});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();

  late final List<Widget> _screens;

  void _onDataChanged() {
    setState(() {
    });
  }

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(key: _dashboardKey, userId: widget.user.id!),
      FoodDiaryScreen(
        userId: widget.user.id!,
        onDataChanged: _onDataChanged,
        onCaloriesUpdated: (calories) {
          print("Calories updated in food diary: $calories");
          _dashboardKey.currentState?.updateCaloriesConsumed(calories);
        },
      ),
      ActivityLogScreen(userId: widget.user.id!),
      ProgressChartsScreen(userId: widget.user.id!),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFoodDiaryWithDashboard();
    });
  }

  Future<void> _syncFoodDiaryWithDashboard() async {
    print("Syncing food diary data with dashboard");
    final dbHelper = DatabaseHelper.instance;

    final db = await dbHelper.database;
    final users = await db.query('users');
    print('Found ${users.length} users in database');
    for (var user in users) {
      print('User: ${user['id']} - ${user['name']}');
    }

    final allEntries = await db.query('meal_entries');
    print('Total entries in meal_entries table: ${allEntries.length}');
    for (var entry in allEntries) {
      print(
        'Entry: ${entry['name']}, calories: ${entry['calories']}, user_id: ${entry['user_id']}',
      );
    }

    final calories = await dbHelper.getTotalCaloriesForDate(
      widget.user.id!,
      DateTime.now(),
    );

    print("Initial calories from database: $calories");
    if (calories > 0) {
      _dashboardKey.currentState?.updateCaloriesConsumed(calories);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !await _navigatorKey.currentState!.maybePop();
      },
      child: Scaffold(
        body: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (settings) {
            Widget page;

            if (settings.name == '/food_diary') {
              page = FoodDiaryScreen(
                userId: widget.user.id!,
                onDataChanged: _onDataChanged,
                onCaloriesUpdated: (calories) {
                  print("Calories updated in food diary: $calories");
                  _dashboardKey.currentState?.updateCaloriesConsumed(calories);
                },
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _currentIndex = 1);
              });
            } else if (settings.name == '/activity_log') {
              page = ActivityLogScreen(userId: widget.user.id!);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _currentIndex = 2);
              });
            } else {
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
            if (index == _currentIndex) {
              _navigatorKey.currentState!.popUntil((route) => route.isFirst);
            }

            if (index == 0) {
              print("Switching to dashboard tab, refreshing data");
              Future.delayed(Duration(milliseconds: 100), () async {
                final dbHelper = DatabaseHelper.instance;
                final calories = await dbHelper.getTotalCaloriesForDate(
                  widget
                      .user
                      .id!,
                  DateTime.now(),
                );

                print("Current calories from database: $calories");
                if (calories > 0) {
                  _dashboardKey.currentState?.updateCaloriesConsumed(calories);
                }

                _dashboardKey.currentState?.refreshData();
              });
            }

            setState(() => _currentIndex = index);

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
