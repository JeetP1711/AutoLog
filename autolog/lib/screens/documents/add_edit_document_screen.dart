import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/document_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an expiry date')));
      return;
    }
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a vehicle')));
      return;
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

      await ref.read(documentProvider(_selectedVehicleId!).notifier).saveDocument(doc, vehicle.nickname);

      if (mounted) {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final vehicles = ref.watch(vehicleProvider).valueOrNull ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                widget.documentId != null ? 'Edit Document' : 'Add Document',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vehicles.length > 1) ...[
                        _SectionHeader(title: 'Which vehicle?', icon: Icons.directions_car_rounded),
                        DropdownButtonFormField<String>(
                          value: _selectedVehicleId,
                          items: vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.nickname))).toList(),
                          onChanged: (v) => setState(() => _selectedVehicleId = v),
                          decoration: _inputDecoration('Select Vehicle'),
                        ),
                        const SizedBox(height: 24),
                      ],
                      _SectionHeader(title: 'Document Category', icon: Icons.description_rounded),
                      DropdownButtonFormField<String>(
                        value: _docType,
                        items: _documentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _docType = v!),
                        decoration: _inputDecoration('Type of Document'),
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Validity Periods', icon: Icons.history_rounded),
                      _DateSelectionTile(
                        label: 'Expiry Date',
                        value: _expiryDate != null ? DateFormatter.format(_expiryDate!) : 'Select Date',
                        icon: Icons.event_busy_rounded,
                        onTap: () => _pickDate(true),
                        isRequired: _expiryDate == null,
                      ),
                      const SizedBox(height: 12),
                      _DateSelectionTile(
                        label: 'Issue Date',
                        value: _issueDate != null ? DateFormatter.format(_issueDate!) : 'Select Date (Optional)',
                        icon: Icons.event_available_rounded,
                        onTap: () => _pickDate(false),
                        onClear: _issueDate != null ? () => setState(() => _issueDate = null) : null,
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Details', icon: Icons.numbers_rounded),
                      _buildTextField(
                        controller: _docNumberCtrl,
                        label: 'Document Number',
                        hint: 'e.g. MH-12-2023-0012345',
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Document', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withAlpha(50))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withAlpha(50))),
      filled: true,
      fillColor: cs.surface,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? suffixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label).copyWith(
        hintText: hint,
        suffixText: suffixText,
        suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.primary),
          ),
        ],
      ),
    );
  }
}

class _DateSelectionTile extends StatelessWidget {
  const _DateSelectionTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
    this.isRequired = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isRequired ? cs.error.withAlpha(100) : cs.outline.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (isRequired ? cs.error : cs.primary).withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: isRequired ? cs.error : cs.primary, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isRequired ? cs.error : cs.onSurface)),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: onClear)
            else
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
