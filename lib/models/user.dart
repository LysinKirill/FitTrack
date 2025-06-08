class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final DateTime createdAt;
  final DateTime? birthDate;
  final double? height;
  final double? weight;
  final String gender;
  final int dailyCalorieGoal;
  final int dailyWaterGoal;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
    this.birthDate,
    this.height,
    this.weight,
    this.gender = 'other',
    this.dailyCalorieGoal = 2000,
    this.dailyWaterGoal = 2000,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'birth_date': birthDate?.toIso8601String(),
      'height': height,
      'weight': weight,
      'gender': gender,
      'daily_calorie_goal': dailyCalorieGoal,
      'daily_water_goal': dailyWaterGoal,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      createdAt: DateTime.parse(map['created_at']),
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date']) : null,
      height: map['height']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
      gender: map['gender'] ?? 'other',
      dailyCalorieGoal: map['daily_calorie_goal'] ?? 2000,
      dailyWaterGoal: map['daily_water_goal'] ?? 2000,
    );
  }
}