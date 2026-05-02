import 'package:flutter/material.dart';

/// Placeholder add/edit service log screen.
///
/// When [logId] is null the screen is in "add" mode; otherwise "edit" mode.
class AddEditServiceLogScreen extends StatelessWidget {
  /// The ID of the service log to edit, or null when adding a new entry.
  final String? logId;

  const AddEditServiceLogScreen({super.key, this.logId});

  @override
  Widget build(BuildContext context) {
    final isEdit = logId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Service Log' : 'Add Service Log')),
      body: Center(
        child: Text(
          isEdit ? 'AddEditServiceLogScreen (edit: $logId)' : 'AddEditServiceLogScreen (add)',
        ),
      ),
    );
  }
}
