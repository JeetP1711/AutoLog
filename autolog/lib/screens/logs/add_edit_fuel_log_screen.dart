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
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
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
    final vehiclesAsync = ref.watch(vehicleProvider);
    final vehicles = vehiclesAsync.valueOrNull ?? [];
    final selectedVehicle = _selectedVehicleId != null
        ? vehicles.firstWhere((v) => v.id == _selectedVehicleId,
            orElse: () => vehicles.first)
        : null;
    final unit = selectedVehicle != null
        ? MileageCalculator.quantityUnit(selectedVehicle.fuelType,
            customUnit: selectedVehicle.customFuelUnit)
        : 'L';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(widget.logId != null ? 'Edit Fuel Log' : 'Add Fuel Log'),
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
            // Vehicle selector
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

            // Quantity
            TextFormField(
              controller: _quantityCtrl,
              keyboardType: TextInputType.number,
              validator: Validators.quantity,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Quantity ($unit)',
                hintText: 'e.g. 40',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Total price
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              validator: Validators.price,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                labelText: 'Total Price (₹)',
                hintText: 'e.g. 3200',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Odometer
            TextFormField(
              controller: _odometerCtrl,
              keyboardType: TextInputType.number,
              validator: Validators.odometer,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                labelText: 'Odometer (km)',
                hintText: 'e.g. 12500',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Full tank toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Full Tank',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textPrimaryDark)),
              subtitle: Text('Enable for mileage calculation',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondaryDark)),
              value: _isFullTank,
              onChanged: (v) => setState(() => _isFullTank = v),
              activeColor: AppColors.primaryBlue,
            ),
            const SizedBox(height: AppSpacing.md),

            // Station name (optional)
            TextFormField(
              controller: _stationCtrl,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                labelText: 'Fuel Station (optional)',
                hintText: 'e.g. HP Petrol Pump',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Notes (optional)
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
