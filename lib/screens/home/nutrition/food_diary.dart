import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/models/meal_entry.dart';
import 'package:fit_track/services/database/db_helper.dart';
import '../../../widgets/food_search_dialog.dart';

class FoodDiaryScreen extends StatefulWidget {
  final int userId;
  final VoidCallback? onDataChanged;
  final Function(int)? onCaloriesUpdated;

  const FoodDiaryScreen({
    super.key,
    required this.userId,
    this.onDataChanged,
    this.onCaloriesUpdated,
  });

  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  DateTime _selectedDate = DateTime.now();
  List<MealEntry> _mealEntries = [];
  late int _userId;


  int _totalCalories = 0;
  double _totalProteins = 0;
  double _totalFats = 0;
  double _totalCarbs = 0;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId; // Always use the user ID passed from the parent
    _loadMealEntries(); // Load meal entries directly without _ensureUserExists
  }

  Future<void> _loadMealEntries() async {
    print('Loading entries for date: ${_selectedDate.toString()}');
    final entries = await _dbHelper.getMealEntriesByDate(
      _userId,
      _selectedDate,
    );
    print('Loaded ${entries.length} entries from database');
    if (entries.isNotEmpty) {
      for (var entry in entries) {
        print(
          'Entry: ${entry.name}, type: ${entry.mealType}, date: ${entry.dateTime}',
        );
      }
    }
    setState(() {
      _mealEntries = entries;
      _calculateNutritionSummary();
    });
  }

  void _calculateNutritionSummary() {
    int calories = 0;
    double proteins = 0;
    double fats = 0;
    double carbs = 0;

    for (var entry in _mealEntries) {
      calories += entry.calories;
      proteins += entry.proteins;
      fats += entry.fats;
      carbs += entry.carbs;
    }

    setState(() {
      _totalCalories = calories;
      _totalProteins = proteins;
      _totalFats = fats;
      _totalCarbs = carbs;
    });

    // Notify parent about calories update
    if (widget.onCaloriesUpdated != null) {
      print('Directly updating calories: $calories');
      widget.onCaloriesUpdated!(calories);
    } else {
      print('No onCaloriesUpdated callback provided');
    }

    // Notify parent that data has changed
    if (widget.onDataChanged != null) {
      print('Notifying parent that data has changed');
      widget.onDataChanged!();
    } else {
      print('No onDataChanged callback provided');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMealEntries();
    }
  }

  Future<void> _addMealEntry() async {
    final result = await showDialog<MealEntry>(
      context: context,
      builder: (context) => AddMealDialog(),
    );

    if (result != null) {
      print('Adding meal: ${result.name}, type: ${result.mealType}');
      final id = await _dbHelper.insertMealEntry(result, _userId);
      print('Meal added with ID: $id');
      await _loadMealEntries();
      print('Loaded ${_mealEntries.length} entries after adding');

      // Notify parent about calories update
      if (widget.onCaloriesUpdated != null) {
        print('Directly updating calories: $_totalCalories');
        widget.onCaloriesUpdated!(_totalCalories);
      } else {
        print('No onCaloriesUpdated callback provided');
      }

      // Notify parent that data has changed
      if (widget.onDataChanged != null) {
        print('Notifying parent that data has changed');
        widget.onDataChanged!();
      } else {
        print('No onDataChanged callback provided');
      }
    }
  }

  Future<void> _deleteMealEntry(int id) async {
    await _dbHelper.deleteMealEntry(id);
    _loadMealEntries();

    // Notify parent about calories update
    if (widget.onCaloriesUpdated != null) {
      print('Directly updating calories: $_totalCalories');
      widget.onCaloriesUpdated!(_totalCalories);
    }

    // Notify parent that data has changed
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
  }

  // Debug method to add a test meal entry
  Future<void> _addTestMealEntry() async {
    final testMeal = MealEntry(
      name: 'Test Food',
      mealType: 'Завтрак',
      calories: 300,
      proteins: 20.0,
      fats: 10.0,
      carbs: 30.0,
      dateTime: DateTime.now(),
    );

    print('Adding test meal: ${testMeal.name}, type: ${testMeal.mealType}');
    final id = await _dbHelper.insertMealEntry(testMeal, _userId);
    print('Test meal added with ID: $id');
    await _loadMealEntries();
    print('Loaded ${_mealEntries.length} entries after adding test meal');

    // Notify parent about calories update
    if (widget.onCaloriesUpdated != null) {
      print('Directly updating calories: $_totalCalories');
      widget.onCaloriesUpdated!(_totalCalories);
    }

    // Notify parent that data has changed
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Тестовая еда добавлена')));
  }

  @override
  Widget build(BuildContext context) {
    // Group meal entries by meal type
    Map<String, List<MealEntry>> groupedEntries = {};
    for (var type in MealEntry.mealTypes) {
      groupedEntries[type] =
          _mealEntries.where((entry) => entry.mealType == type).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дневник питания'),
        actions: [
          // Debug button to add test meal
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _addTestMealEntry,
          ),
          // Debug button to clear all entries
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final count = await _dbHelper.clearMealEntries();
              print('Cleared $count meal entries');
              _loadMealEntries();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Удалено $count записей о приеме пищи')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date display
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(
                        const Duration(days: 1),
                      );
                    });
                    _loadMealEntries();
                  },
                ),
                Text(
                  DateFormat('EEEE, d MMMM').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(
                        const Duration(days: 1),
                      );
                    });
                    _loadMealEntries();
                  },
                ),
              ],
            ),
          ),

          // Nutrition summary card
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Дневная сводка',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutrientColumn(
                        'Калории',
                        _totalCalories.toString(),
                        Colors.red,
                      ),
                      _buildNutrientColumn(
                        'Белки',
                        '${_totalProteins.toStringAsFixed(1)}г',
                        Colors.blue,
                      ),
                      _buildNutrientColumn(
                        'Жиры',
                        '${_totalFats.toStringAsFixed(1)}г',
                        Colors.yellow.shade800,
                      ),
                      _buildNutrientColumn(
                        'Углеводы',
                        '${_totalCarbs.toStringAsFixed(1)}г',
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Meal entries list
          Expanded(
            child: ListView.builder(
              itemCount: MealEntry.mealTypes.length,
              itemBuilder: (context, index) {
                final mealType = MealEntry.mealTypes[index];
                final entries = groupedEntries[mealType] ?? [];

                return ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(mealType),
                      if (entries.isNotEmpty)
                        Text(
                          '${entries.fold<int>(0, (sum, entry) => sum + entry.calories)} ккал',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  initiallyExpanded: true,
                  children: [
                    ...entries.map((entry) => _buildMealEntryTile(entry)),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Добавить еду'),
                      onTap: () async {
                        final result = await showDialog<MealEntry>(
                          context: context,
                          builder: (context) => FoodSearchDialog(initialMealType: mealType),
                        );

                        if (result != null) {
                          final id = await _dbHelper.insertMealEntry(
                            result,
                            _userId,
                          );
                          print('Added meal entry with ID: $id');
                          await _loadMealEntries();

                          // Notify parent about calories update
                          if (widget.onCaloriesUpdated != null) {
                            print(
                              'Directly updating calories: $_totalCalories',
                            );
                            widget.onCaloriesUpdated!(_totalCalories);
                          } else {
                            print('No onCaloriesUpdated callback provided');
                          }

                          // Notify parent that data has changed
                          if (widget.onDataChanged != null) {
                            print('Notifying parent that data has changed');
                            widget.onDataChanged!();
                          } else {
                            print('No onDataChanged callback provided');
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMealEntry,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNutrientColumn(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMealEntryTile(MealEntry entry) {
    return ListTile(
      title: Text(entry.name),
      subtitle: Text(
        'Б: ${entry.proteins.toStringAsFixed(1)}г | Ж: ${entry.fats.toStringAsFixed(1)}г | У: ${entry.carbs.toStringAsFixed(1)}г',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${entry.calories} ккал',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteMealEntry(entry.id!),
          ),
        ],
      ),
    );
  }
}

class AddMealDialog extends StatefulWidget {
  final String? initialMealType;

  const AddMealDialog({super.key, this.initialMealType});

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _carbsController = TextEditingController();

  String _mealType = 'Завтрак';

  @override
  void initState() {
    super.initState();
    if (widget.initialMealType != null) {
      _mealType = widget.initialMealType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить еду'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _mealType,
                decoration: const InputDecoration(labelText: 'Тип приема пищи'),
                items:
                    MealEntry.mealTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _mealType = value!;
                  });
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название еды'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название еды';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Калории'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите калории';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Пожалуйста, введите корректное число';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _proteinsController,
                decoration: const InputDecoration(labelText: 'Белки (г)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите белки';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Пожалуйста, введите корректное число';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fatsController,
                decoration: const InputDecoration(labelText: 'Жиры (г)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите жиры';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Пожалуйста, введите корректное число';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _carbsController,
                decoration: const InputDecoration(labelText: 'Углеводы (г)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите углеводы';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Пожалуйста, введите корректное число';
                  }
                  return null;
                },
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
            if (_formKey.currentState!.validate()) {
              final mealEntry = MealEntry(
                name: _nameController.text,
                mealType: _mealType,
                calories: int.parse(_caloriesController.text),
                proteins: double.parse(_proteinsController.text),
                fats: double.parse(_fatsController.text),
                carbs: double.parse(_carbsController.text),
                dateTime: DateTime.now(),
              );
              Navigator.of(context).pop(mealEntry);
            }
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}
