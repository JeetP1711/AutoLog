import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../data/vehicle_database.dart';
import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

/// Add or edit a vehicle.
///
/// When [vehicleId] is null the screen is in "add" mode; otherwise "edit" mode.
class AddEditVehicleScreen extends ConsumerStatefulWidget {
  /// The ID of the vehicle to edit, or null when adding a new vehicle.
  final String? vehicleId;

  const AddEditVehicleScreen({super.key, this.vehicleId});

  @override
  ConsumerState<AddEditVehicleScreen> createState() =>
      _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends ConsumerState<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Form state ─────────────────────────────────────────────────────────────
  VehicleType _vehicleType = VehicleType.car;
  FuelType _fuelType = FuelType.petrol;

  final _nicknameController = TextEditingController();
  final _numberPlateController = TextEditingController();
  final _odometerController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedBrand;
  String? _selectedModel;
  int? _selectedYear;

  DateTime? _purchaseDate;
  String? _photoPath;

  // ── Database lists ─────────────────────────────────────────────────────────
  List<String> _brands = [];
  List<String> _models = [];
  List<int> _years = [];

  bool _isSaving = false;
  bool _isLoadingDb = true;

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    final db = VehicleDatabase.instance;
    if (!db.isLoaded) {
      await db.load();
    }
    if (mounted) {
      setState(() {
        _brands = db.getBrands();
        _isLoadingDb = false;
      });
      // If editing, populate fields after DB is loaded
      _populateForEdit();
    }
  }

  void _populateForEdit() {
    if (widget.vehicleId == null) return;
    final vehicle = ref.read(vehicleByIdProvider(widget.vehicleId!));
    if (vehicle == null) return;

    setState(() {
      _vehicleType = vehicle.vehicleType;
      _fuelType = vehicle.fuelType;
      _nicknameController.text = vehicle.nickname;
      _numberPlateController.text = vehicle.numberPlate;
      _odometerController.text = vehicle.odometerKm.toStringAsFixed(0);
      _notesController.text = vehicle.notes ?? '';
      _purchaseDate = vehicle.purchaseDate;
      _photoPath = vehicle.photoPath;

      _selectedBrand = vehicle.brand;
      _models = VehicleDatabase.instance.getModels(vehicle.brand);
      _selectedModel = vehicle.model;
      _years = VehicleDatabase.instance.getYears(vehicle.brand, vehicle.model);
      _selectedYear = vehicle.year;
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _numberPlateController.dispose();
    _odometerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Cascading dropdown handlers ────────────────────────────────────────────

  void _onBrandChanged(String? brand) {
    setState(() {
      _selectedBrand = brand;
      _selectedModel = null;
      _selectedYear = null;
      _models = brand != null
          ? VehicleDatabase.instance.getModels(brand)
          : [];
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

  void _onYearChanged(int? year) {
    setState(() => _selectedYear = year);
  }

  // ── Photo picker ───────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _photoPath = picked.path);
    }
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickPurchaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(1980),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _purchaseDate = picked);
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Extra validation for dropdowns not covered by TextFormField validators
    if (_selectedBrand == null) {
      _showError('Please select a brand.');
      return;
    }
    if (_selectedModel == null) {
      _showError('Please select a model.');
      return;
    }
    if (_selectedYear == null) {
      _showError('Please select a year.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final odometer = double.parse(_odometerController.text.trim());
      final isEdit = widget.vehicleId != null;

      final vehicle = Vehicle(
        id: isEdit ? widget.vehicleId! : newId(),
        nickname: _nicknameController.text.trim(),
        numberPlate: _numberPlateController.text.trim(),
        brand: _selectedBrand!,
        model: _selectedModel!,
        year: _selectedYear!,
        fuelType: _fuelType,
        vehicleType: _vehicleType,
        odometerKm: odometer,
        purchaseDate: _purchaseDate,
        photoPath: _photoPath,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: isEdit
            ? (ref.read(vehicleByIdProvider(widget.vehicleId!))?.createdAt ??
                DateTime.now())
            : DateTime.now(),
      );

      if (isEdit) {
        await ref.read(vehicleProvider.notifier).updateVehicle(vehicle);
      } else {
        await ref.read(vehicleProvider.notifier).addVehicle(vehicle);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? '${vehicle.nickname} updated successfully.'
                  : '${vehicle.nickname} added successfully.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save vehicle: $e');
      }
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
    final isEdit = widget.vehicleId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Vehicle' : 'Add Vehicle'),
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
      body: _isLoadingDb
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // ── Vehicle type ─────────────────────────────────────────
                  _SectionLabel('Vehicle Type'),
                  const SizedBox(height: AppSpacing.sm),
                  _VehicleTypeSelector(
                    selected: _vehicleType,
                    onChanged: (t) => setState(() => _vehicleType = t),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Photo ────────────────────────────────────────────────
                  _PhotoPicker(
                    photoPath: _photoPath,
                    onPick: _pickPhoto,
                    onRemove: () => setState(() => _photoPath = null),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Nickname ─────────────────────────────────────────────
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'Nickname *',
                      hintText: 'e.g. My Swift',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.nickname,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Number plate ─────────────────────────────────────────
                  TextFormField(
                    controller: _numberPlateController,
                    decoration: const InputDecoration(
                      labelText: 'Number Plate *',
                      hintText: 'e.g. MH12AB1234',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\- ]')),
                    ],
                    validator: Validators.numberPlate,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Brand dropdown ───────────────────────────────────────
                  _DropdownField<String>(
                    label: 'Brand *',
                    value: _selectedBrand,
                    items: _brands,
                    itemLabel: (b) => b,
                    onChanged: _onBrandChanged,
                    validator: (v) => Validators.brand(v),
                    hint: 'Select brand',
                    prefixIcon: Icons.business_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Model dropdown ───────────────────────────────────────
                  _DropdownField<String>(
                    label: 'Model *',
                    value: _selectedModel,
                    items: _models,
                    itemLabel: (m) => m,
                    onChanged: _onModelChanged,
                    validator: (v) => Validators.model(v),
                    hint: _selectedBrand == null
                        ? 'Select brand first'
                        : 'Select model',
                    prefixIcon: Icons.directions_car_outlined,
                    enabled: _selectedBrand != null && _models.isNotEmpty,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Year dropdown ────────────────────────────────────────
                  _DropdownField<int>(
                    label: 'Year *',
                    value: _selectedYear,
                    items: _years,
                    itemLabel: (y) => y.toString(),
                    onChanged: _onYearChanged,
                    validator: (v) =>
                        v == null ? 'Year is required' : null,
                    hint: _selectedModel == null
                        ? 'Select model first'
                        : 'Select year',
                    prefixIcon: Icons.calendar_today_outlined,
                    enabled: _selectedModel != null && _years.isNotEmpty,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Fuel type ────────────────────────────────────────────
                  _SectionLabel('Fuel Type'),
                  const SizedBox(height: AppSpacing.sm),
                  _FuelTypeSelector(
                    selected: _fuelType,
                    onChanged: (f) => setState(() => _fuelType = f),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Odometer ─────────────────────────────────────────────
                  TextFormField(
                    controller: _odometerController,
                    decoration: const InputDecoration(
                      labelText: 'Current Odometer (km) *',
                      hintText: 'e.g. 12500',
                      prefixIcon: Icon(Icons.speed_outlined),
                      suffixText: 'km',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]')),
                    ],
                    validator: Validators.odometer,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Purchase date ────────────────────────────────────────
                  _DatePickerField(
                    label: 'Purchase Date (optional)',
                    value: _purchaseDate,
                    onTap: _pickPurchaseDate,
                    onClear: () => setState(() => _purchaseDate = null),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Notes ────────────────────────────────────────────────
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Any additional information…',
                      prefixIcon: Icon(Icons.notes_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Save button ──────────────────────────────────────────
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
                          : Text(isEdit ? 'Update Vehicle' : 'Add Vehicle'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle type chip selector
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleTypeSelector extends StatelessWidget {
  const _VehicleTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final VehicleType selected;
  final ValueChanged<VehicleType> onChanged;

  static const _types = [
    (VehicleType.car, 'Car', Icons.directions_car_rounded),
    (VehicleType.bike, 'Bike', Icons.two_wheeler_rounded),
    (VehicleType.scooter, 'Scooter', Icons.electric_scooter_rounded),
    (VehicleType.truck, 'Truck', Icons.local_shipping_rounded),
    (VehicleType.custom, 'Custom', Icons.commute_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _types.map((entry) {
        final (type, label, icon) = entry;
        final isSelected = selected == type;
        return ChoiceChip(
          avatar: Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
          ),
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(type),
          selectedColor: AppColors.primaryBlue,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimaryDark,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fuel type chip selector
// ─────────────────────────────────────────────────────────────────────────────

class _FuelTypeSelector extends StatelessWidget {
  const _FuelTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final FuelType selected;
  final ValueChanged<FuelType> onChanged;

  static const _types = [
    (FuelType.petrol, 'Petrol'),
    (FuelType.diesel, 'Diesel'),
    (FuelType.cng, 'CNG'),
    (FuelType.electric, 'Electric'),
    (FuelType.hybrid, 'Hybrid'),
    (FuelType.lpg, 'LPG'),
    (FuelType.hydrogen, 'Hydrogen'),
    (FuelType.custom, 'Custom'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _types.map((entry) {
        final (type, label) = entry;
        final isSelected = selected == type;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(type),
          selectedColor: AppColors.primaryBlue,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimaryDark,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic dropdown field
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.validator,
    required this.hint,
    required this.prefixIcon,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? Function(T?) validator;
  final String hint;
  final IconData prefixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
      ),
      hint: Text(hint),
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
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
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final formatted = value != null
        ? DateFormat('dd MMM yyyy').format(value!)
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon: value != null
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
// Photo picker widget
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoPath,
    required this.onPick,
    required this.onRemove,
  });

  final String? photoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Preview / placeholder
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryBlue.withAlpha(60),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoPath != null
                ? Image.file(
                    File(photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.primaryBlue,
                    size: 28,
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle Photo',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Optional — tap to pick from gallery',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
              if (photoPath != null) ...[
                const SizedBox(height: AppSpacing.xs),
                GestureDetector(
                  onTap: onRemove,
                  child: Text(
                    'Remove photo',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
        color: AppColors.textSecondaryDark,
      ),
    );
  }
}
