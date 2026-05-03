import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/document_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_theme.dart';

const _documentTypes = [
  'Insurance', 'PUC', 'RC', 'Fitness Certificate',
  'Warranty', 'Licence Copy', 'Pollution Certificate', 'Other',
];

class AddEditDocumentScreen extends ConsumerStatefulWidget {
  const AddEditDocumentScreen({super.key, this.documentId, this.vehicleId});
  final String? documentId;
  final String? vehicleId;

  @override
  ConsumerState<AddEditDocumentScreen> createState() => _AddEditDocumentScreenState();
}

class _AddEditDocumentScreenState extends ConsumerState<AddEditDocumentScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedVehicleId == null) {
        final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
        if (vehicles.length == 1) setState(() => _selectedVehicleId = vehicles.first.id);
      }
    });
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
    if (picked != null) setState(() => isExpiry ? _expiryDate = picked : _issueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')));
      return;
    }
    if (_selectedVehicleId == null) {
      final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
      if (vehicles.length == 1) {
        _selectedVehicleId = vehicles.first.id;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a vehicle')));
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
      final vehicle = vehicles.firstWhere((v) => v.id == _selectedVehicleId!);

      final doc = Document(
        id: widget.documentId ?? newId(),
        vehicleId: _selectedVehicleId!,
        documentType: _docType,
        expiryDate: _expiryDate!,
        issueDate: _issueDate,
        documentNumber: _docNumberCtrl.text.trim().isEmpty ? null : _docNumberCtrl.text.trim(),
      );

      await ref.read(documentProvider(_selectedVehicleId!).notifier)
          .saveDocument(doc, vehicle.nickname);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document saved'), behavior: SnackBarBehavior.floating));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vehicles = ref.watch(vehicleProvider).valueOrNull ?? [];
    if (_selectedVehicleId == null && vehicles.length == 1) {
      _selectedVehicleId = vehicles.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentId != null ? 'Edit Document' : 'Add Document'),
        actions: [
          if (_loading)
            const Padding(padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(onPressed: _save,
              child: Text('Save', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          children: [
            if (vehicles.length > 1) ...[
              DropdownButtonFormField<String>(
                value: _selectedVehicleId,
                decoration: const InputDecoration(labelText: 'Vehicle'),
                items: vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.nickname))).toList(),
                onChanged: (v) => setState(() => _selectedVehicleId = v),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            DropdownButtonFormField<String>(
              value: _docType,
              decoration: const InputDecoration(labelText: 'Document Type'),
              items: _documentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _docType = v!),
            ),
            const SizedBox(height: AppSpacing.md),

            // Expiry date (required)
            _DateTile(
              icon: Icons.event_busy_rounded,
              label: _expiryDate != null
                  ? 'Expiry: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                  : 'Set Expiry Date *',
              isRequired: _expiryDate == null,
              onTap: () => _pickDate(true),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Issue date (optional)
            _DateTile(
              icon: Icons.event_available_rounded,
              label: _issueDate != null
                  ? 'Issue Date: ${_issueDate!.day}/${_issueDate!.month}/${_issueDate!.year}'
                  : 'Set Issue Date (optional)',
              onTap: () => _pickDate(false),
              trailing: _issueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _issueDate = null))
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _docNumberCtrl,
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

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.icon, required this.label, required this.onTap,
    this.isRequired = false, this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isRequired;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border.all(color: isRequired ? cs.error : cs.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isRequired ? cs.error : cs.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isRequired ? cs.error : null))),
            if (trailing != null) trailing!
            else Icon(Icons.edit_calendar_rounded, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
