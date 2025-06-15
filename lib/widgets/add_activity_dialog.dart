import 'package:flutter/material.dart';
import '../models/activity_entry.dart';
import '../services/activity_service.dart';


class AddActivityDialog extends StatefulWidget {
  final String? initialActivityType;
  final double? userWeight;
  final DateTime selectedDate;

  const AddActivityDialog({
    super.key,
    this.initialActivityType,
    this.userWeight,
    required this.selectedDate,
  });

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _weightController = TextEditingController();

  String _activityType = 'Running';
  int? _calculatedCalories;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialActivityType != null) {
      _activityType = widget.initialActivityType!;
    }
    if (widget.userWeight != null) {
      _weightController.text = widget.userWeight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _calculateCalories() async {
    if (!_formKey.currentState!.validate()) return;
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите ваш вес')),
      );
      return;
    }

    setState(() => _isCalculating = true);

    try {
      final calories = await ActivityService.calculateCalories(
        activityType: _activityType,
        duration: int.parse(_durationController.text),
        weight: double.parse(_weightController.text),
      );

      setState(() {
        _calculatedCalories = calories;
        if (calories == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось рассчитать калории')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить активность'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _activityType,
                decoration: const InputDecoration(labelText: 'Тип активности'),
                items: ActivityEntry.activityTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _activityType = value!;
                    _calculatedCalories = null; // Reset when activity changes
                  });
                },
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Длительность (минуты)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите длительность';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Пожалуйста, введите корректное число';
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _calculatedCalories = null),
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Ваш вес (кг)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _calculatedCalories = null),
              ),
              const SizedBox(height: 16),
              if (_isCalculating)
                const CircularProgressIndicator()
              else if (_calculatedCalories != null)
                Text(
                  'Сожжено калорий: $_calculatedCalories',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculateCalories,
                child: const Text('Рассчитать калории'),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Заметки (необязательно)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _calculatedCalories != null) {
              final now = DateTime.now();
              final dateTime = DateTime(
                widget.selectedDate.year,
                widget.selectedDate.month,
                widget.selectedDate.day,
                now.hour,
                now.minute,
                now.second,
              );

              final activityEntry = ActivityEntry(
                name: _activityType, // Using the dropdown value as name
                activityType: _activityType,
                duration: int.parse(_durationController.text),
                caloriesBurned: _calculatedCalories!,
                dateTime: dateTime,
                notes: _notesController.text.isEmpty ? null : _notesController.text,
              );
              Navigator.of(context).pop(activityEntry);
            } else if (_calculatedCalories == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Пожалуйста, рассчитайте калории')),
              );
            }
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}