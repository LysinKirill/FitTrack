import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      // Explicitly set bottomNavigationBar to null to ensure it doesn't appear
      bottomNavigationBar: null,
    );
  }
}
