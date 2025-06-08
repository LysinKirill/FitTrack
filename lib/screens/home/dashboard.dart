import 'package:flutter/material.dart';
import 'package:fit_track/widgets/dashboard_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual data from database
    final dailyCalories = 1850;
    final remainingCalories = 450;
    final waterIntake = 5;
    final steps = 7543;
    final protein = 120;
    final carbs = 180;
    final fat = 50;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Calories',
                    value: '$remainingCalories',
                    unit: 'kcal left',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: DashboardCard(
                    title: 'Water',
                    value: '$waterIntake',
                    unit: 'glasses',
                    icon: Icons.local_drink,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Steps',
                    value: '$steps',
                    unit: 'today',
                    icon: Icons.directions_walk,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: DashboardCard(
                    title: 'Macros',
                    value: '${protein}g/${carbs}g/${fat}g',
                    unit: 'P/C/F',
                    icon: Icons.pie_chart,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            // Quick Actions
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildQuickActionButton(
                  context,
                  'Add Meal',
                  Icons.restaurant,
                  Colors.blue,
                      () {
                    // Navigate to add meal
                  },
                ),
                _buildQuickActionButton(
                  context,
                  'Log Exercise',
                  Icons.directions_run,
                  Colors.green,
                      () {
                    // Navigate to log exercise
                  },
                ),
                _buildQuickActionButton(
                  context,
                  'Weigh In',
                  Icons.monitor_weight,
                  Colors.orange,
                      () {
                    // Navigate to weight input
                  },
                ),
                _buildQuickActionButton(
                  context,
                  'Water',
                  Icons.local_drink,
                  Colors.lightBlue,
                      () {
                    // Navigate to water intake
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }
}