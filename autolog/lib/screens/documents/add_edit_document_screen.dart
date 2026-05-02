import 'package:flutter/material.dart';

/// Placeholder add/edit document screen.
///
/// When [documentId] is null the screen is in "add" mode; otherwise "edit" mode.
class AddEditDocumentScreen extends StatelessWidget {
  /// The ID of the document to edit, or null when adding a new document.
  final String? documentId;

  const AddEditDocumentScreen({super.key, this.documentId});

  @override
  Widget build(BuildContext context) {
    final isEdit = documentId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Document' : 'Add Document')),
      body: Center(
        child: Text(
          isEdit ? 'AddEditDocumentScreen (edit: $documentId)' : 'AddEditDocumentScreen (add)',
        ),
      ),
    );
  }
}
