import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/fuel_log_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/mileage_calculator.dart';
import '../../utils/validators.dart';

class AddEditFuelLogScreen extends ConsumerStatefulWidget {
  const AddEditFuelLogScreen({super.key, this.logId, this.vehicleId});
  final String? logId;
  final String? vehicleId;

  @override
  ConsumerState<AddEditFuelLogScreen> createState() =>
      _AddEditFuelLogScreenState();
}

class _AddEditFuelLogScreenState extends ConsumerState<AddEditFuelLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  bool _isFullTank = true;
  bool _loading = false;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
    // Auto-select first vehicle if only one exists and none passed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedVehicleId == null) {
        final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
        if (vehicles.length == 1) {
          setState(() => _selectedVehicleId = vehicles.first.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _odometerCtrl.dispose();
    _stationCtrl.dispose();
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

    // Auto-select if only one vehicle
    if (_selectedVehicleId == null) {
      final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
      if (vehicles.length == 1) {
        _selectedVehicleId = vehicles.first.id;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a vehicle')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
      final vehicle = vehicles.firstWhere((v) => v.id == _selectedVehicleId!);

      final log = FuelLog(
        id: widget.logId ?? newId(),
        vehicleId: _selectedVehicleId!,
        date: _date,
        quantity: double.parse(_quantityCtrl.text.trim()),
        totalPrice: double.parse(_priceCtrl.text.trim()),
        odometerKm: double.parse(_odometerCtrl.text.trim()),
        isFullTank: _isFullTank,
        stationName: _stationCtrl.text.trim().isEmpty
            ? null
            : _stationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await ref
          .read(fuelLogProvider(_selectedVehicleId!).notifier)
          .saveFuelLog(log, vehicle.fuelType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fuel log saved'),
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
    final cs = Theme.of(context).colorScheme;
    final vehiclesAsync = ref.watch(vehicleProvider);
    final vehicles = vehiclesAsync.valueOrNull ?? [];

    // Auto-select single vehicle
    if (_selectedVehicleId == null && vehicles.length == 1) {
      _selectedVehicleId = vehicles.first.id;
    }

    final selectedVehicle = _selectedVehicleId != null
        ? vehicles.firstWhere((v) => v.id == _selectedVehicleId,
            orElse: () => vehicles.isNotEmpty ? vehicles.first : throw StateError('no vehicles'))
        : null;
    final unit = selectedVehicle != null
        ? MileageCalculator.quantityUnit(selectedVehicle.fuelType,
            customUnit: selectedVehicle.customFuelUnit)
        : 'L';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.logId != null ? 'Edit Fuel Log' : 'Add Fuel Log'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Save',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          children: [
            // Vehicle selector — only show when multiple vehicles
            if (vehicles.length > 1) ...[
              DropdownButtonFormField<String>(
                value: _selectedVehicleId,
                decoration: const InputDecoration(labelText: 'Vehicle'),
                items: vehicles
                    .map((v) => DropdownMenuItem(value: v.id, child: Text(v.nickname)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedVehicleId = v),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Date picker row
            _DateRow(date: _date, onTap: _pickDate),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _quantityCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.quantity,
              decoration: InputDecoration(labelText: 'Quantity ($unit)', hintText: 'e.g. 40'),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.price,
              decoration: const InputDecoration(labelText: 'Total Price (₹)', hintText: 'e.g. 3200'),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _odometerCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.odometer,
              decoration: const InputDecoration(labelText: 'Odometer (km)', hintText: 'e.g. 12500'),
            ),
            const SizedBox(height: AppSpacing.sm),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Full Tank'),
              subtitle: const Text('Required for mileage calculation'),
              value: _isFullTank,
              onChanged: (v) => setState(() => _isFullTank = v),
            ),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _stationCtrl,
              decoration: const InputDecoration(labelText: 'Fuel Station (optional)'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared date row widget
// ─────────────────────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Icon(Icons.edit_calendar_rounded, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
