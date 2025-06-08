import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fit_track/models/meal_entry.dart';
import 'package:fit_track/models/activity_entry.dart';
import 'package:fit_track/models/weight_entry.dart';
import 'package:fit_track/models/water_entry.dart';
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

    print('Initializing database at path: $path');

    return await openDatabase(
      path,
      version: 6, // Increase version to trigger onCreate/onUpgrade
      onCreate: (db, version) {
        print('Creating new database tables');
        return _createDB(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('Upgrading database from v$oldVersion to v$newVersion');
        if (oldVersion < 2) {
          // Add meal_entries table if upgrading from version 1
          print('Adding meal_entries table');
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
          // Add activity_entries table if upgrading from version 2
          print('Adding activity_entries table');
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
          // Add weight_entries table if upgrading from version 3
          print('Adding weight_entries table');
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
          // Add water_entries table if upgrading from version 4
          print('Adding water_entries table');
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
          // Add fitness_goal and activity_level columns to users table
          print(
            'Adding fitness_goal and activity_level columns to users table',
          );
          await db.execute(
            'ALTER TABLE users ADD COLUMN fitness_goal TEXT DEFAULT "maintenance"',
          );
          await db.execute(
            'ALTER TABLE users ADD COLUMN activity_level TEXT DEFAULT "moderate"',
          );
        }
      },
      onOpen: (db) async {
        print('Database opened');
        // Check if tables exist
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        print('Tables in database: ${tables.map((t) => t['name']).join(', ')}');
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
  }

  // Meal Entries CRUD operations
  Future<int> insertMealEntry(MealEntry mealEntry, int userId) async {
    final db = await instance.database;
    final map = mealEntry.toMap();
    map['user_id'] = userId;

    print('Inserting meal entry: $map');

    try {
      final id = await db.insert('meal_entries', map);
      print('Successfully inserted meal entry with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting meal entry: $e');
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

    print(
      'Querying meals for userId: $userId, date range: $startDateStr to $endDateStr',
    );

    // First check if the table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='meal_entries'",
    );
    print('Tables found: ${tables.length}');

    if (tables.isEmpty) {
      print('meal_entries table does not exist!');
      return [];
    }

    // Check all entries in the table without filtering
    final allEntries = await db.query('meal_entries');
    print('Total entries in meal_entries table: ${allEntries.length}');

    if (allEntries.isNotEmpty) {
      print('Sample entry: ${allEntries.first}');

      // Debug: Print all entries
      for (var entry in allEntries) {
        print(
          'Entry: ${entry['name']}, calories: ${entry['calories']}, date: ${entry['date_time']}, user_id: ${entry['user_id']}',
        );
      }
    }

    // Try a simpler query first to debug
    final userEntries = await db.query(
      'meal_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    print('Entries for user $userId: ${userEntries.length}');

    // Now try the date-filtered query
    final result = await db.query(
      'meal_entries',
      where: 'user_id = ? AND date_time BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'date_time ASC',
    );

    print('Query result count for date range: ${result.length}');

    // Debug: Print all filtered entries
    for (var entry in result) {
      print(
        'Filtered entry: ${entry['name']}, calories: ${entry['calories']}, date: ${entry['date_time']}',
      );
    }

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

  // For testing: clear all meal entries
  Future<int> clearMealEntries() async {
    final db = await instance.database;
    print('Clearing all meal entries');
    return await db.delete('meal_entries');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // Activity Entries CRUD operations
  Future<int> insertActivityEntry(
    ActivityEntry activityEntry,
    int userId,
  ) async {
    final db = await instance.database;
    final map = activityEntry.toMap();
    map['user_id'] = userId;

    print('Inserting activity entry: $map');

    try {
      final id = await db.insert('activity_entries', map);
      print('Successfully inserted activity entry with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting activity entry: $e');
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

    print(
      'Querying activities for userId: $userId, date range: $startDateStr to $endDateStr',
    );

    // First check if the table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='activity_entries'",
    );
    print('Tables found: ${tables.length}');

    if (tables.isEmpty) {
      print('activity_entries table does not exist!');
      return [];
    }

    final result = await db.query(
      'activity_entries',
      where: 'user_id = ? AND date_time BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'date_time ASC',
    );

    print('Query result count: ${result.length}');

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

  // For testing: clear all activity entries
  Future<int> clearActivityEntries() async {
    final db = await instance.database;
    print('Clearing all activity entries');
    return await db.delete('activity_entries');
  }

  // Weight Entries CRUD operations
  Future<int> insertWeightEntry(WeightEntry weightEntry) async {
    final db = await instance.database;
    final map = weightEntry.toMap();

    print('Inserting weight entry: $map');

    try {
      final id = await db.insert('weight_entries', map);
      print('Successfully inserted weight entry with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting weight entry: $e');
      return -1;
    }
  }

  Future<List<WeightEntry>> getWeightEntriesByUserId(int userId) async {
    final db = await instance.database;

    // First check if the table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='weight_entries'",
    );

    if (tables.isEmpty) {
      print('weight_entries table does not exist!');
      return [];
    }

    final result = await db.query(
      'weight_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );

    print('Query result count: ${result.length}');

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

    print(
      'Querying weight entries for userId: $userId, date range: $startDateStr to $endDateStr',
    );

    // First check if the table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='weight_entries'",
    );

    if (tables.isEmpty) {
      print('weight_entries table does not exist!');
      return [];
    }

    final result = await db.query(
      'weight_entries',
      where: 'user_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'date ASC',
    );

    print('Query result count: ${result.length}');

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

  // For testing: clear all weight entries
  Future<int> clearWeightEntries() async {
    final db = await instance.database;
    print('Clearing all weight entries');
    return await db.delete('weight_entries');
  }

  // Water Entries CRUD operations
  Future<int> insertWaterEntry(WaterEntry waterEntry) async {
    final db = await instance.database;
    final map = waterEntry.toMap();

    print('Inserting water entry: $map');

    try {
      final id = await db.insert('water_entries', map);
      print('Successfully inserted water entry with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting water entry: $e');
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

    print(
      'Querying water entries for userId: $userId, date range: $startDateStr to $endDateStr',
    );

    // First check if the table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='water_entries'",
    );

    if (tables.isEmpty) {
      print('water_entries table does not exist!');
      return [];
    }

    final result = await db.query(
      'water_entries',
      where: 'user_id = ? AND date_time BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'date_time ASC',
    );

    print('Query result count: ${result.length}');

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

  // For testing: clear all water entries
  Future<int> clearWaterEntries() async {
    final db = await instance.database;
    print('Clearing all water entries');
    return await db.delete('water_entries');
  }

  // Get total calories for a date
  Future<int> getTotalCaloriesForDate(int userId, DateTime date) async {
    final entries = await getMealEntriesByDate(userId, date);
    int total = 0;
    for (var entry in entries) {
      total += entry.calories;
      print('Adding ${entry.calories} calories from ${entry.name}');
    }
    print('Total calories for date ${date.toString()}: $total');
    return total;
  }
}
