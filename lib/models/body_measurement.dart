import 'package:intl/intl.dart';

class BodyMeasurement {
  final int? id;
  final int userId;
  final DateTime date;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? thighs;
  final double? arms;
  final double? shoulders;
  final String? note;

  BodyMeasurement({
    this.id,
    required this.userId,
    required this.date,
    this.chest,
    this.waist,
    this.hips,
    this.thighs,
    this.arms,
    this.shoulders,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(date),
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'thighs': thighs,
      'arms': arms,
      'shoulders': shoulders,
      'note': note,
    };
  }

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    return BodyMeasurement(
      id: map['id'],
      userId: map['user_id'],
      date: DateFormat('yyyy-MM-dd HH:mm:ss').parse(map['date']),
      chest: map['chest']?.toDouble(),
      waist: map['waist']?.toDouble(),
      hips: map['hips']?.toDouble(),
      thighs: map['thighs']?.toDouble(),
      arms: map['arms']?.toDouble(),
      shoulders: map['shoulders']?.toDouble(),
      note: map['note'],
    );
  }
}
