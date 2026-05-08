import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/service_log_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
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
  ConsumerState<AddEditServiceLogScreen> createState() => _AddEditServiceLogScreenState();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a vehicle')));
      return;
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
        odometerKm: _odometerCtrl.text.trim().isNotEmpty ? double.parse(_odometerCtrl.text.trim()) : null,
        garageName: _garageCtrl.text.trim().isEmpty ? null : _garageCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        nextDueDate: _nextDueDate,
        nextDueOdometerKm: _nextDueOdoCtrl.text.trim().isNotEmpty ? double.parse(_nextDueOdoCtrl.text.trim()) : null,
      );

      await ref.read(serviceLogProvider(_selectedVehicleId!).notifier).saveServiceLog(log, vehicle.nickname);

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
                widget.logId != null ? 'Edit Service' : 'Service Log',
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
                      _SectionHeader(title: 'Service Type', icon: Icons.build_circle_rounded),
                      DropdownButtonFormField<String>(
                        value: _serviceType,
                        items: _serviceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _serviceType = v!),
                        decoration: _inputDecoration('Type of Maintenance'),
                      ),
                      if (_serviceType == 'Custom') ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _customTypeCtrl,
                          label: 'Service Name',
                          hint: 'Describe the maintenance',
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter service type' : null,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Maintenance Details', icon: Icons.receipt_rounded),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _costCtrl,
                              label: 'Service Cost',
                              hint: '0.00',
                              suffixText: '₹',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: Validators.cost,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _odometerCtrl,
                              label: 'Current Odo',
                              hint: 'optional',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _garageCtrl,
                        label: 'Service Center / Garage',
                        hint: 'e.g. Authorized Service Center',
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Next Service Reminder', icon: Icons.notification_important_rounded),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: cs.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.calendar_today_rounded, color: cs.primary, size: 20),
                        ),
                        title: Text(
                          _nextDueDate != null ? 'Due on: ${DateFormatter.format(_nextDueDate!)}' : 'Set Next Due Date',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        trailing: _nextDueDate != null ? IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => setState(() => _nextDueDate = null)) : null,
                        onTap: () => _pickDate(true),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _nextDueOdoCtrl,
                        label: 'Next Due Odometer',
                        hint: 'optional km',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Notes', icon: Icons.notes_rounded),
                      _buildTextField(
                        controller: _notesCtrl,
                        label: 'Additional Info',
                        maxLines: 4,
                        hint: 'Work performed, parts replaced, etc.',
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
                          child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Service Log', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
