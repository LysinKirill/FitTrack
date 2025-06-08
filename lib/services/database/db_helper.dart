import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fit_track/models/meal_entry.dart';
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
      version: 2, // Increase version to trigger onCreate/onUpgrade
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
        created_at TEXT NOT NULL
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
    }

    final result = await db.query(
      'meal_entries',
      where: 'user_id = ? AND date_time BETWEEN ? AND ?',
      whereArgs: [userId, startDateStr, endDateStr],
      orderBy: 'date_time ASC',
    );

    print('Query result count: ${result.length}');

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
}
