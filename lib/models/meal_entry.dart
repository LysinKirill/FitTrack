import 'package:intl/intl.dart';

class MealEntry {
  final int? id;
  final String name;
  final String mealType;
  final int calories;
  final double proteins;
  final double fats;
  final double carbs;
  final DateTime dateTime;

  MealEntry({
    this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'meal_type': mealType,
      'calories': calories,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
      'date_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime),
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'],
      name: map['name'],
      mealType: map['meal_type'],
      calories: map['calories'],
      proteins: map['proteins'],
      fats: map['fats'],
      carbs: map['carbs'],
      dateTime: DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['date_time']),
    );
  }

  static List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
}
