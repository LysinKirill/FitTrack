import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/database/db_helper.dart';
import '../../services/database/user_repository.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/setting_bottom_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<User> _userFuture;
  final UserRepository _userRepository = UserRepository(DatabaseHelper.instance);

  @override
  void initState() {
    super.initState();
    _userFuture = _userRepository.getUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final user = snapshot.data!;
        // TODO: Calculate these from daily logs
        final caloriesConsumed = 1200;
        final waterConsumed = 800;
        final remainingCalories = user.dailyCalorieGoal - caloriesConsumed;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettings(context, user),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Update cards to use real data
                DashboardCard(
                  title: 'Calories',
                  value: '$remainingCalories',
                  unit: 'of ${user.dailyCalorieGoal} kcal left',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
                // ... other cards
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SettingsBottomSheet(user: user);
      },
    );
  }
}