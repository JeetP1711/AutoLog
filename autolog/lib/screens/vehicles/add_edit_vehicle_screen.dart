import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/vehicle_database.dart';
import '../../models/models.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

class AddEditVehicleScreen extends ConsumerStatefulWidget {
  const AddEditVehicleScreen({super.key, this.vehicleId});
  final String? vehicleId;

  @override
  ConsumerState<AddEditVehicleScreen> createState() =>
      _AddEditVehicleScreenState();
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
      final v = vehicles.firstWhere((v) => v.id == widget.vehicleId,
          orElse: () => throw StateError('Vehicle not found'));
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
      _years = (_selectedBrand != null && model != null)
          ? VehicleDatabase.instance.getYears(_selectedBrand!, model)
          : [];
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select brand, model, and year')),
      );
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
        customFuelType: _fuelType == FuelType.custom
            ? _customFuelTypeCtrl.text.trim()
            : null,
        customFuelUnit: _fuelType == FuelType.custom
            ? _customFuelUnitCtrl.text.trim()
            : null,
      );

      if (_editingVehicle != null) {
        await ref.read(vehicleProvider.notifier).updateVehicle(vehicle);
      } else {
        await ref.read(vehicleProvider.notifier).addVehicle(vehicle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingVehicle != null
                ? 'Vehicle updated'
                : 'Vehicle added'),
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
    final isEditing = widget.vehicleId != null;

    return Scaffold(
            appBar: AppBar(
        title: Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Vehicle type ─────────────────────────────────────────────────
            _SectionHeader(title: 'Vehicle Type'),
            _VehicleTypeSelector(
              selected: _vehicleType,
              onChanged: (t) => setState(() => _vehicleType = t),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Basic info ───────────────────────────────────────────────────
            _SectionHeader(title: 'Basic Info'),
            _buildTextField(
              controller: _nicknameCtrl,
              label: 'Nickname',
              hint: 'e.g. My Swift',
              validator: Validators.nickname,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _plateCtrl,
              label: 'Number Plate',
              hint: 'e.g. MH12AB1234',
              validator: Validators.numberPlate,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Brand / Model / Year ─────────────────────────────────────────
            _SectionHeader(title: 'Brand & Model'),
            _buildDropdown(
              label: 'Brand',
              value: _selectedBrand,
              items: _brands,
              onChanged: _onBrandChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDropdown(
              label: 'Model',
              value: _selectedModel,
              items: _models,
              onChanged: _onModelChanged,
              enabled: _selectedBrand != null,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDropdown(
              label: 'Year',
              value: _selectedYear?.toString(),
              items: _years.map((y) => y.toString()).toList(),
              onChanged: (v) =>
                  setState(() => _selectedYear = v != null ? int.parse(v) : null),
              enabled: _selectedModel != null,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Fuel type ────────────────────────────────────────────────────
            _SectionHeader(title: 'Fuel Type'),
            _FuelTypeSelector(
              selected: _fuelType,
              onChanged: (t) => setState(() => _fuelType = t),
            ),
            if (_fuelType == FuelType.custom) ...[
              const SizedBox(height: AppSpacing.md),
              _buildTextField(
                controller: _customFuelTypeCtrl,
                label: 'Custom Fuel Name',
                hint: 'e.g. Biodiesel',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(
                controller: _customFuelUnitCtrl,
                label: 'Custom Unit',
                hint: 'e.g. gal',
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // ── Odometer ─────────────────────────────────────────────────────
            _SectionHeader(title: 'Odometer'),
            _buildTextField(
              controller: _odometerCtrl,
              label: 'Current Odometer (km)',
              hint: 'e.g. 12500',
              keyboardType: TextInputType.number,
              validator: Validators.odometer,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Optional fields ──────────────────────────────────────────────
            _SectionHeader(title: 'Optional'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded,
                  color: AppColors.primaryBlue),
              title: Text(
                _purchaseDate != null
                    ? 'Purchase Date: ${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                    : 'Purchase Date',
                ),
              onTap: _pickPurchaseDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_camera_rounded,
                  color: AppColors.primaryBlue),
              title: Text(
                _photoPath != null ? 'Photo selected' : 'Add Photo',
                ),
              onTap: _pickPhoto,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _notesCtrl,
              label: 'Notes',
              hint: 'Any additional notes...',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
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
      style: AppTextStyles.bodyMedium
          .copyWith(color: AppColors.textPrimaryDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: enabled ? onChanged : null,
      style: AppTextStyles.bodyMedium
          .copyWith(color: AppColors.textPrimaryDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.labelMedium
            .copyWith(color: AppColors.textSecondaryDark),
      ),
    );
  }
}

class _VehicleTypeSelector extends StatelessWidget {
  const _VehicleTypeSelector(
      {required this.selected, required this.onChanged});
  final VehicleType selected;
  final void Function(VehicleType) onChanged;

  @override
  Widget build(BuildContext context) {
    const types = [
      (VehicleType.car, Icons.directions_car_rounded, 'Car'),
      (VehicleType.bike, Icons.two_wheeler_rounded, 'Bike'),
      (VehicleType.scooter, Icons.electric_scooter_rounded, 'Scooter'),
      (VehicleType.truck, Icons.local_shipping_rounded, 'Truck'),
      (VehicleType.custom, Icons.commute_rounded, 'Other'),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      children: types.map((t) {
        final isSelected = selected == t.$1;
        return ChoiceChip(
          avatar: Icon(t.$2,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondaryDark),
          label: Text(t.$3),
          selected: isSelected,
          onSelected: (_) => onChanged(t.$1),
          selectedColor: AppColors.primaryBlue,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimaryDark,
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
    const types = [
      (FuelType.petrol, 'Petrol'),
      (FuelType.diesel, 'Diesel'),
      (FuelType.cng, 'CNG'),
      (FuelType.electric, 'Electric'),
      (FuelType.hybrid, 'Hybrid'),
      (FuelType.lpg, 'LPG'),
      (FuelType.hydrogen, 'Hydrogen'),
      (FuelType.custom, 'Custom'),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: types.map((t) {
        final isSelected = selected == t.$1;
        return ChoiceChip(
          label: Text(t.$2),
          selected: isSelected,
          onSelected: (_) => onChanged(t.$1),
          selectedColor: AppColors.primaryBlue,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimaryDark,
          ),
        );
      }).toList(),
    );
  }
}
