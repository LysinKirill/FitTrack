import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/models/meal_entry.dart';
import 'package:fit_track/services/database/db_helper.dart';
import '../../../widgets/food_search_dialog.dart';

class FoodDiaryScreen extends StatefulWidget {
  final int userId;

  const FoodDiaryScreen({super.key, required this.userId});

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
    _ensureUserExists().then((_) => _loadMealEntries());
  }

  Future<void> _ensureUserExists() async {
    final db = await _dbHelper.database;
    final users = await db.query('users');
    print('Found ${users.length} users in database');

    if (users.isEmpty) {
      print('No users found, creating a test user');
      final now = DateTime.now().toIso8601String();
      final userId = await db.insert('users', {
        'name': 'Test User',
        'email': 'test@example.com',
        'password': 'password123',
        'created_at': now,
      });
      print('Created test user with ID: $userId');
      setState(() {
        _userId = userId;
      });
    } else {
      print('Using existing user with ID: ${users.first['id']}');
      setState(() {
        _userId = users.first['id'] as int;
      });
    }
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
    _totalCalories = 0;
    _totalProteins = 0;
    _totalFats = 0;
    _totalCarbs = 0;

    for (var entry in _mealEntries) {
      _totalCalories += entry.calories;
      _totalProteins += entry.proteins;
      _totalFats += entry.fats;
      _totalCarbs += entry.carbs;
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
    }
  }

  Future<void> _deleteMealEntry(int id) async {
    await _dbHelper.deleteMealEntry(id);
    _loadMealEntries();
  }

  // Debug method to add a test meal entry
  Future<void> _addTestMealEntry() async {
    final testMeal = MealEntry(
      name: 'Test Food',
      mealType: 'Breakfast',
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Test meal added')));
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
        title: const Text('Food Diary'),
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
                SnackBar(content: Text('Cleared $count meal entries')),
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
                  DateFormat('EEEE, MMMM d').format(_selectedDate),
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
                        '${_totalProteins.toStringAsFixed(1)}g',
                        Colors.blue,
                      ),
                      _buildNutrientColumn(
                        'Fats',
                        '${_totalFats.toStringAsFixed(1)}g',
                        Colors.yellow.shade800,
                      ),
                      _buildNutrientColumn(
                        'Carbs',
                        '${_totalCarbs.toStringAsFixed(1)}g',
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
                          '${entries.fold<int>(0, (sum, entry) => sum + entry.calories)} cal',
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
                          builder: (context) => FoodSearchDialog(initialMealType: mealType),
                        );

                        if (result != null) {
                          await _dbHelper.insertMealEntry(result, _userId);
                          _loadMealEntries();
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
            '${entry.calories} cal',
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
                    return 'Please enter a food name';
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
                decoration: const InputDecoration(labelText: 'Proteins (g)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter proteins';
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
          child: const Text('Add'),
        ),
      ],
    );
  }
}
