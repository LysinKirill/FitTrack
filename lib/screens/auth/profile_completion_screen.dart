import 'package:flutter/material.dart';
import 'package:fit_track/models/user.dart';
import 'package:fit_track/services/database/user_repository.dart';
import 'package:fit_track/utils/calorie_calculator.dart';

import '../../services/database/db_helper.dart';
import '../home/main_app.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final User user;

  const ProfileCompletionScreen({super.key, required this.user});

  @override
  _ProfileCompletionScreenState createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _birthDateController;
  DateTime? _selectedBirthDate;
  String _selectedGender = 'male';
  String _selectedFitnessGoal = 'maintenance';
  String _selectedActivityLevel = 'moderate';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.user.height?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.user.weight?.toString() ?? '',
    );
    _birthDateController = TextEditingController(
      text:
          widget.user.birthDate != null
              ? '${widget.user.birthDate!.day}.${widget.user.birthDate!.month}.${widget.user.birthDate!.year}'
              : '',
    );
    _selectedGender = widget.user.gender;
    _selectedBirthDate = widget.user.birthDate;
    _selectedFitnessGoal = widget.user.fitnessGoal;
    _selectedActivityLevel = widget.user.activityLevel;
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text =
            "${picked.day}.${picked.month}.${picked.year}";
      });
    }
  }

  Future<void> _completeProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Calculate daily calorie goal based on user parameters
      int calorieGoal = widget.user.dailyCalorieGoal;
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);

      if (_selectedBirthDate != null) {
        // Create temporary user for calorie calculation
        final tempUser = User(
          name: widget.user.name,
          email: widget.user.email,
          password: widget.user.password,
          createdAt: widget.user.createdAt,
          birthDate: _selectedBirthDate,
          height: height,
          weight: weight,
          gender: _selectedGender,
          fitnessGoal: _selectedFitnessGoal,
          activityLevel: _selectedActivityLevel,
        );

        calorieGoal = CalorieCalculator.calculateDailyCalorieNeeds(tempUser);
      }

      // Create user with updated information and calculated calorie goal
      final updatedUser = User(
        id: widget.user.id,
        name: widget.user.name,
        email: widget.user.email,
        password: widget.user.password,
        createdAt: widget.user.createdAt,
        birthDate: _selectedBirthDate,
        height: height,
        weight: weight,
        gender: _selectedGender,
        fitnessGoal: _selectedFitnessGoal,
        activityLevel: _selectedActivityLevel,
        dailyCalorieGoal: calorieGoal,
        dailyWaterGoal: widget.user.dailyWaterGoal,
      );

      try {
        final userRepo = UserRepository(DatabaseHelper.instance);
        await userRepo.updateUser(updatedUser);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainApp(user: updatedUser)),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile update error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      // Explicitly set bottomNavigationBar to null to ensure it doesn't appear
      bottomNavigationBar: null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Help us personalize your experience',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(
                  labelText: 'Birth Date',
                  prefixIcon: Icon(Icons.cake),
                ),
                readOnly: true,
                onTap: () => _selectBirthDate(context),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gender',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildGenderSelector(),

              const SizedBox(height: 16),
              const Text(
                'What is your goal?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildFitnessGoalSelector(),

              const SizedBox(height: 16),
              const Text(
                'Activity Level',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildActivityLevelSelector(),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _completeProfile,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'SAVE PROFILE',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Male'),
            value: 'male',
            groupValue: _selectedGender,
            onChanged: (value) {
              setState(() {
                _selectedGender = value!;
              });
            },
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Female'),
            value: 'female',
            groupValue: _selectedGender,
            onChanged: (value) {
              setState(() {
                _selectedGender = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessGoalSelector() {
    final goals = CalorieCalculator.getFitnessGoals();

    return Column(
      children:
          goals.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: _selectedFitnessGoal,
              onChanged: (value) {
                setState(() {
                  _selectedFitnessGoal = value!;
                });
              },
            );
          }).toList(),
    );
  }

  Widget _buildActivityLevelSelector() {
    final activityLevels = CalorieCalculator.getActivityLevels();

    return Column(
      children:
          activityLevels.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: _selectedActivityLevel,
              onChanged: (value) {
                setState(() {
                  _selectedActivityLevel = value!;
                });
              },
            );
          }).toList(),
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
}
