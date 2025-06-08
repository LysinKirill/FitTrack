import 'package:fit_track/models/user.dart';
import 'db_helper.dart';

class UserRepository {
  final DatabaseHelper dbHelper;

  UserRepository(this.dbHelper);

  Future<int> updateUser(User user) async {
    final db = await dbHelper.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<User> getUser(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    throw Exception('User not found');
  }

  Future<void> updateUserGoals({
    required int userId,
    double? weight,
    int? calorieGoal,
    int? waterGoal,
  }) async {
    final db = await dbHelper.database;
    final updates = <String, dynamic>{};

    if (weight != null) updates['weight'] = weight;
    if (calorieGoal != null) updates['daily_calorie_goal'] = calorieGoal;
    if (waterGoal != null) updates['daily_water_goal'] = waterGoal;

    if (updates.isNotEmpty) {
      await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );
    }
  }
}