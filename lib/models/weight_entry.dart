import 'package:intl/intl.dart';

class WeightEntry {
  final int? id;
  final double weight;
  final DateTime date;
  final String? note;
  final int userId;

  WeightEntry({
    this.id,
    required this.weight,
    required this.date,
    this.note,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(date),
      'note': note,
      'user_id': userId,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'],
      weight: map['weight'],
      date: DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['date']),
      note: map['note'],
      userId: map['user_id'],
    );
  }
}
