import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/fuel_log_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../utils/mileage_calculator.dart';
import '../../utils/validators.dart';

class AddEditFuelLogScreen extends ConsumerStatefulWidget {
  const AddEditFuelLogScreen({super.key, this.logId, this.vehicleId});
  final String? logId;
  final String? vehicleId;

  @override
  ConsumerState<AddEditFuelLogScreen> createState() => _AddEditFuelLogScreenState();
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
  FuelType? _activeFuelType;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
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

  FuelType _resolvedFuelType(Vehicle? vehicle) {
    if (vehicle == null) return FuelType.petrol;
    if (vehicle.fuelType == FuelType.petrolCng) {
      return _activeFuelType ?? FuelType.petrol;
    }
    return vehicle.fuelType;
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
      final fuelType = _resolvedFuelType(vehicle);

      final log = FuelLog(
        id: widget.logId ?? newId(),
        vehicleId: _selectedVehicleId!,
        date: _date,
        quantity: double.parse(_quantityCtrl.text.trim()),
        totalPrice: double.parse(_priceCtrl.text.trim()),
        odometerKm: double.parse(_odometerCtrl.text.trim()),
        isFullTank: _isFullTank,
        stationName: _stationCtrl.text.trim().isEmpty ? null : _stationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await ref.read(fuelLogProvider(_selectedVehicleId!).notifier).saveFuelLog(log, fuelType);

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

    final selectedVehicle = _selectedVehicleId != null ? vehicles.firstWhere((v) => v.id == _selectedVehicleId, orElse: () => vehicles.first) : (vehicles.length == 1 ? vehicles.first : null);

    final isPetrolCng = selectedVehicle?.fuelType == FuelType.petrolCng;
    final resolvedFuelType = _resolvedFuelType(selectedVehicle);
    final unit = MileageCalculator.quantityUnit(resolvedFuelType, customUnit: selectedVehicle?.customFuelUnit);

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
                widget.logId != null ? 'Edit Fuel Entry' : 'Refuel Log',
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
                          onChanged: (v) => setState(() {
                            _selectedVehicleId = v;
                            _activeFuelType = null;
                          }),
                          decoration: _inputDecoration('Select Vehicle'),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (isPetrolCng) ...[
                        _SectionHeader(title: 'Fuel Type', icon: Icons.local_gas_station_rounded),
                        Row(
                          children: [
                            _SelectionChip(
                              label: 'Petrol',
                              selected: (_activeFuelType ?? FuelType.petrol) == FuelType.petrol,
                              onTap: () => setState(() => _activeFuelType = FuelType.petrol),
                            ),
                            const SizedBox(width: 12),
                            _SelectionChip(
                              label: 'CNG',
                              selected: _activeFuelType == FuelType.cng,
                              onTap: () => setState(() => _activeFuelType = FuelType.cng),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      _SectionHeader(title: 'Refill Details', icon: Icons.ev_station_rounded),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _quantityCtrl,
                              label: 'Quantity',
                              hint: '0.00',
                              suffixText: unit,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: Validators.quantity,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _priceCtrl,
                              label: 'Total Cost',
                              hint: '0.00',
                              suffixText: '₹',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: Validators.price,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _odometerCtrl,
                        label: 'Odometer Reading',
                        hint: 'Current km',
                        keyboardType: TextInputType.number,
                        validator: Validators.odometer,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Full Tank refill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Keeps mileage tracking accurate', style: TextStyle(fontSize: 12)),
                        value: _isFullTank,
                        onChanged: (v) => setState(() => _isFullTank = v),
                        activeColor: cs.primary,
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Optional', icon: Icons.more_horiz_rounded),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: cs.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.calendar_today_rounded, color: cs.primary, size: 20),
                        ),
                        title: Text(
                          'Refilled on: ${DateFormatter.format(_date)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _stationCtrl,
                        label: 'Fuel Station',
                        hint: 'e.g. Shell, HP',
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _notesCtrl,
                        label: 'Notes',
                        maxLines: 3,
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
                          child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Fuel Entry', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? cs.primary : cs.outline.withAlpha(30)),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? cs.onPrimary : cs.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}
