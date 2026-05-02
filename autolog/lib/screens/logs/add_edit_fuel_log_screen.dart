import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/fuel_log.dart';
import '../../models/vehicle.dart';
import '../../providers/fuel_log_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

/// Add or edit a fuel log entry.
///
/// When [logId] is null the screen is in "add" mode; otherwise "edit" mode.
class AddEditFuelLogScreen extends ConsumerStatefulWidget {
  /// The ID of the fuel log to edit, or null when adding a new entry.
  final String? logId;

  const AddEditFuelLogScreen({super.key, this.logId});

  @override
  ConsumerState<AddEditFuelLogScreen> createState() =>
      _AddEditFuelLogScreenState();
}

class _AddEditFuelLogScreenState extends ConsumerState<AddEditFuelLogScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Form state ─────────────────────────────────────────────────────────────
  String? _selectedVehicleId;
  DateTime _date = DateTime.now();
  bool _isFullTank = true;
  bool _isSaving = false;
  bool _isLoading = false;

  final _quantityController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _odometerController = TextEditingController();
  final _stationNameController = TextEditingController();
  final _notesController = TextEditingController();

  // ── Helpers ────────────────────────────────────────────────────────────────

  Vehicle? get _selectedVehicle {
    if (_selectedVehicleId == null) return null;
    final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
    try {
      return vehicles.firstWhere((v) => v.id == _selectedVehicleId);
    } catch (_) {
      return null;
    }
  }

  String get _fuelUnit {
    final vehicle = _selectedVehicle;
    if (vehicle == null) return 'L';
    switch (vehicle.fuelType) {
      case FuelType.electric:
        return 'kWh';
      case FuelType.cng:
      case FuelType.lpg:
        return 'kg';
      case FuelType.hydrogen:
        return 'kg';
      case FuelType.custom:
        return vehicle.customFuelUnit ?? 'L';
      default:
        return 'L';
    }
  }

  String get _distanceUnit {
    final unit = ref.read(distanceUnitProvider);
    return unit == DistanceUnit.km ? 'km' : 'mi';
  }

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
      final repo = ref.read(fuelLogRepositoryProvider);
      final log = await repo.getById(widget.logId!);
      if (log != null && mounted) {
        setState(() {
          _selectedVehicleId = log.vehicleId;
          _date = log.date;
          _isFullTank = log.isFullTank;
          _quantityController.text = log.quantity.toString();
          _totalPriceController.text = log.totalPrice.toString();
          _odometerController.text = log.odometerKm.toString();
          _stationNameController.text = log.stationName ?? '';
          _notesController.text = log.notes ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _totalPriceController.dispose();
    _odometerController.dispose();
    _stationNameController.dispose();
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

    setState(() => _isSaving = true);
    try {
      final vehicle = _selectedVehicle!;
      final isEdit = widget.logId != null;

      final log = FuelLog(
        id: isEdit ? widget.logId! : newId(),
        vehicleId: _selectedVehicleId!,
        date: _date,
        quantity: double.parse(_quantityController.text.trim()),
        totalPrice: double.parse(_totalPriceController.text.trim()),
        odometerKm: double.parse(_odometerController.text.trim()),
        isFullTank: _isFullTank,
        stationName: _stationNameController.text.trim().isEmpty
            ? null
            : _stationNameController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ref
          .read(fuelLogProvider(_selectedVehicleId!).notifier)
          .saveFuelLog(log, vehicle.fuelType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Fuel log updated successfully.'
                  : 'Fuel log added successfully.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _showError('Failed to save fuel log: $e');
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
        title: Text(isEdit ? 'Edit Fuel Log' : 'Add Fuel Log'),
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

                    // ── Quantity ─────────────────────────────────────────
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity *',
                        hintText: 'e.g. 40',
                        prefixIcon: const Icon(Icons.local_gas_station_outlined),
                        suffixText: _fuelUnit,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: Validators.quantity,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Total price ──────────────────────────────────────
                    TextFormField(
                      controller: _totalPriceController,
                      decoration: InputDecoration(
                        labelText: 'Total Price *',
                        hintText: 'e.g. 2500',
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

                    // ── Odometer ─────────────────────────────────────────
                    TextFormField(
                      controller: _odometerController,
                      decoration: InputDecoration(
                        labelText: 'Odometer *',
                        hintText: 'e.g. 15000',
                        prefixIcon: const Icon(Icons.speed_outlined),
                        suffixText: _distanceUnit,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: Validators.odometer,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Station name ─────────────────────────────────────
                    TextFormField(
                      controller: _stationNameController,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Station (optional)',
                        hintText: 'e.g. HP Petrol Pump',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Full tank toggle ─────────────────────────────────
                    _SwitchTile(
                      title: 'Full Tank',
                      subtitle: 'Enable for accurate mileage calculation',
                      value: _isFullTank,
                      onChanged: (v) => setState(() => _isFullTank = v),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Notes ────────────────────────────────────────────
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
                            : Text(isEdit ? 'Update Fuel Log' : 'Add Fuel Log'),
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
// Switch tile
// ─────────────────────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: SwitchListTile(
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}
