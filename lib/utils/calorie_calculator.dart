import 'package:fit_track/models/user.dart';

class CalorieCalculator {
  /// Calculates the daily calorie needs based on user parameters using the Harris-Benedict formula
  static int calculateDailyCalorieNeeds(User user) {
    if (user.height == null || user.weight == null || user.birthDate == null) {
      return 2000; // Default value if required parameters are missing
    }

    // Calculate age
    final now = DateTime.now();
    final age = now.year - user.birthDate!.year;

    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < user.birthDate!.month ||
        (now.month == user.birthDate!.month && now.day < user.birthDate!.day)) {
      age - 1;
    }

    // Calculate BMR (Basal Metabolic Rate) using Harris-Benedict formula
    double bmr;
    if (user.gender == 'male') {
      bmr =
          88.362 +
          (13.397 * user.weight!) +
          (4.799 * user.height!) -
          (5.677 * age);
    } else {
      bmr =
          447.593 +
          (9.247 * user.weight!) +
          (3.098 * user.height!) -
          (4.330 * age);
    }

    // Apply activity level multiplier
    double activityMultiplier;
    switch (user.activityLevel) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'active':
        activityMultiplier = 1.725;
        break;
      case 'very_active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55; // Default to moderate
    }

    double calories = bmr * activityMultiplier;

    // Adjust based on fitness goal
    switch (user.fitnessGoal) {
      case 'weight_loss':
        calories -= 500; // Deficit for weight loss
        break;
      case 'weight_gain':
        calories += 500; // Surplus for weight gain
        break;
      case 'maintenance':
      default:
        // No adjustment needed for maintenance
        break;
    }

    return calories.round();
  }

  /// Returns a map of activity levels with their descriptions
  static Map<String, String> getActivityLevels() {
    return {
      'sedentary': 'Малоподвижный образ жизни',
      'light': 'Легкие тренировки 1-3 дня в неделю',
      'moderate': 'Умеренные тренировки 3-5 дней в неделю',
      'active': 'Интенсивные тренировки 6-7 дней в неделю',
      'very_active': 'Очень интенсивные тренировки и физическая работа',
    };
  }

  /// Returns a map of fitness goals with their descriptions
  static Map<String, String> getFitnessGoals() {
    return {
      'weight_loss': 'Снижение веса',
      'maintenance': 'Поддержание веса',
      'weight_gain': 'Набор веса',
    };
  }
}
