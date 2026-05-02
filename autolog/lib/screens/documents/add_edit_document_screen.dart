import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/document_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

const _documentTypes = [
  'Insurance',
  'PUC',
  'RC',
  'Fitness Certificate',
  'Warranty',
  'Licence Copy',
  'Pollution Certificate',
  'Other',
];

class AddEditDocumentScreen extends ConsumerStatefulWidget {
  const AddEditDocumentScreen({super.key, this.documentId, this.vehicleId});
  final String? documentId;
  final String? vehicleId;

  @override
  ConsumerState<AddEditDocumentScreen> createState() =>
      _AddEditDocumentScreenState();
}

class _AddEditDocumentScreenState
    extends ConsumerState<AddEditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docNumberCtrl = TextEditingController();

  String _docType = 'Insurance';
  DateTime? _issueDate;
  DateTime? _expiryDate;
  bool _loading = false;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
  }

  @override
  void dispose() {
    _docNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isExpiry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isExpiry
          ? (_expiryDate ?? DateTime.now().add(const Duration(days: 365)))
          : (_issueDate ?? DateTime.now()),
      firstDate: isExpiry ? DateTime.now() : DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _issueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
      );
      return;
    }
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
      final vehicle =
          vehicles.firstWhere((v) => v.id == _selectedVehicleId!);

      final doc = Document(
        id: widget.documentId ?? newId(),
        vehicleId: _selectedVehicleId!,
        documentType: _docType,
        expiryDate: _expiryDate!,
        issueDate: _issueDate,
        documentNumber: _docNumberCtrl.text.trim().isEmpty
            ? null
            : _docNumberCtrl.text.trim(),
      );

      await ref
          .read(documentProvider(_selectedVehicleId!).notifier)
          .saveDocument(doc, vehicle.nickname);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
            widget.documentId != null ? 'Edit Document' : 'Add Document'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Save',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.primaryBlue)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (vehicles.length > 1)
              DropdownButtonFormField<String>(
                value: _selectedVehicleId,
                decoration: const InputDecoration(labelText: 'Vehicle'),
                items: vehicles
                    .map((v) => DropdownMenuItem(
                        value: v.id, child: Text(v.nickname)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedVehicleId = v),
                dropdownColor: AppColors.darkSurface,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimaryDark),
              ),
            const SizedBox(height: AppSpacing.md),

            // Document type
            DropdownButtonFormField<String>(
              value: _docType,
              decoration: const InputDecoration(labelText: 'Document Type'),
              items: _documentTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _docType = v!),
              dropdownColor: AppColors.darkSurface,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
            ),
            const SizedBox(height: AppSpacing.md),

            // Expiry date (required)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy_rounded,
                  color: AppColors.warning),
              title: Text(
                _expiryDate != null
                    ? 'Expiry: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                    : 'Set Expiry Date *',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _expiryDate != null
                      ? AppColors.textPrimaryDark
                      : AppColors.warning,
                ),
              ),
              onTap: () => _pickDate(true),
            ),

            // Issue date (optional)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_rounded,
                  color: AppColors.primaryBlue),
              title: Text(
                _issueDate != null
                    ? 'Issue Date: ${_issueDate!.day}/${_issueDate!.month}/${_issueDate!.year}'
                    : 'Set Issue Date (optional)',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimaryDark),
              ),
              trailing: _issueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textSecondaryDark),
                      onPressed: () => setState(() => _issueDate = null),
                    )
                  : null,
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: AppSpacing.md),

            // Document number (optional)
            TextFormField(
              controller: _docNumberCtrl,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                labelText: 'Document Number (optional)',
                hintText: 'e.g. POL123456789',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
