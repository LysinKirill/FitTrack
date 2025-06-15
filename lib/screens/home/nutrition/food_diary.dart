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
    _userId = widget.userId;
    _loadMealEntries();
  }

  Future<void> _loadMealEntries() async {
    final entries = await _dbHelper.getMealEntriesByDate(
      _userId,
      _selectedDate,
    );
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

    if (widget.onCaloriesUpdated != null) {
      widget.onCaloriesUpdated!(calories);
    }

    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
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
      builder: (context) => AddMealDialog(selectedDate: _selectedDate),
    );

    if (result != null) {
      await _loadMealEntries();

      if (widget.onCaloriesUpdated != null) {
        widget.onCaloriesUpdated!(_totalCalories);
      }

      if (widget.onDataChanged != null) {
        widget.onDataChanged!();
      }
    }
  }

  Future<void> _deleteMealEntry(int id) async {
    await _dbHelper.deleteMealEntry(id);
    _loadMealEntries();

    if (widget.onCaloriesUpdated != null) {
      widget.onCaloriesUpdated!(_totalCalories);
    }

    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
  }

  Future<void> _addTestMealEntry() async {
    await _loadMealEntries();

    if (widget.onCaloriesUpdated != null) {
      widget.onCaloriesUpdated!(_totalCalories);
    }

    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Test food added')));
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<MealEntry>> groupedEntries = {};
    for (var type in MealEntry.mealTypes) {
      groupedEntries[type] =
          _mealEntries.where((entry) => entry.mealType == type).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _addTestMealEntry,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final count = await _dbHelper.clearMealEntries();
              _loadMealEntries();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted $count meal entries')),
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

          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutrientColumn(
                        'Calories',
                        _totalCalories.toString(),
                        Colors.red,
                      ),
                      _buildNutrientColumn(
                        'Protein',
                        '${_totalProteins.toStringAsFixed(1)}г',
                        Colors.blue,
                      ),
                      _buildNutrientColumn(
                        'Fats',
                        '${_totalFats.toStringAsFixed(1)}г',
                        Colors.yellow.shade800,
                      ),
                      _buildNutrientColumn(
                        'Carbs',
                        '${_totalCarbs.toStringAsFixed(1)}г',
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

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
                          '${entries.fold<int>(0, (sum, entry) => sum + entry.calories)} kcal',
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
                      title: const Text('Add Food'),
                      onTap: () async {
                        final result = await showDialog<MealEntry>(
                          context: context,
                          builder:
                              (context) => FoodSearchDialog(
                                initialMealType: mealType,
                                selectedDate: _selectedDate,
                              ),
                        );

                        if (result != null) {
                          await _loadMealEntries();

                          if (widget.onCaloriesUpdated != null) {
                            widget.onCaloriesUpdated!(_totalCalories);
                          }

                          if (widget.onDataChanged != null) {
                            widget.onDataChanged!();
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
        'P: ${entry.proteins.toStringAsFixed(1)}g | F: ${entry.fats.toStringAsFixed(1)}g | C: ${entry.carbs.toStringAsFixed(1)}g',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${entry.calories} kcal',
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
  final DateTime selectedDate;

  const AddMealDialog({
    super.key,
    this.initialMealType,
    required this.selectedDate,
  });

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

  String _mealType = 'Breakfast';

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
      title: const Text('Add Food'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _mealType,
                decoration: const InputDecoration(labelText: 'Meal Type'),
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
                decoration: const InputDecoration(labelText: 'Food Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter food name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter calories';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _proteinsController,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter protein';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fatsController,
                decoration: const InputDecoration(labelText: 'Fats (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter fats';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _carbsController,
                decoration: const InputDecoration(labelText: 'Carbs (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter carbs';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final now = DateTime.now();
              final dateTime = DateTime(
                widget.selectedDate.year,
                widget.selectedDate.month,
                widget.selectedDate.day,
                now.hour,
                now.minute,
                now.second,
              );

              final mealEntry = MealEntry(
                name: _nameController.text,
                mealType: _mealType,
                calories: int.parse(_caloriesController.text),
                proteins: double.parse(_proteinsController.text),
                fats: double.parse(_fatsController.text),
                carbs: double.parse(_carbsController.text),
                dateTime: dateTime,
              );
              Navigator.of(context).pop(mealEntry);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
