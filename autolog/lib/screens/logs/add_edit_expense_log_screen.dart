import 'package:flutter/material.dart';

/// Placeholder add/edit expense log screen.
///
/// When [logId] is null the screen is in "add" mode; otherwise "edit" mode.
class AddEditExpenseLogScreen extends StatelessWidget {
  /// The ID of the expense log to edit, or null when adding a new entry.
  final String? logId;

  const AddEditExpenseLogScreen({super.key, this.logId});

  @override
  Widget build(BuildContext context) {
    final isEdit = logId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Expense' : 'Add Expense')),
      body: Center(
        child: Text(
          isEdit ? 'AddEditExpenseLogScreen (edit: $logId)' : 'AddEditExpenseLogScreen (add)',
        ),
      ),
    );
  }
}
