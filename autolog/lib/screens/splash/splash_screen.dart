import 'package:flutter/material.dart';

/// Placeholder splash screen shown while the app initialises.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('SplashScreen'),
      ),
    );
  }
}
