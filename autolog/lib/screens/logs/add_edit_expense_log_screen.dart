import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/expense_log.dart';
import '../../providers/expense_log_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Expense category constants
// ─────────────────────────────────────────────────────────────────────────────

/// Well-known expense category labels.
const _kExpenseCategories = [
  'Toll',
  'Parking',
  'Fine',
  'Accessories',
  'Insurance Payment',
  'Repairs',
  'Loan EMI',
  'Miscellaneous',
];

/// Add or edit an expense log entry.
///
/// When [logId] is null the screen is in "add" mode; otherwise "edit" mode.
class AddEditExpenseLogScreen extends ConsumerStatefulWidget {
  /// The ID of the expense log to edit, or null when adding a new entry.
  final String? logId;

  const AddEditExpenseLogScreen({super.key, this.logId});

  @override
  ConsumerState<AddEditExpenseLogScreen> createState() =>
      _AddEditExpenseLogScreenState();
}

class _AddEditExpenseLogScreenState
    extends ConsumerState<AddEditExpenseLogScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Form state ─────────────────────────────────────────────────────────────
  String? _selectedVehicleId;
  DateTime _date = DateTime.now();
  String? _selectedCategory;
  bool _isSaving = false;
  bool _isLoading = false;

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String get _currencySymbol => ref.read(currencySymbolProvider);

  @override
  void initState() {
    super.initState();
    if (widget.logId != null) {
      _loadExistingLog();
    }
  }

  Future<void> _loadExistingLog() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(expenseLogRepositoryProvider);
      final log = await repo.getById(widget.logId!);
      if (log != null && mounted) {
        // Determine if the stored category matches a known category
        final knownCategory = _kExpenseCategories.contains(log.category)
            ? log.category
            : null;
        setState(() {
          _selectedVehicleId = log.vehicleId;
          _date = log.date;
          _selectedCategory = knownCategory ?? log.category;
          _amountController.text = log.amount.toString();
          _notesController.text = log.notes ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicleId == null) {
      _showError('Please select a vehicle.');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Please select a category.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final isEdit = widget.logId != null;

      final log = ExpenseLog(
        id: isEdit ? widget.logId! : newId(),
        vehicleId: _selectedVehicleId!,
        date: _date,
        category: _selectedCategory!,
        amount: double.parse(_amountController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ref
          .read(expenseLogProvider(_selectedVehicleId!).notifier)
          .saveExpenseLog(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Expense updated successfully.'
                  : 'Expense added successfully.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _showError('Failed to save expense: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.logId != null;
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : vehiclesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (vehicles) => Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // ── Vehicle selector ─────────────────────────────────
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _selectedVehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle *',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                      ),
                      hint: const Text('Select vehicle'),
                      isExpanded: true,
                      items: vehicles
                          .map(
                            (v) => DropdownMenuItem<String>(
                              value: v.id,
                              child: Text(
                                '${v.nickname} (${v.numberPlate})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) =>
                          setState(() => _selectedVehicleId = id),
                      validator: (v) =>
                          v == null ? 'Vehicle is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Date picker ──────────────────────────────────────
                    _DatePickerField(
                      label: 'Date *',
                      value: _date,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Category chips ───────────────────────────────────
                    _SectionLabel('Category *'),
                    const SizedBox(height: AppSpacing.sm),
                    _CategorySelector(
                      selected: _selectedCategory,
                      onChanged: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                    if (_selectedCategory == null)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: AppSpacing.xs, left: AppSpacing.sm),
                        child: Text(
                          'Category is required',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Amount ───────────────────────────────────────────
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount *',
                        hintText: 'e.g. 500',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        prefixText: _currencySymbol,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: Validators.price,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Notes (optional) ─────────────────────────────────
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Any additional information…',
                        prefixIcon: Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Save button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEdit ? 'Update Expense' : 'Add Expense'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chip selector
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _kExpenseCategories.map((cat) {
        final isSelected = selected == cat;
        return ChoiceChip(
          label: Text(cat),
          selected: isSelected,
          onSelected: (_) => onChanged(cat),
          selectedColor: AppColors.primaryBlue,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : null,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date picker field
// ─────────────────────────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted =
        value != null ? DateFormat('dd MMM yyyy').format(value!) : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        ),
        child: Text(
          formatted ?? 'Tap to select',
          style: AppTextStyles.bodyMedium.copyWith(
            color: value != null
                ? AppColors.textPrimaryDark
                : AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.titleSmall.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
