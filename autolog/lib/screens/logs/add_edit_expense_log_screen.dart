import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/expense_log_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

const _expenseCategories = [
  'Toll',
  'Parking',
  'Fine',
  'Accessories',
  'Insurance Payment',
  'Repairs',
  'Loan EMI',
  'Miscellaneous',
];

class AddEditExpenseLogScreen extends ConsumerStatefulWidget {
  const AddEditExpenseLogScreen({super.key, this.logId, this.vehicleId});
  final String? logId;
  final String? vehicleId;

  @override
  ConsumerState<AddEditExpenseLogScreen> createState() =>
      _AddEditExpenseLogScreenState();
}

class _AddEditExpenseLogScreenState
    extends ConsumerState<AddEditExpenseLogScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
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

      await ref
          .read(expenseLogProvider(_selectedVehicleId!).notifier)
          .saveExpenseLog(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense saved'),
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
        title: Text(widget.logId != null ? 'Edit Expense' : 'Add Expense'),
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

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded,
                  color: AppColors.primaryBlue),
              title: Text(
                'Date: ${_date.day}/${_date.month}/${_date.year}',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimaryDark),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.md),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _expenseCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
              dropdownColor: AppColors.darkSurface,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
            ),
            const SizedBox(height: AppSpacing.md),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              validator: Validators.price,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                hintText: 'e.g. 150',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Notes (optional)
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
