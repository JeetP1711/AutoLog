import 'package:flutter/material.dart';

/// Placeholder add/edit vehicle screen.
///
/// When [vehicleId] is null the screen is in "add" mode; otherwise "edit" mode.
class AddEditVehicleScreen extends StatelessWidget {
  /// The ID of the vehicle to edit, or null when adding a new vehicle.
  final String? vehicleId;

  const AddEditVehicleScreen({super.key, this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final isEdit = vehicleId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Vehicle' : 'Add Vehicle')),
      body: Center(
        child: Text(
          isEdit ? 'AddEditVehicleScreen (edit: $vehicleId)' : 'AddEditVehicleScreen (add)',
        ),
      ),
    );
  }
}
