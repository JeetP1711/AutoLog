import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/vehicle_database.dart';
import '../../models/models.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../utils/validators.dart';
import '../../utils/vehicle_image_helper.dart';

class AddEditVehicleScreen extends ConsumerStatefulWidget {
  const AddEditVehicleScreen({super.key, this.vehicleId});
  final String? vehicleId;

  @override
  ConsumerState<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends ConsumerState<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customFuelTypeCtrl = TextEditingController();
  final _customFuelUnitCtrl = TextEditingController();

  String? _selectedBrand;
  String? _selectedModel;
  int? _selectedYear;
  FuelType _fuelType = FuelType.petrol;
  VehicleType _vehicleType = VehicleType.car;
  DateTime? _purchaseDate;
  String? _photoPath;
  bool _loading = false;

  List<String> _brands = [];
  List<String> _models = [];
  List<int> _years = [];

  Vehicle? _editingVehicle;

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    await VehicleDatabase.instance.load();
    setState(() {
      _brands = VehicleDatabase.instance.getBrands();
    });

    if (widget.vehicleId != null) {
      final vehicles = ref.read(vehicleProvider).valueOrNull ?? [];
      final v = vehicles.firstWhere((v) => v.id == widget.vehicleId, orElse: () => throw StateError('Vehicle not found'));
      _editingVehicle = v;
      _nicknameCtrl.text = v.nickname;
      _plateCtrl.text = v.numberPlate;
      _odometerCtrl.text = v.odometerKm.toString();
      _notesCtrl.text = v.notes ?? '';
      _selectedBrand = v.brand;
      _fuelType = v.fuelType;
      _vehicleType = v.vehicleType;
      _purchaseDate = v.purchaseDate;
      _photoPath = v.photoPath;
      if (v.customFuelType != null) _customFuelTypeCtrl.text = v.customFuelType!;
      if (v.customFuelUnit != null) _customFuelUnitCtrl.text = v.customFuelUnit!;

      _models = VehicleDatabase.instance.getModels(v.brand);
      _selectedModel = v.model;
      _years = VehicleDatabase.instance.getYears(v.brand, v.model);
      _selectedYear = v.year;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _plateCtrl.dispose();
    _odometerCtrl.dispose();
    _notesCtrl.dispose();
    _customFuelTypeCtrl.dispose();
    _customFuelUnitCtrl.dispose();
    super.dispose();
  }

  void _onBrandChanged(String? brand) {
    setState(() {
      _selectedBrand = brand;
      _selectedModel = null;
      _selectedYear = null;
      _models = brand != null ? VehicleDatabase.instance.getModels(brand) : [];
      _years = [];
    });
  }

  void _onModelChanged(String? model) {
    setState(() {
      _selectedModel = model;
      _selectedYear = null;
      _years = (_selectedBrand != null && model != null) ? VehicleDatabase.instance.getYears(_selectedBrand!, model) : [];
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _photoPath = image.path);
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrand == null || _selectedModel == null || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select brand, model, and year')));
      return;
    }

    setState(() => _loading = true);
    try {
      final vehicle = Vehicle(
        id: _editingVehicle?.id ?? newId(),
        nickname: _nicknameCtrl.text.trim(),
        numberPlate: _plateCtrl.text.trim().toUpperCase(),
        brand: _selectedBrand!,
        model: _selectedModel!,
        year: _selectedYear!,
        fuelType: _fuelType,
        vehicleType: _vehicleType,
        odometerKm: double.parse(_odometerCtrl.text.trim()),
        purchaseDate: _purchaseDate,
        photoPath: _photoPath,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: _editingVehicle?.createdAt ?? DateTime.now(),
        customFuelType: _fuelType == FuelType.custom ? _customFuelTypeCtrl.text.trim() : null,
        customFuelUnit: _fuelType == FuelType.custom ? _customFuelUnitCtrl.text.trim() : null,
      );

      if (_editingVehicle != null) {
        await ref.read(vehicleProvider.notifier).updateVehicle(vehicle);
      } else {
        await ref.read(vehicleProvider.notifier).addVehicle(vehicle);
      }

      if (mounted) {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicleId != null;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                isEditing ? 'Edit Vehicle' : 'Add Vehicle',
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
                      _SectionHeader(title: 'What kind of vehicle?', icon: Icons.category_rounded),
                      _VehicleTypeSelector(
                        selected: _vehicleType,
                        onChanged: (t) => setState(() => _vehicleType = t),
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Basic Details', icon: Icons.info_outline_rounded),
                      _buildTextField(
                        controller: _nicknameCtrl,
                        label: 'Nickname',
                        hint: 'e.g. Blue Thunder',
                        validator: Validators.nickname,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _plateCtrl,
                        label: 'Number Plate',
                        hint: 'e.g. MH 12 AB 1234',
                        validator: Validators.numberPlate,
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Brand & Model', icon: Icons.directions_car_rounded),
                      _buildDropdown(
                        label: 'Manufacturer',
                        value: _selectedBrand,
                        items: _brands,
                        onChanged: _onBrandChanged,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDropdown(
                              label: 'Model',
                              value: _selectedModel,
                              items: _models,
                              onChanged: _onModelChanged,
                              enabled: _selectedBrand != null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Year',
                              value: _selectedYear?.toString(),
                              items: _years.map((y) => y.toString()).toList(),
                              onChanged: (v) => setState(() => _selectedYear = v != null ? int.parse(v) : null),
                              enabled: _selectedModel != null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Fuel & Odometer', icon: Icons.speed_rounded),
                      _FuelTypeSelector(
                        selected: _fuelType,
                        onChanged: (t) => setState(() => _fuelType = t),
                      ),
                      if (_fuelType == FuelType.custom) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(controller: _customFuelTypeCtrl, label: 'Fuel Name')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(controller: _customFuelUnitCtrl, label: 'Unit (L, gal)')),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _odometerCtrl,
                        label: 'Current Odometer',
                        hint: 'In kilometers',
                        keyboardType: TextInputType.number,
                        validator: Validators.odometer,
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Optional Info', icon: Icons.more_horiz_rounded),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: cs.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.calendar_month_rounded, color: cs.primary, size: 20),
                        ),
                        title: Text(
                          _purchaseDate != null ? 'Bought on: ${DateFormatter.format(_purchaseDate!)}' : 'Add Purchase Date',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        onTap: _pickPurchaseDate,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _notesCtrl,
                        label: 'Notes',
                        hint: 'Service schedules, insurance details, etc.',
                        maxLines: 4,
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
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isEditing ? 'Update Vehicle' : 'Save Vehicle', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(50))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(50))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha(50))),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
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

class _VehicleTypeSelector extends StatelessWidget {
  const _VehicleTypeSelector({required this.selected, required this.onChanged});
  final VehicleType selected;
  final void Function(VehicleType) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const types = [
      (VehicleType.car, Icons.directions_car_rounded, 'Car'),
      (VehicleType.bike, Icons.two_wheeler_rounded, 'Bike'),
      (VehicleType.scooter, Icons.electric_scooter_rounded, 'Scooter'),
      (VehicleType.truck, Icons.local_shipping_rounded, 'Truck'),
      (VehicleType.custom, Icons.commute_rounded, 'Other'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: types.map((t) {
        final isSelected = selected == t.$1;
        return GestureDetector(
          onTap: () => onChanged(t.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? cs.primary : cs.outline.withAlpha(30)),
              boxShadow: isSelected ? [BoxShadow(color: cs.primary.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.$2, size: 18, color: isSelected ? cs.onPrimary : cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(t.$3, style: TextStyle(color: isSelected ? cs.onPrimary : cs.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FuelTypeSelector extends StatelessWidget {
  const _FuelTypeSelector({required this.selected, required this.onChanged});
  final FuelType selected;
  final void Function(FuelType) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const types = [
      (FuelType.petrol, 'Petrol'),
      (FuelType.diesel, 'Diesel'),
      (FuelType.cng, 'CNG'),
      (FuelType.electric, 'Electric'),
      (FuelType.hybrid, 'Hybrid'),
      (FuelType.custom, 'Other'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final isSelected = selected == t.$1;
        return ChoiceChip(
          label: Text(t.$2),
          selected: isSelected,
          onSelected: (_) => onChanged(t.$1),
          selectedColor: cs.primary,
          labelStyle: TextStyle(color: isSelected ? cs.onPrimary : cs.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12),
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? cs.primary : cs.outline.withAlpha(30))),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
