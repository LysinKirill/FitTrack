import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ActivityService {
  static final String? _apiId = dotenv.env['NUTRITIONIX_APP_ID'];
  static final String? _apiKey = dotenv.env['NUTRITIONIX_API_KEY'];
  static const String _apiUrl = 'https://trackapi.nutritionix.com/v2/natural/exercise';

  static Future<int?> calculateCalories({
    required String activityType,
    required int duration,
    required double weight,
  }) async {
    final Map<String, String> activityTypeMapping = {
      'Бег': 'running',
      'Ходьба': 'walking',
      'Велосипед': 'cycling',
      'Плавание': 'swimming',
      'Тренировка в зале': 'weight training',
      'Йога': 'yoga',
      'Пилатес': 'pilates',
      'ВИИТ': 'high intensity interval training',
      'Другое': 'general exercise',
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _apiId!,
          'x-app-key': _apiKey!,
        },
        body: jsonEncode({
          'query': '$duration minutes of ${activityTypeMapping[activityType]}',
          'weight_kg': weight,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exercises'] != null && data['exercises'].isNotEmpty) {
          return data['exercises'][0]['nf_calories'].round();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}