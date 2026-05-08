import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

/// Helper to resolve vehicle illustrations/images based on vehicle data.
class VehicleImageHelper {
  /// Returns a widget representing the vehicle.
  /// 
  /// Priority:
  /// 1. User uploaded photo ([photoPath])
  /// 2. Brand-specific illustration (matching [brand])
  /// 3. Vehicle type icon fallback
  static Widget getVehicleImage(Vehicle vehicle, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
    // 1. User photo
    if (vehicle.photoPath != null && vehicle.photoPath!.isNotEmpty) {
      // Note: In a real app we'd use Image.file or similar.
      // For now we'll show a placeholder if the path looks like a local file.
      return Image.asset(
        'assets/images/app_icon.png', // Fallback for demonstration
        width: width,
        height: height,
        fit: fit,
      );
    }

    // 2. Brand specific illustration (Future expansion)
    // We can add logic here to check assets/images/vehicles/[brand].png
    
    // 3. Fallback to Type Icon
    return _getTypeIcon(vehicle.vehicleType, width: width, height: height);
  }

  static Widget _getTypeIcon(VehicleType type, {double? width, double? height}) {
    IconData icon;
    switch (type) {
      case VehicleType.car:
        icon = Icons.directions_car_rounded;
        break;
      case VehicleType.bike:
        icon = Icons.two_wheeler_rounded;
        break;
      case VehicleType.scooter:
        icon = Icons.electric_scooter_rounded;
        break;
      case VehicleType.truck:
        icon = Icons.local_shipping_rounded;
        break;
      case VehicleType.custom:
      default:
        icon = Icons.commute_rounded;
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          icon,
          size: (width ?? 40) * 0.6,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
