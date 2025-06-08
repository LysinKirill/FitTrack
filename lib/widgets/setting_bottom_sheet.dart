import 'package:flutter/material.dart';
import 'package:fit_track/models/user.dart';

class SettingsBottomSheet extends StatefulWidget {
  final User user;

  const SettingsBottomSheet({super.key, required this.user});

  @override
  _SettingsBottomSheetState createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  late TextEditingController _calorieController;
  late TextEditingController _waterController;

  @override
  void initState() {
    super.initState();
    _calorieController = TextEditingController(
      text: widget.user.dailyCalorieGoal.toString(),
    );
    _waterController = TextEditingController(
      text: widget.user.dailyWaterGoal.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Daily Goals', style: Theme.of(context).textTheme.titleLarge),
          TextField(
            controller: _calorieController,
            decoration: InputDecoration(
              labelText: 'Calorie Goal (kcal)',
              suffixIcon: Icon(Icons.local_fire_department),
            ),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _waterController,
            decoration: InputDecoration(
              labelText: 'Water Goal (ml)',
              suffixIcon: Icon(Icons.water_drop),
            ),
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(
            onPressed: _saveGoals,
            child: Text('Save Goals'),
          ),
        ],
      ),
    );
  }

  void _saveGoals() {
    // TODO: Implement save to database
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _calorieController.dispose();
    _waterController.dispose();
    super.dispose();
  }
}