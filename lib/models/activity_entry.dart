import 'package:intl/intl.dart';

class ActivityEntry {
  final int? id;
  final String name;
  final String activityType;
  final int duration;
  final int caloriesBurned;
  final DateTime dateTime;
  final String? notes;

  ActivityEntry({
    this.id,
    required this.name,
    required this.activityType,
    required this.duration,
    required this.caloriesBurned,
    required this.dateTime,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'activity_type': activityType,
      'duration': duration,
      'calories_burned': caloriesBurned,
      'date_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime),
      'notes': notes,
    };
  }

  factory ActivityEntry.fromMap(Map<String, dynamic> map) {
    return ActivityEntry(
      id: map['id'],
      name: map['name'],
      activityType: map['activity_type'],
      duration: map['duration'],
      caloriesBurned: map['calories_burned'],
      dateTime: DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['date_time']),
      notes: map['notes'],
    );
  }

  static List<String> activityTypes = [
    'Running',
    'Walking',
    'Cycling',
    'Swimming',
    'Gym Workout',
    'Yoga',
    'Pilates',
    'HIIT',
    'Other',
  ];
}
