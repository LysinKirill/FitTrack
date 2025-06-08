import 'package:flutter/material.dart';
import 'package:fit_track/models/meal_entry.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/api/fatsecret_api.dart';

class FoodSearchDialog extends StatefulWidget {
  final String initialMealType;
  final DateTime selectedDate;

  const FoodSearchDialog({
    super.key,
    required this.initialMealType,
    required this.selectedDate,
  });

  @override
  State<FoodSearchDialog> createState() => _FoodSearchDialogState();
}

class _FoodSearchDialogState extends State<FoodSearchDialog> {
  final _searchController = TextEditingController();
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  String _mealType = 'Breakfast';

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final _api = FatSecretAPI(
    dotenv.env['FATSECRET_KEY']!,
    dotenv.env['FATSECRET_SECRET']!,
  );

  void _searchFoods() async {
    setState(() => _isSearching = true);
    try {
      final results = await _api.searchFoods(_searchController.text);
      final parsed = parseSearchResults(results);

      setState(() => _searchResults = parsed);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  List<FoodItem> parseSearchResults(Map<String, dynamic> data) {
    var foods = data['foods']['food'];
    var results =
        foods.map<FoodItem>((food) {
          var nutritionalInfo = parseNutritionalInfo(food['food_description']);
          return FoodItem(
            id: food['food_id'],
            name: food['food_name'],
            calories: (nutritionalInfo['Calories'] ?? 0).toInt(),
            proteins: nutritionalInfo['Protein'] ?? 0,
            fats: nutritionalInfo['Fat'] ?? 0,
            carbs: nutritionalInfo['Carbs'] ?? 0,
          );
        }).toList();

    return results;
  }

  Map<String, double> parseNutritionalInfo(String input) {
    RegExp exp = RegExp(
      r'Calories: (\d+\.?\d*)kcal \| Fat: (\d+\.?\d*)g \| Carbs: (\d+\.?\d*)g \| Protein: (\d+\.?\d*)g',
    );

    Match? match = exp.firstMatch(input);
    if (match != null) {
      return {
        'Calories': double.parse(match.group(1)!),
        'Fat': double.parse(match.group(2)!),
        'Carbs': double.parse(match.group(3)!),
        'Protein': double.parse(match.group(4)!),
      };
    }

    return {};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Food'),
      content: SingleChildScrollView(
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
              onChanged: (value) => setState(() => _mealType = value!),
            ),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search food',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchFoods,
                ),
              ),
              onSubmitted: (_) => _searchFoods(),
            ),
            const SizedBox(height: 16),
            _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Search for foods'
                            : 'No results found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : ConstrainedBox(
                  // Add ConstrainedBox
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final food in _searchResults)
                        ListTile(
                          title: Text(food.name),
                          subtitle: Text(
                            '${food.calories} cal | P:${food.proteins}g F:${food.fats}g C:${food.carbs}g',
                          ),
                          onTap: () {
                            // Create a DateTime that combines the selected date with the current time
                            final now = DateTime.now();
                            final dateTime = DateTime(
                              widget.selectedDate.year,
                              widget.selectedDate.month,
                              widget.selectedDate.day,
                              now.hour,
                              now.minute,
                              now.second,
                            );

                            Navigator.pop(
                              context,
                              MealEntry(
                                name: food.name,
                                mealType: _mealType,
                                calories: food.calories,
                                proteins: food.proteins,
                                fats: food.fats,
                                carbs: food.carbs,
                                dateTime: dateTime,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
