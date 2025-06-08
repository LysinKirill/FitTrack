import 'package:fit_track/screens/auth/profile_completion_screen.dart';
import 'package:fit_track/utils/calorie_calculator.dart';
import 'package:flutter/material.dart';
import 'package:fit_track/services/auth_service.dart';

import '../../models/user.dart';
import '../home/main_app.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;

  const RegisterScreen({super.key, required this.authService});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;
  String _selectedGender = 'male';
  String _selectedFitnessGoal = 'maintenance';
  String _selectedActivityLevel = 'moderate';

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Пароли не совпадают')));
        return;
      }

      setState(() => _isLoading = true);

      final emailExists = await widget.authService.emailExists(
        _emailController.text,
      );
      if (emailExists) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Такой email уже существует')),
        );
        return;
      }

      // Create user with all parameters
      final user = User(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        createdAt: DateTime.now(),
        height:
            _heightController.text.isNotEmpty
                ? double.parse(_heightController.text)
                : null,
        weight:
            _weightController.text.isNotEmpty
                ? double.parse(_weightController.text)
                : null,
        birthDate: _selectedBirthDate,
        gender: _selectedGender,
        fitnessGoal: _selectedFitnessGoal,
        activityLevel: _selectedActivityLevel,
      );

      // Calculate daily calorie goal if all required parameters are present
      int calorieGoal = 2000; // Default value
      if (user.height != null &&
          user.weight != null &&
          user.birthDate != null) {
        calorieGoal = CalorieCalculator.calculateDailyCalorieNeeds(user);
      }

      // Create final user with calculated calorie goal
      final userToRegister = User(
        name: user.name,
        email: user.email,
        password: user.password,
        createdAt: user.createdAt,
        height: user.height,
        weight: user.weight,
        birthDate: user.birthDate,
        gender: user.gender,
        fitnessGoal: user.fitnessGoal,
        activityLevel: user.activityLevel,
        dailyCalorieGoal: calorieGoal,
        dailyWaterGoal: user.dailyWaterGoal,
      );

      final id = await widget.authService.registerUser(userToRegister);
      setState(() => _isLoading = false);

      if (id > 0) {
        final newUser = await widget.authService.loginUser(
          _emailController.text,
          _passwordController.text,
        );

        if (newUser != null) {
          if (newUser.height == null || newUser.weight == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileCompletionScreen(user: newUser),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainApp(user: newUser)),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка регистрации')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать аккаунт'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Text(
                    'Ваш путь к здоровью начинается здесь',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Account Information Section
                  _buildSectionHeader('Информация об аккаунте'),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Имя',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Пожалуйста, введите ваше имя';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Эл. почта',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Пожалуйста, введите вашу эл. почту';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Пароль',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Пожалуйста, введите пароль';
                              }
                              if (value.length < 6) {
                                return 'Пароль должен содержать не менее 6 символов';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Подтвердите пароль',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Пожалуйста, подтвердите пароль';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Physical Information Section
                  _buildSectionHeader('Физические параметры'),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _heightController,
                            decoration: const InputDecoration(
                              labelText: 'Рост (см)',
                              prefixIcon: Icon(Icons.height),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'Вес (кг)',
                              prefixIcon: Icon(Icons.monitor_weight),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _birthDateController,
                            decoration: InputDecoration(
                              labelText: 'Дата рождения',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.edit_calendar),
                                onPressed: () => _selectBirthDate(context),
                              ),
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Пол',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildGenderSelector(),
                        ],
                      ),
                    ),
                  ),

                  // Fitness Goals Section
                  _buildSectionHeader('Цели фитнеса'),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Какова ваша цель?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildFitnessGoalSelector(),
                          const SizedBox(height: 16),
                          const Text(
                            'Уровень активности',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildActivityLevelSelector(),
                        ],
                      ),
                    ),
                  ),

                  // Register Button
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: const Text(
                          'СОЗДАТЬ АККАУНТ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Мужской'),
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
            title: const Text('Женский'),
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

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
}
