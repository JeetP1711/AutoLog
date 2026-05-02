import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha(26),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primaryBlue.withAlpha(77),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  size: 52,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'AutoLog',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Track Every Mile',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Version 1.0.0',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textDisabledDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'A premium personal offline vehicle management app.\nTrack fuel, service, expenses, and documents for all your vehicles — 100% offline.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
