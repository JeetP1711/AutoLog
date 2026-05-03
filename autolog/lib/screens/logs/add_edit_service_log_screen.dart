import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/service_log_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

const _serviceTypes = [
  'Oil Change', 'Brake Service', 'General Service', 'Washing',
  'Detailing', 'Tyre Rotation', 'Battery Replacement',
  'Engine Repair', 'AC Repair', 'Custom',
];

class AddEditServiceLogScreen extends ConsumerStatefulWidget {
  const AddEditServiceLogScreen({super.key, this.logId, this.vehicleId});
  final String? logId;
  final String? vehicleId;

  @override
  ConsumerState<AddEditServiceLogScreen> createState() =>
      _AddEditServiceLogScreenState();
}

class _AddEditServiceLogScreenState extends ConsumerState<AddEditServiceLogScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedVehicleId == null) {
        final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
        if (vehicles.length == 1) setState(() => _selectedVehicleId = vehicles.first.id);
      }
    });
  }

  @override
  void dispose() {
    _costCtrl.dispose(); _odometerCtrl.dispose(); _garageCtrl.dispose();
    _notesCtrl.dispose(); _customTypeCtrl.dispose(); _nextDueOdoCtrl.dispose();
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
    if (picked != null) setState(() => isNextDue ? _nextDueDate = picked : _date = picked);
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
      final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
      final vehicle = vehicles.firstWhere((v) => v.id == _selectedVehicleId!);
      final resolvedType = _serviceType == 'Custom' ? _customTypeCtrl.text.trim() : _serviceType;

      final log = ServiceLog(
        id: widget.logId ?? newId(),
        vehicleId: _selectedVehicleId!,
        date: _date,
        serviceType: resolvedType,
        cost: double.parse(_costCtrl.text.trim()),
        odometerKm: _odometerCtrl.text.trim().isNotEmpty
            ? double.parse(_odometerCtrl.text.trim()) : null,
        garageName: _garageCtrl.text.trim().isEmpty ? null : _garageCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        nextDueDate: _nextDueDate,
        nextDueOdometerKm: _nextDueOdoCtrl.text.trim().isNotEmpty
            ? double.parse(_nextDueOdoCtrl.text.trim()) : null,
      );

      await ref.read(serviceLogProvider(_selectedVehicleId!).notifier)
          .saveServiceLog(log, vehicle.nickname);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service log saved'), behavior: SnackBarBehavior.floating));
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
        title: Text(widget.logId != null ? 'Edit Service' : 'Add Service'),
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

            _DatePickerRow(label: 'Date', date: _date, onTap: () => _pickDate(false)),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<String>(
              value: _serviceType,
              decoration: const InputDecoration(labelText: 'Service Type'),
              items: _serviceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _serviceType = v!),
            ),
            if (_serviceType == 'Custom') ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _customTypeCtrl,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter service type' : null,
                decoration: const InputDecoration(labelText: 'Custom Service Type'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _costCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.cost,
              decoration: const InputDecoration(labelText: 'Cost (₹)', hintText: 'e.g. 2500'),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _odometerCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Odometer (optional)', hintText: 'km at service'),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _garageCtrl,
              decoration: const InputDecoration(labelText: 'Garage / Workshop (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: AppSpacing.lg),

            _DatePickerRow(
              label: _nextDueDate != null
                  ? 'Next Due: ${_nextDueDate!.day}/${_nextDueDate!.month}/${_nextDueDate!.year}'
                  : 'Set Next Due Date (optional)',
              date: _nextDueDate,
              onTap: () => _pickDate(true),
              trailing: _nextDueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _nextDueDate = null))
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _nextDueOdoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Next Due Odometer (optional)', hintText: 'km'),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({required this.label, required this.onTap, this.date, this.trailing});
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
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
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            if (trailing != null) trailing!
            else Icon(Icons.edit_calendar_rounded, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
