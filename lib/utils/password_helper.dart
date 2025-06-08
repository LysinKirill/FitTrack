import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHelper {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String inputPassword, String hashedPassword) {
    final inputHash = hashPassword(inputPassword);
    return inputHash == hashedPassword;
  }
}