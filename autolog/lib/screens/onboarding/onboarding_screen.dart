import 'package:flutter/material.dart';

/// Placeholder onboarding screen shown on first launch.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('OnboardingScreen'),
      ),
    );
  }
}
