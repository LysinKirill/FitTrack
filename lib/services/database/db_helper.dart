import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fit_track/models/meal_entry.dart';
import 'package:fit_track/models/activity_entry.dart';
import 'package:fit_track/models/weight_entry.dart';
import 'package:fit_track/models/water_entry.dart';
import 'package:fit_track/models/body_measurement.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fit_track.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: (db, version) {
        return _createDB(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS meal_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              meal_type TEXT NOT NULL,
              calories INTEGER NOT NULL,
              proteins REAL NOT NULL,
              fats REAL NOT NULL,
              carbs REAL NOT NULL,
              date_time TEXT NOT NULL,
              user_id INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS activity_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              activity_type TEXT NOT NULL,
              duration INTEGER NOT NULL,
              calories_burned INTEGER NOT NULL,
              date_time TEXT NOT NULL,
              notes TEXT,
              user_id INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');
        }

        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS weight_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              weight REAL NOT NULL,
              date TEXT NOT NULL,
              note TEXT,
              user_id INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');
        }

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS water_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              amount INTEGER NOT NULL,
              date_time TEXT NOT NULL,
              user_id INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');
        }

        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE users ADD COLUMN fitness_goal TEXT DEFAULT "maintenance"',
          );
          await db.execute(
            'ALTER TABLE users ADD COLUMN activity_level TEXT DEFAULT "moderate"',
          );
        }

        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS body_measurements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              date TEXT NOT NULL,
              chest REAL,
              waist REAL,
              hips REAL,
              thighs REAL,
              arms REAL,
              shoulders REAL,
              note TEXT,
              FOREIGN KEY (user_id) REFERENCES users (id)
            )
          ''');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      created_at TEXT NOT NULL,
      birth_date TEXT,
      height REAL,
      weight REAL,
      gender TEXT default 'other',
      daily_calorie_goal INTEGER NOT NULL,
      daily_water_goal INTEGER NOT NULL,
      fitness_goal TEXT default 'maintenance',
      activity_level TEXT default 'moderate'
    )
    ''');

    await db.execute('''
      CREATE TABLE meal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        calories INTEGER NOT NULL,
        proteins REAL NOT NULL,
        fats REAL NOT NULL,
        carbs REAL NOT NULL,
        date_time TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        duration INTEGER NOT NULL,
        calories_burned INTEGER NOT NULL,
        date_time TEXT NOT NULL,
        notes TEXT,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE water_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        date_time TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE body_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        chest REAL,
        waist REAL,
        hips REAL,
        thighs REAL,
        arms REAL,
        shoulders REAL,
        note TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  Future<int> insertMealEntry(MealEntry mealEntry, int userId) async {
    final db = await instance.database;
    final map = mealEntry.toMap();
    map['user_id'] = userId;

    try {
      final id = await db.insert('meal_entries', map);
      return id;
    } catch (e) {
      return -1;
    }
  }

  Future<List<MealEntry>> getMealEntriesByDate(
    int userId,
    DateTime date,
  ) async {
    final db = await instance.database;
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final startDateStr = dateFormat.format(startDate);
    final endDateStr = dateFormat.format(endDate);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='meal_entries'",
    );

    if (tables.isEmpty) {
      return [];
    }

    final result = await db.query(
      'meal_entries',
      where: 'user_id = ? AND date_time BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'date_time ASC',
    );

    return result.map((map) => MealEntry.fromMap(map)).toList();
  }

  Future<int> updateMealEntry(MealEntry mealEntry) async {
    final db = await instance.database;
    return await db.update(
      'meal_entries',
      mealEntry.toMap(),
      where: 'id = ?',
      whereArgs: [mealEntry.id],
    );
  }

  Future<int> deleteMealEntry(int id) async {
    final db = await instance.database;
    return await db.delete('meal_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearMealEntries() async {
    final db = await instance.database;
    return await db.delete('meal_entries');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<int> insertActivityEntry(
    ActivityEntry activityEntry,
    int userId,
  ) async {
    final db = await instance.database;
    final map = activityEntry.toMap();
    map['user_id'] = userId;

    try {
      final id = await db.insert('activity_entries', map);
      return id;
    } catch (e) {
      return -1;
    }
  }

  Future<List<ActivityEntry>> getActivityEntriesByDate(
    int userId,
    DateTime date,
  ) async {
    final db = await instance.database;
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final startDateStr = dateFormat.format(startDate);
    final endDateStr = dateFormat.format(endDate);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='activity_entries'",
    );

    if (tables.isEmpty) {
      return [];
    }

    final result = await db.query(
      'activity_entries',
      where: 'user_id = ? AND date_time BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'date_time ASC',
    );

    return result.map((map) => ActivityEntry.fromMap(map)).toList();
  }

  Future<int> updateActivityEntry(ActivityEntry activityEntry) async {
    final db = await instance.database;
    return await db.update(
      'activity_entries',
      activityEntry.toMap(),
      where: 'id = ?',
      whereArgs: [activityEntry.id],
    );
  }

  Future<int> deleteActivityEntry(int id) async {
    final db = await instance.database;
    return await db.delete(
      'activity_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearActivityEntries() async {
    final db = await instance.database;
    return await db.delete('activity_entries');
  }

  Future<int> insertWeightEntry(WeightEntry weightEntry) async {
    final db = await instance.database;
    final map = weightEntry.toMap();

    try {
      final id = await db.insert('weight_entries', map);
      return id;
    } catch (e) {
      return -1;
    }
  }

  Future<List<WeightEntry>> getWeightEntriesByUserId(int userId) async {
    final db = await instance.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='weight_entries'",
    );

    if (tables.isEmpty) {
      return [];
    }

    final result = await db.query(
      'weight_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );

    return result.map((map) => WeightEntry.fromMap(map)).toList();
  }

  Future<List<WeightEntry>> getWeightEntriesForDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await instance.database;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final startDateStr = dateFormat.format(startDate);
    final endDateStr = dateFormat.format(endDate);
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='weight_entries'",
    );

    if (tables.isEmpty) {
      return [];
    }

    final result = await db.query(
      'weight_entries',
      where: 'user_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'date ASC',
    );

    return result.map((map) => WeightEntry.fromMap(map)).toList();
  }

  Future<int> updateWeightEntry(WeightEntry weightEntry) async {
    final db = await instance.database;
    return await db.update(
      'weight_entries',
      weightEntry.toMap(),
      where: 'id = ?',
      whereArgs: [weightEntry.id],
    );
  }

  Future<int> deleteWeightEntry(int id) async {
    final db = await instance.database;
    return await db.delete('weight_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearWeightEntries() async {
    final db = await instance.database;
    return await db.delete('weight_entries');
  }

  Future<int> insertWaterEntry(WaterEntry waterEntry) async {
    final db = await instance.database;
    final map = waterEntry.toMap();

    try {
      final id = await db.insert('water_entries', map);
      return id;
    } catch (e) {
      return -1;
    }
  }

  Future<List<WaterEntry>> getWaterEntriesByDate(
    int userId,
    DateTime date,
  ) async {
    final db = await instance.database;
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final startDateStr = dateFormat.format(startDate);
    final endDateStr = dateFormat.format(endDate);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='water_entries'",
    );

    if (tables.isEmpty) {
      return [];
    }

    final result = await db.query(
      'water_entries',
      where: 'user_id = ? AND date_time BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'date_time ASC',
    );

    return result.map((map) => WaterEntry.fromMap(map)).toList();
  }

  Future<int> getTotalWaterForDate(int userId, DateTime date) async {
    final entries = await getWaterEntriesByDate(userId, date);
    int total = 0;
    for (var entry in entries) {
      total += entry.amount;
    }
    return total;
  }

  Future<int> updateWaterEntry(WaterEntry waterEntry) async {
    final db = await instance.database;
    return await db.update(
      'water_entries',
      waterEntry.toMap(),
      where: 'id = ?',
      whereArgs: [waterEntry.id],
    );
  }

  Future<int> deleteWaterEntry(int id) async {
    final db = await instance.database;
    return await db.delete('water_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearWaterEntries() async {
    final db = await instance.database;
    return await db.delete('water_entries');
  }

  Future<int> getTotalCaloriesForDate(int userId, DateTime date) async {
    final entries = await getMealEntriesByDate(userId, date);
    int total = 0;
    for (var entry in entries) {
      total += entry.calories;
    }
    return total;
  }

  Future<int> insertBodyMeasurement(BodyMeasurement measurement) async {
    final db = await instance.database;
    final map = measurement.toMap();

    try {
      final id = await db.insert('body_measurements', map);
      return id;
    } catch (e) {
      return -1;
    }
  }

  Future<List<BodyMeasurement>> getBodyMeasurementsByUserId(int userId) async {
    final db = await instance.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='body_measurements'",
    );

    if (tables.isEmpty) {
      return [];
    }

    final result = await db.query(
      'body_measurements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );

    return result.map((map) => BodyMeasurement.fromMap(map)).toList();
  }

  Future<List<BodyMeasurement>> getBodyMeasurementsForDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await instance.database;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final startDateStr = dateFormat.format(startDate);
    final endDateStr = dateFormat.format(endDate);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='body_measurements'",
    );

    if (tables.isEmpty) {
      return [];
    }

    final result = await db.query(
      'body_measurements',
      where: 'user_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'date ASC',
    );

    return result.map((map) => BodyMeasurement.fromMap(map)).toList();
  }

  Future<int> updateBodyMeasurement(BodyMeasurement measurement) async {
    final db = await instance.database;
    return await db.update(
      'body_measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<int> deleteBodyMeasurement(int id) async {
    final db = await instance.database;
    return await db.delete(
      'body_measurements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearBodyMeasurements() async {
    final db = await instance.database;
    return await db.delete('body_measurements');
  }
}
