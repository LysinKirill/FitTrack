import 'package:intl/intl.dart';

class WaterEntry {
  final int? id;
  final int amount; // in milliliters
  final DateTime dateTime;
  final int userId;

  WaterEntry({
    this.id,
    required this.amount,
    required this.dateTime,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime),
      'user_id': userId,
    };
  }

  factory WaterEntry.fromMap(Map<String, dynamic> map) {
    return WaterEntry(
      id: map['id'],
      amount: map['amount'],
      dateTime: DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['date_time']),
      userId: map['user_id'],
    );
  }
}
