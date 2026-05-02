import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/service_log.dart';
import '../../providers/service_log_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Service type constants
// ─────────────────────────────────────────────────────────────────────────────

/// Well-known service type labels.
const _kServiceTypes = [
  'Oil Change',
  'Brake Service',
  'General Service',
  'Washing',
  'Detailing',
  'Tyre Rotation',
  'Battery Replacement',
  'Engine Repair',
  'AC Repair',
  'Custom',
];

/// Add or edit a service log entry.
///
/// When [logId] is null the screen is in "add" mode; otherwise "edit" mode.
class AddEditServiceLogScreen extends ConsumerStatefulWidget {
  /// The ID of the service log to edit, or null when adding a new entry.
  final String? logId;

  const AddEditServiceLogScreen({super.key, this.logId});

  @override
  ConsumerState<AddEditServiceLogScreen> createState() =>
      _AddEditServiceLogScreenState();
}

class _AddEditServiceLogScreenState
    extends ConsumerState<AddEditServiceLogScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Form state ─────────────────────────────────────────────────────────────
  String? _selectedVehicleId;
  DateTime _date = DateTime.now();
  String? _selectedServiceType;
  DateTime? _nextDueDate;
  bool _isSaving = false;
  bool _isLoading = false;

  final _costController = TextEditingController();
  final _odometerController = TextEditingController();
  final _garageNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _nextDueOdometerController = TextEditingController();
  final _customServiceTypeController = TextEditingController();

  bool get _isCustomServiceType => _selectedServiceType == 'Custom';

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
      final repo = ref.read(serviceLogRepositoryProvider);
      final log = await repo.getById(widget.logId!);
      if (log != null && mounted) {
        // Determine if the stored service type matches a known type
        final knownType = _kServiceTypes.contains(log.serviceType)
            ? log.serviceType
            : 'Custom';
        setState(() {
          _selectedVehicleId = log.vehicleId;
          _date = log.date;
          _selectedServiceType = knownType;
          if (knownType == 'Custom') {
            _customServiceTypeController.text = log.serviceType;
          }
          _costController.text = log.cost.toString();
          _odometerController.text = log.odometerKm?.toString() ?? '';
          _garageNameController.text = log.garageName ?? '';
          _notesController.text = log.notes ?? '';
          _nextDueDate = log.nextDueDate;
          _nextDueOdometerController.text =
              log.nextDueOdometerKm?.toString() ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _costController.dispose();
    _odometerController.dispose();
    _garageNameController.dispose();
    _notesController.dispose();
    _nextDueOdometerController.dispose();
    _customServiceTypeController.dispose();
    super.dispose();
  }

  // ── Date pickers ───────────────────────────────────────────────────────────

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

  Future<void> _pickNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _nextDueDate = picked);
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicleId == null) {
      _showError('Please select a vehicle.');
      return;
    }
    if (_selectedServiceType == null) {
      _showError('Please select a service type.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final isEdit = widget.logId != null;

      // Resolve the actual service type string
      final serviceTypeStr = _isCustomServiceType
          ? _customServiceTypeController.text.trim()
          : _selectedServiceType!;

      // Resolve vehicle nickname for reminder
      final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
      final vehicle = vehicles.firstWhere(
        (v) => v.id == _selectedVehicleId,
        orElse: () => throw StateError('Vehicle not found'),
      );

      final odometerText = _odometerController.text.trim();
      final nextDueOdometerText = _nextDueOdometerController.text.trim();

      final log = ServiceLog(
        id: isEdit ? widget.logId! : newId(),
        vehicleId: _selectedVehicleId!,
        date: _date,
        serviceType: serviceTypeStr,
        cost: double.parse(_costController.text.trim()),
        odometerKm: odometerText.isEmpty ? null : double.parse(odometerText),
        garageName: _garageNameController.text.trim().isEmpty
            ? null
            : _garageNameController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        nextDueDate: _nextDueDate,
        nextDueOdometerKm: nextDueOdometerText.isEmpty
            ? null
            : double.parse(nextDueOdometerText),
      );

      await ref
          .read(serviceLogProvider(_selectedVehicleId!).notifier)
          .saveServiceLog(log, vehicle.nickname);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Service log updated successfully.'
                  : 'Service log added successfully.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _showError('Failed to save service log: $e');
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
        title: Text(isEdit ? 'Edit Service Log' : 'Add Service Log'),
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

                    // ── Service type chips ───────────────────────────────
                    _SectionLabel('Service Type *'),
                    const SizedBox(height: AppSpacing.sm),
                    _ServiceTypeSelector(
                      selected: _selectedServiceType,
                      onChanged: (type) =>
                          setState(() => _selectedServiceType = type),
                    ),
                    if (_selectedServiceType == null)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: AppSpacing.xs, left: AppSpacing.sm),
                        child: Text(
                          'Service type is required',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Custom service type field ─────────────────────────
                    if (_isCustomServiceType) ...[
                      TextFormField(
                        controller: _customServiceTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Service Type *',
                          hintText: 'e.g. Wheel Alignment',
                          prefixIcon: Icon(Icons.build_outlined),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => _isCustomServiceType
                            ? Validators.requiredText(v,
                                label: 'Custom service type')
                            : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // ── Cost ─────────────────────────────────────────────
                    TextFormField(
                      controller: _costController,
                      decoration: InputDecoration(
                        labelText: 'Cost *',
                        hintText: 'e.g. 1500',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        prefixText: _currencySymbol,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: Validators.cost,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Odometer (optional) ──────────────────────────────
                    TextFormField(
                      controller: _odometerController,
                      decoration: const InputDecoration(
                        labelText: 'Odometer (optional)',
                        hintText: 'e.g. 15000',
                        prefixIcon: Icon(Icons.speed_outlined),
                        suffixText: 'km',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null) return 'Enter a valid number';
                        if (parsed < 0) return 'Odometer cannot be negative';
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Garage name (optional) ───────────────────────────
                    TextFormField(
                      controller: _garageNameController,
                      decoration: const InputDecoration(
                        labelText: 'Garage / Workshop (optional)',
                        hintText: 'e.g. City Auto Service',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
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
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Next due section ─────────────────────────────────
                    _SectionLabel('Next Service Due (optional)'),
                    const SizedBox(height: AppSpacing.sm),

                    _DatePickerField(
                      label: 'Next Due Date (optional)',
                      value: _nextDueDate,
                      onTap: _pickNextDueDate,
                      onClear: () => setState(() => _nextDueDate = null),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _nextDueOdometerController,
                      decoration: const InputDecoration(
                        labelText: 'Next Due Odometer (optional)',
                        hintText: 'e.g. 20000',
                        prefixIcon: Icon(Icons.speed_outlined),
                        suffixText: 'km',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null) return 'Enter a valid number';
                        if (parsed < 0) return 'Odometer cannot be negative';
                        return null;
                      },
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
                            : Text(isEdit
                                ? 'Update Service Log'
                                : 'Add Service Log'),
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
// Service type chip selector
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceTypeSelector extends StatelessWidget {
  const _ServiceTypeSelector({
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
      children: _kServiceTypes.map((type) {
        final isSelected = selected == type;
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (_) => onChanged(type),
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
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

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
          suffixIcon: (value != null && onClear != null)
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onClear,
                  tooltip: 'Clear date',
                )
              : const Icon(Icons.arrow_drop_down_rounded),
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
