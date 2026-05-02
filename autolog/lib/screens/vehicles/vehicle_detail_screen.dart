import 'package:flutter/material.dart';

/// Placeholder vehicle detail screen.
class VehicleDetailScreen extends StatelessWidget {
  /// The ID of the vehicle to display.
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Detail')),
      body: Center(
        child: Text('VehicleDetailScreen: $vehicleId'),
      ),
    );
  }
}
