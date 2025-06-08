import '../models/user.dart';
import '../utils/password_helper.dart';
import 'database/db_helper.dart';

class AuthService {
  final DatabaseHelper dbHelper;

  AuthService(this.dbHelper);

  Future<int> registerUser(User user) async {
    final db = await dbHelper.database;
    final hashedUser = User(
      id: user.id,
      name: user.name,
      email: user.email,
      password: PasswordHelper.hashPassword(user.password),
      createdAt: user.createdAt,
    );
    return await db.insert('users', hashedUser.toMap());
  }


  Future<User?> loginUser(String email, String password) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      final user = User.fromMap(maps.first);
      if (PasswordHelper.verifyPassword(password, user.password)) {
        return user;
      }
    }
    return null;
  }
  Future<bool> emailExists(String email) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }
}