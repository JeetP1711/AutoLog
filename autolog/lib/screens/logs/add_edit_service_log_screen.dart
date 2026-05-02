import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/service_log_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

const _serviceTypes = [
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

class AddEditServiceLogScreen extends ConsumerStatefulWidget {
  const AddEditServiceLogScreen({super.key, this.logId, this.vehicleId});
  final String? logId;
  final String? vehicleId;

  @override
  ConsumerState<AddEditServiceLogScreen> createState() =>
      _AddEditServiceLogScreenState();
}

class _AddEditServiceLogScreenState
    extends ConsumerState<AddEditServiceLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _costCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _garageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customTypeCtrl = TextEditingController();
  final _nextDueOdoCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  DateTime? _nextDueDate;
  String _serviceType = 'Oil Change';
  bool _loading = false;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    _odometerCtrl.dispose();
    _garageCtrl.dispose();
    _notesCtrl.dispose();
    _customTypeCtrl.dispose();
    _nextDueOdoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isNextDue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isNextDue
          ? (_nextDueDate ?? DateTime.now().add(const Duration(days: 90)))
          : _date,
      firstDate: isNextDue ? DateTime.now() : DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        if (isNextDue) {
          _nextDueDate = picked;
        } else {
          _date = picked;
        }
      });
    }
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
      final vehicle =
          vehicles.firstWhere((v) => v.id == _selectedVehicleId!);

      final resolvedType =
          _serviceType == 'Custom' ? _customTypeCtrl.text.trim() : _serviceType;

      final log = ServiceLog(
        id: widget.logId ?? newId(),
        vehicleId: _selectedVehicleId!,
        date: _date,
        serviceType: resolvedType,
        cost: double.parse(_costCtrl.text.trim()),
        odometerKm: _odometerCtrl.text.trim().isNotEmpty
            ? double.parse(_odometerCtrl.text.trim())
            : null,
        garageName: _garageCtrl.text.trim().isEmpty
            ? null
            : _garageCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        nextDueDate: _nextDueDate,
        nextDueOdometerKm: _nextDueOdoCtrl.text.trim().isNotEmpty
            ? double.parse(_nextDueOdoCtrl.text.trim())
            : null,
      );

      await ref
          .read(serviceLogProvider(_selectedVehicleId!).notifier)
          .saveServiceLog(log, vehicle.nickname);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service log saved'),
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
        title: Text(widget.logId != null ? 'Edit Service' : 'Add Service'),
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
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: AppSpacing.md),

            // Service type
            DropdownButtonFormField<String>(
              value: _serviceType,
              decoration: const InputDecoration(labelText: 'Service Type'),
              items: _serviceTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _serviceType = v!),
              dropdownColor: AppColors.darkSurface,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
            ),
            if (_serviceType == 'Custom') ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _customTypeCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter service type' : null,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimaryDark),
                decoration: const InputDecoration(
                    labelText: 'Custom Service Type'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Cost
            TextFormField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              validator: Validators.cost,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                labelText: 'Cost (₹)',
                hintText: 'e.g. 2500',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Odometer (optional)
            TextFormField(
              controller: _odometerCtrl,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                labelText: 'Odometer (optional)',
                hintText: 'km at time of service',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Garage name (optional)
            TextFormField(
              controller: _garageCtrl,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                labelText: 'Garage / Workshop (optional)',
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
            const SizedBox(height: AppSpacing.lg),

            // Next due date (optional)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded,
                  color: AppColors.warning),
              title: Text(
                _nextDueDate != null
                    ? 'Next Due: ${_nextDueDate!.day}/${_nextDueDate!.month}/${_nextDueDate!.year}'
                    : 'Set Next Due Date (optional)',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimaryDark),
              ),
              trailing: _nextDueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textSecondaryDark),
                      onPressed: () => setState(() => _nextDueDate = null),
                    )
                  : null,
              onTap: () => _pickDate(true),
            ),

            // Next due odometer (optional)
            TextFormField(
              controller: _nextDueOdoCtrl,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                labelText: 'Next Due Odometer (optional)',
                hintText: 'km for next service',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
