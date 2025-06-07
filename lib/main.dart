import 'package:flutter/material.dart';
import 'package:fit_track/screens/auth/login_screen.dart';
import 'package:fit_track/services/database/db_helper.dart';
import 'package:fit_track/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper.instance;
  final authService = AuthService(dbHelper);

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(authService: authService),
    );
  }
}