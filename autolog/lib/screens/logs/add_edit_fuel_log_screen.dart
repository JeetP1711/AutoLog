import 'package:flutter/material.dart';

/// Placeholder add/edit fuel log screen.
///
/// When [logId] is null the screen is in "add" mode; otherwise "edit" mode.
class AddEditFuelLogScreen extends StatelessWidget {
  /// The ID of the fuel log to edit, or null when adding a new entry.
  final String? logId;

  const AddEditFuelLogScreen({super.key, this.logId});

  @override
  Widget build(BuildContext context) {
    final isEdit = logId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Fuel Log' : 'Add Fuel Log')),
      body: Center(
        child: Text(
          isEdit ? 'AddEditFuelLogScreen (edit: $logId)' : 'AddEditFuelLogScreen (add)',
        ),
      ),
    );
  }
}
