import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/expense_log_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

const _expenseCategories = [
  'Toll', 'Parking', 'Fine', 'Accessories',
  'Insurance Payment', 'Repairs', 'Loan EMI', 'Miscellaneous',
];

class AddEditExpenseLogScreen extends ConsumerStatefulWidget {
  const AddEditExpenseLogScreen({super.key, this.logId, this.vehicleId});
  final String? logId;
  final String? vehicleId;

  @override
  ConsumerState<AddEditExpenseLogScreen> createState() =>
      _AddEditExpenseLogScreenState();
}

class _AddEditExpenseLogScreenState extends ConsumerState<AddEditExpenseLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  String _category = 'Toll';
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
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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
      final log = ExpenseLog(
        id: widget.logId ?? newId(),
        vehicleId: _selectedVehicleId!,
        date: _date,
        category: _category,
        amount: double.parse(_amountCtrl.text.trim()),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await ref.read(expenseLogProvider(_selectedVehicleId!).notifier).saveExpenseLog(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved'), behavior: SnackBarBehavior.floating));
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
        title: Text(widget.logId != null ? 'Edit Expense' : 'Add Expense'),
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

            // Date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xs),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${_date.day}/${_date.month}/${_date.year}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const Spacer(),
                    Icon(Icons.edit_calendar_rounded, size: 16, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.price,
              decoration: const InputDecoration(labelText: 'Amount (₹)', hintText: 'e.g. 150'),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
