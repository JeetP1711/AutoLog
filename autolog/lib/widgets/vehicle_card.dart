import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/vehicle_image_helper.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(cs.brightness == Brightness.light ? 10 : 30),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Vehicle Illustration
                VehicleImageHelper.getVehicleImage(
                  vehicle,
                  width: 80,
                  height: 60,
                ),
                const SizedBox(width: AppSpacing.md),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.nickname,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.brand} ${vehicle.model}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Tag(
                            label: vehicle.numberPlate.toUpperCase(),
                            icon: Icons.tag_rounded,
                            color: cs.onSurfaceVariant.withAlpha(150),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _Tag(
                            label: _fuelLabel(vehicle.fuelType),
                            icon: Icons.local_gas_station_rounded,
                            color: _fuelColor(vehicle.fuelType),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Trailing
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withAlpha(100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      case FuelType.petrolCng: return 'Petrol+CNG';
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
      case FuelType.petrolCng: return AppColors.fuelCng;
      case FuelType.custom: return AppColors.primaryBlue;
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
