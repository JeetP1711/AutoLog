import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

/// Helper to resolve vehicle illustrations/images based on vehicle data.
class VehicleImageHelper {
  /// Returns a widget representing the vehicle based on the full object.
  static Widget getVehicleImage(Vehicle vehicle, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
    if (vehicle.photoPath != null && vehicle.photoPath!.isNotEmpty) {
      return Image.asset(
        'assets/images/app_icon.png', // Fallback for demonstration
        width: width,
        height: height,
        fit: fit,
      );
    }
    return getIllustration(vehicle.vehicleType, brand: vehicle.brand, width: width, height: height);
  }

  /// Returns a themed illustration based on vehicle type and brand.
  static Widget getIllustration(VehicleType type, {String? brand, double? width, double? height}) {
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
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Icon(
          icon,
          size: (width ?? 80) * 0.5,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
