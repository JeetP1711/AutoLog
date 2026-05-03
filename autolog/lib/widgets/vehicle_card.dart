import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A premium card displaying vehicle summary information.
class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onDelete,
  });

  final Vehicle vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _vehicleIcon(vehicle.vehicleType),
                  size: 30,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.nickname,
                        style: tt.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle.brand} ${vehicle.model} · ${vehicle.year}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(label: vehicle.numberPlate.toUpperCase(), cs: cs),
                        const SizedBox(width: AppSpacing.xs),
                        _Chip(
                          label: _fuelLabel(vehicle.fuelType),
                          cs: cs,
                          color: _fuelColor(vehicle.fuelType),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: cs.error, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete vehicle',
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _vehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.car: return Icons.directions_car_rounded;
      case VehicleType.bike: return Icons.two_wheeler_rounded;
      case VehicleType.scooter: return Icons.electric_scooter_rounded;
      case VehicleType.truck: return Icons.local_shipping_rounded;
      case VehicleType.custom: return Icons.commute_rounded;
    }
  }

  String _fuelLabel(FuelType type) {
    switch (type) {
      case FuelType.petrol: return 'Petrol';
      case FuelType.diesel: return 'Diesel';
      case FuelType.cng: return 'CNG';
      case FuelType.electric: return 'EV';
      case FuelType.hybrid: return 'Hybrid';
      case FuelType.lpg: return 'LPG';
      case FuelType.hydrogen: return 'H₂';
      case FuelType.custom: return 'Custom';
    }
  }

  Color _fuelColor(FuelType type) {
    switch (type) {
      case FuelType.petrol: return AppColors.fuelPetrol;
      case FuelType.diesel: return AppColors.fuelDiesel;
      case FuelType.cng: return AppColors.fuelCng;
      case FuelType.electric: return AppColors.fuelElectric;
      case FuelType.hybrid: return AppColors.fuelHybrid;
      case FuelType.lpg: return AppColors.fuelLpg;
      case FuelType.hydrogen: return AppColors.fuelHydrogen;
      case FuelType.custom: return AppColors.primaryBlue;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.cs, this.color});
  final String label;
  final ColorScheme cs;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color != null ? color!.withAlpha(30) : cs.surfaceContainerHighest;
    final fg = color ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
