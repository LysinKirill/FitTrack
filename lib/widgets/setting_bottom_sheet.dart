import 'package:flutter/material.dart';
import 'package:fit_track/models/user.dart';
import 'package:fit_track/services/database/db_helper.dart';
import 'package:fit_track/services/database/user_repository.dart';

class SettingsBottomSheet extends StatefulWidget {
  final User user;

  const SettingsBottomSheet({super.key, required this.user});

  @override
  _SettingsBottomSheetState createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  late TextEditingController _calorieController;
  late TextEditingController _waterController;
  late TextEditingController _weightController;
  bool _isSaving = false;
  final UserRepository _userRepository = UserRepository(
    DatabaseHelper.instance,
  );

  @override
  void initState() {
    super.initState();
    _calorieController = TextEditingController(
      text: widget.user.dailyCalorieGoal.toString(),
    );
    _waterController = TextEditingController(
      text: widget.user.dailyWaterGoal.toString(),
    );
    _weightController = TextEditingController(
      text: widget.user.weight?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Профиль и цели',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // User info section
          Text(
            'Информация о пользователе',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Текущий вес (кг)',
              suffixIcon: Icon(Icons.monitor_weight),
              hintText: 'Введите ваш текущий вес',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Daily goals section
          Text(
            'Дневные цели',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _calorieController,
            decoration: const InputDecoration(
              labelText: 'Цель по калориям (ккал)',
              suffixIcon: Icon(Icons.local_fire_department),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _waterController,
            decoration: const InputDecoration(
              labelText: 'Цель по воде (мл)',
              suffixIcon: Icon(Icons.water_drop),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isSaving ? null : _saveGoals,
            child:
                _isSaving
                    ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Сохранение...'),
                      ],
                    )
                    : const Text('Сохранить изменения'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGoals() async {
    // Validate inputs
    final calorieGoal = int.tryParse(_calorieController.text);
    final waterGoal = int.tryParse(_waterController.text);
    final weight =
        _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null;

    if (calorieGoal == null || waterGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите корректные числа')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _userRepository.updateUserGoals(
        userId: widget.user.id!,
        calorieGoal: calorieGoal,
        waterGoal: waterGoal,
        weight: weight,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Цели успешно обновлены')));
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка обновления целей: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _calorieController.dispose();
    _waterController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
